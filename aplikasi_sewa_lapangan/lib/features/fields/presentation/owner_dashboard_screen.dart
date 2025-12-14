import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasi_sewa_lapangan/features/auth/data/auth_repository.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_repository.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(myFieldsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Fields'),
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
            return const Center(child: Text('No fields added yet.'));
          }
          return ListView.builder(
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              return ListTile(
                title: Text(field.name),
                subtitle: Text('Rp ${field.pricePerHour}/hour'),
                trailing: Switch(
                  value: field.isActive,
                  onChanged: (val) {
                    // TODO: Implement toggle active status
                  },
                ),
                onTap: () {
                  // TODO: Navigate to detail/edit
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/owner/add-field'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
