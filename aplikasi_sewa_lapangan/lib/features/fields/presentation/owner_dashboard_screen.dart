import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_repository.dart';
import 'package:aplikasi_sewa_lapangan/features/bookings/data/booking_repository.dart';
import 'package:aplikasi_sewa_lapangan/features/auth/data/auth_repository.dart';

// Providers
final dashboardFieldsProvider = FutureProvider((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  String role = user?.userMetadata?['role'] ?? 'user';
  if (user?.email == 'admin@gmail.com') role = 'admin';
  if (user?.email == 'owner@gmail.com') role = 'owner';

  if (role == 'admin') {
    return ref.watch(fieldRepositoryProvider).getAdminFields();
  } else {
    return ref.watch(fieldRepositoryProvider).getMyFields();
  }
});

final dashboardBookingsProvider = FutureProvider((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  String role = user?.userMetadata?['role'] ?? 'user';
  if (user?.email == 'admin@gmail.com') role = 'admin';
  if (user?.email == 'owner@gmail.com') role = 'owner';

  if (role == 'admin') {
    return ref.watch(bookingRepositoryProvider).getAdminBookings();
  } else {
    return ref.watch(bookingRepositoryProvider).getOwnerBookings();
  }
});

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    String role = user?.userMetadata?['role'] ?? 'user';
    if (user?.email == 'admin@gmail.com') role = 'admin';
    if (user?.email == 'owner@gmail.com') role = 'owner';

    final isAdmin = role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Dashboard' : 'Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(dashboardFieldsProvider);
              ref.invalidate(dashboardBookingsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Fields Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAdmin ? 'All Fields' : 'My Fields',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isAdmin)
                  ElevatedButton.icon(
                    onPressed: () => context.push('/owner/add-field'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFieldsList(ref, isAdmin),

            const Divider(height: 48, thickness: 2),

            // --- Bookings Section ---
            const Text(
              'Incoming Bookings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBookingsList(ref, context),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsList(WidgetRef ref, bool isAdmin) {
    final fieldsAsync = ref.watch(dashboardFieldsProvider);
    return fieldsAsync.when(
      data: (allFields) {
        
        final fields = allFields.where((field) => field.isActive).toList();

        if (fields.isEmpty) {
          return const Text('No active fields found.');
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: fields.length,
          itemBuilder: (context, index) {
            final field = fields[index];
            return Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: field.images.isNotEmpty
                          ? Builder(builder: (context) {
                              final rawImage = field.images.first;
                              final imageUrl = rawImage.contains('http')
                                  ? rawImage
                                  : Supabase.instance.client.storage
                                      .from('field-images')
                                      .getPublicUrl(rawImage);

                              return Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                ),
                              );
                            })
                          : Container(
                              color: Colors.grey.shade200,
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.sports_soccer,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            field.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Rp ${field.pricePerHour}',
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                          const SizedBox(height: 4),
                          // Actions
                          if (!isAdmin)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                  onPressed: () {
                                    context.push('/owner/add-field', extra: field);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Field?'),
                                        content: const Text('Are you sure you want to delete this field?'),
                                        actions: [
                                          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () => context.pop(true),
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await ref.read(fieldRepositoryProvider).deleteField(field.id);
                                      ref.invalidate(dashboardFieldsProvider);
                                    }
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, trace) => Text('Error: $e'),
    );
  }
  Widget _buildBookingsList(WidgetRef ref, BuildContext context) {
    final bookingsAsync = ref.watch(dashboardBookingsProvider);
    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) return const Text('No bookings yet.');
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final fieldName = booking['field']['name'] ?? 'Unknown Field';
            final userEmail = booking['user']?['email'] ?? 'Unknown User';
            final status = booking['status'];
            final id = booking['id'];
            final proofUrl = booking['proof_of_payment_url'];

            Color statusColor = Colors.grey;
            if (status == 'confirmed') statusColor = Colors.green;
            if (status == 'pending') statusColor = Colors.orange;
            if (status == 'cancelled') statusColor = Colors.red;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(fieldName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('By: $userEmail'),
                      Text('Total: Rp ${booking["total_price"]}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          if (proofUrl != null)
                            InkWell(
                              onTap: () => _showPaymentProof(context, proofUrl),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.image, size: 12, color: Colors.blue),
                                    SizedBox(width: 4),
                                    Text(
                                      'View Proof',
                                      style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Text(
                              '(No Proof)',
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(bookingRepositoryProvider)
                                    .updateBookingStatus(id, 'confirmed');
                                ref.invalidate(dashboardBookingsProvider);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () async {
                                await ref
                                    .read(bookingRepositoryProvider)
                                    .updateBookingStatus(id, 'cancelled');
                                ref.invalidate(dashboardBookingsProvider);
                              },
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, trace) => Text('Error: $e'),
    );
  }

  void _showPaymentProof(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        "Payment Proof",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    FutureBuilder<String>(
                      future: Supabase.instance.client.storage
                          .from('payment-proofs')
                          .createSignedUrl(path, 60),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const SizedBox(
                            height: 200,
                            child: Center(child: Text("Error loading image")),
                          );
                        }
                        return InteractiveViewer(
                          child: Image.network(
                            snapshot.data!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                height: 200,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}