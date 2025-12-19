import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'booking_model.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(Supabase.instance.client);
});

final myBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  return ref.watch(bookingRepositoryProvider).getMyBookings();
});

final dashboardBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final role =
      Supabase.instance.client.auth.currentUser?.userMetadata?['role'] ??
      'user';
  if (role == 'admin') {
    return ref.watch(bookingRepositoryProvider).getAdminBookings();
  }
  return ref.watch(bookingRepositoryProvider).getOwnerBookings();
});

class BookingRepository {
  final SupabaseClient _client;

  BookingRepository(this._client);

  Future<List<BookingModel>> getMyBookings() async {
    final response = await _client
        .from('bookings')
        .select('*, field:fields(*)') // Join with fields
        .eq('user_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false);
    return (response as List).map((e) => BookingModel.fromJson(e)).toList();
  }

  // New method for Owners
  Future<List<Map<String, dynamic>>> getOwnerBookings() async {
    // 1. Get my field IDs
    final myFields = await _client
        .from('fields')
        .select('id')
        .eq('owner_id', _client.auth.currentUser!.id);

    final fieldIds = (myFields as List).map((e) => e['id'] as String).toList();

    if (fieldIds.isEmpty) return [];

    // 2. Get bookings for these fields
    final response = await _client
        .from('bookings')
        // We need user info too.
        .select('*, field:fields(name), user:users(email, id)')
        .filter(
          'field_id',
          'in',
          fieldIds,
        ) // Fixed: usage of filter instead of in_
        .order('created_at', ascending: false);

    // Return raw maps since BookingModel might not strictly hold the joined 'user'/'field' data deeply
    // or we can adjust logic to map it manually.
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> getAdminBookings() async {
    final response = await _client
        .from('bookings')
        .select('*, field:fields(name), user:users(email, id)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _client
        .from('bookings')
        .update({'status': status})
        .eq('id', bookingId);
  }

  Future<void> createBooking(BookingModel booking) async {
    // Note: We omit ID and let DB generate it, or handle it same as FieldModel
    await _client.from('bookings').insert({
      'field_id': booking.fieldId,
      'user_id': _client.auth.currentUser!.id,
      'start_time': booking.startTime.toIso8601String(),
      'end_time': booking.endTime.toIso8601String(),
      'status': booking.status,
      'total_price': booking.totalPrice,
      // proof_of_payment_url is usually added later or during creation if available
    });
  }

  Future<void> cancelBooking(String bookingId) async {
    await _client
        .from('bookings')
        .update({'status': 'cancelled'}) // Set status ke cancelled
        .eq('id', bookingId)
        .eq('user_id', _client.auth.currentUser!.id); // Pastikan update punya user sendiri
  }

  Future<void> uploadPaymentProof(
    String bookingId,
    List<int> bytes,
    String fileExt,
  ) async {
    final fileName =
        '${bookingId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final path = fileName; // Relative path stored in DB

    // 1. Upload
    await _client.storage
        .from('payment-proofs')
        .uploadBinary(
          path,
          (bytes is Uint8List) ? bytes : Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: 'image/$fileExt'),
        );

    // 2. Update Booking
    await _client
        .from('bookings')
        .update({'proof_of_payment_url': path})
        .eq('id', bookingId);
  }
}
