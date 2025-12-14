import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasi_sewa_lapangan/features/auth/data/auth_repository.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_model.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final allFieldsProvider = FutureProvider<List<FieldModel>>((ref) async {
  return ref.watch(fieldRepositoryProvider).getAllActiveFields();
});

class FieldSearchScreen extends ConsumerWidget {
  const FieldSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(allFieldsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Fields'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => context.push('/map'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/my-bookings'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: fieldsAsync.when(
        data: (fields) {
          if (fields.isEmpty) {
            return const Center(child: Text('No active fields found.'));
          }
          return ListView.builder(
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () => context.push('/field-detail', extra: field),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (field.images.isNotEmpty)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            field.images.first.startsWith('http')
                                ? field.images.first
                                : Supabase.instance.client.storage
                                      .from('field-images')
                                      .getPublicUrl(field.images.first),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          height: 150,
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.sports_soccer,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              field.name,
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              field.address,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Rp ${field.pricePerHour}/hour',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                TextButton(
                                  onPressed: () => context.push(
                                    '/field-detail',
                                    extra: field,
                                  ),
                                  child: const Text('Detail'),
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
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
