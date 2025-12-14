import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'booking_model.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(Supabase.instance.client);
});

final myBookingsProvider = FutureProvider<List<BookingModel>>((ref) async {
  return ref.watch(bookingRepositoryProvider).getMyBookings();
});

class BookingRepository {
  final SupabaseClient _client;

  BookingRepository(this._client);

  Future<List<BookingModel>> getMyBookings() async {
    final response = await _client
        .from('bookings')
        .select()
        .eq('user_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return (response as List).map((e) => BookingModel.fromJson(e)).toList();
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
}
