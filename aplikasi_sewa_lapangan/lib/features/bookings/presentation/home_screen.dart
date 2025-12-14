import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasi_sewa_lapangan/features/auth/data/auth_repository.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_model.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_repository.dart';

final allFieldsProvider = FutureProvider<List<FieldModel>>((ref) async {
  return ref.watch(fieldRepositoryProvider).getAllActiveFields();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(allFieldsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Fields'),
        actions: [
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(field.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(field.address),
                      Text(
                        'Rp ${field.pricePerHour}/hour',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    // TODO: Navigate to Booking/Detail
                  },
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
