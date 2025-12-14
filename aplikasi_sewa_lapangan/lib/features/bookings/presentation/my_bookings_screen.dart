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

  Future<void> _pickAndUpload(String bookingId) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await image.readAsBytes();
      final extension = image.name
          .split('.')
          .last; // Simple extension extraction

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  final startFmt = DateFormat(
                    'dd MMM yyyy, HH:mm',
                  ).format(booking.startTime);
                  final endFmt = DateFormat('HH:mm').format(booking.endTime);
                  final hasProof = booking.proofOfPaymentUrl != null;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.fieldName ??
                                'Booking #${booking.id.substring(0, 8)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Status: ${booking.status.toUpperCase()}'),
                          Text('$startFmt - $endFmt'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Rp ${booking.totalPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Payment Proof Section
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
                                    // Could open full screen view
                                  },
                                  child: FutureBuilder<String>(
                                    future: Supabase.instance.client.storage
                                        .from('payment-proofs')
                                        .createSignedUrl(
                                          booking.proofOfPaymentUrl!,
                                          3600,
                                        ), // 1 hour expiry
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (snapshot.hasError ||
                                          !snapshot.hasData) {
                                        return const Text(
                                          'Error loading image',
                                          style: TextStyle(color: Colors.red),
                                        );
                                      }
                                      return Image.network(
                                        snapshot.data!,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Text('Error loading image'),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isUploading
                                    ? null
                                    : () => _pickAndUpload(booking.id),
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Upload Payment Proof'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_isUploading)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator()),
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
