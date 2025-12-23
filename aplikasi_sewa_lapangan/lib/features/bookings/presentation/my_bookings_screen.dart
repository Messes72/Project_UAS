import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aplikasi_sewa_lapangan/features/bookings/data/booking_repository.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  bool _isUploading = false;
  bool _isCancelling = false;

  Future<void> _pickAndUpload(String bookingId) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await image.readAsBytes();
      final extension = image.name.split('.').last;

      await ref
          .read(bookingRepositoryProvider)
          .uploadPaymentProof(bookingId, bytes, extension);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proof uploaded successfully!')),
        );
        ref.invalidate(myBookingsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(bookingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
        ref.invalidate(myBookingsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }
          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), 
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  final startFmt = DateFormat('dd MMM yyyy, HH:mm').format(booking.startTime);
                  final endFmt = DateFormat('HH:mm').format(booking.endTime);
                  final hasProof = booking.proofOfPaymentUrl != null;
                  
                  final isCancelled = booking.status == 'cancelled';
                  final isCompleted = booking.status == 'completed';

                  Color statusColor = Colors.grey;
                  if (booking.status == 'confirmed') statusColor = Colors.green;
                  else if (booking.status == 'pending') statusColor = Colors.orange;
                  else if (booking.status == 'cancelled') statusColor = Colors.red;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  booking.fieldName ?? 'Booking #${booking.id.substring(0, 8)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  booking.status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Text('$startFmt - $endFmt'),
                          const SizedBox(height: 8),

                          Text(
                            'Rp ${booking.totalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (hasProof)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Payment Proof:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                  },
                                  child: FutureBuilder<String>(
                                    future: Supabase.instance.client.storage
                                        .from('payment-proofs')
                                        .createSignedUrl(
                                          booking.proofOfPaymentUrl!,
                                          3600,
                                        ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const SizedBox(
                                          height: 150,
                                          child: Center(child: CircularProgressIndicator()),
                                        );
                                      }
                                      if (snapshot.hasError || !snapshot.hasData) {
                                        return Container(
                                          height: 150,
                                          width: double.infinity,
                                          color: Colors.grey[200],
                                          child: const Center(child: Text('Error loading image')),
                                        );
                                      }
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          snapshot.data!,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Text('Error loading image'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!isCancelled && !isCompleted)
                                TextButton(
                                  onPressed: (_isCancelling || _isUploading)
                                      ? null
                                      : () => _cancelBooking(booking.id),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Cancel Booking'),
                                ),
                              
                              const SizedBox(width: 8),

                              if (!hasProof && !isCancelled)
                                ElevatedButton.icon(
                                  onPressed: (_isCancelling || _isUploading)
                                      ? null
                                      : () => _pickAndUpload(booking.id),
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Upload Proof'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              if (_isUploading || _isCancelling)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}