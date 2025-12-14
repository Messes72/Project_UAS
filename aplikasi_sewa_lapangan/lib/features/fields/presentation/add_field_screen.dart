import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_model.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_repository.dart';
import 'package:uuid/uuid.dart';

class AddFieldScreen extends ConsumerStatefulWidget {
  const AddFieldScreen({super.key});

  @override
  ConsumerState<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends ConsumerState<AddFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final field = FieldModel(
        id: const Uuid()
            .v4(), // Generate temporary ID, database usually generates this but we need it for the model
        ownerId: '', // Will be set by repository
        name: _nameController.text,
        description: _descController.text,
        pricePerHour: double.parse(_priceController.text),
        address: _addressController.text,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Note: We need to modify repository to handle ignoring ID if DB generates it,
      // or rely on client-side UUID generation.
      // For now, let's assume we pass the object and Repo handles it.

      // However, our FieldRepository.addField uses .insert({...field.toJson()}).
      // If ID is in JSON and DB expects to generate it, it might conflict or be redundant.
      // Let's rely on the repository's logic (which currently inserts everything).
      // Ideally, we should remove ID from insert if it's auto-generated.

      await ref.read(fieldRepositoryProvider).addField(field);

      if (mounted) {
        ref.invalidate(myFieldsProvider); // Refresh the list
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Field')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Field Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price per Hour'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Field'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
