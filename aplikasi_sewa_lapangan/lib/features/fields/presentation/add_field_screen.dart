import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_model.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class AddFieldScreen extends ConsumerStatefulWidget {
  final FieldModel? field; // Optional for Edit Mode
  const AddFieldScreen({super.key, this.field});

  @override
  ConsumerState<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends ConsumerState<AddFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _addressController;
  bool _isLoading = false;

  XFile? _selectedImage;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    final f = widget.field;
    _nameController = TextEditingController(text: f?.name ?? '');
    _descController = TextEditingController(text: f?.description ?? '');
    _priceController = TextEditingController(
      text: f?.pricePerHour.toString() ?? '',
    );
    _addressController = TextEditingController(text: f?.address ?? '');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Image Validation: Required only for Create, Optional for Update
    if (widget.field == null && _selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.field != null) {
        // Update Logic
        await ref.read(fieldRepositoryProvider).updateField(widget.field!.id, {
          'name': _nameController.text,
          'description': _descController.text,
          'price_per_hour': double.parse(_priceController.text),
          'address': _addressController.text,
        });

        // Image Update (Optional)
        if (_selectedImage != null) {
          final fileExt = _selectedImage!.name.split('.').last;
          final fileName =
              '${widget.field!.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          await Supabase.instance.client.storage
              .from('field-images')
              .uploadBinary(
                fileName,
                _imageBytes!,
                fileOptions: FileOptions(contentType: 'image/$fileExt'),
              );
          await ref
              .read(fieldRepositoryProvider)
              .addFieldImage(widget.field!.id, fileName);
        }
      } else {
        // Create Logic
        final fieldId = const Uuid().v4();
        final field = FieldModel(
          id: fieldId,
          ownerId: '',
          name: _nameController.text,
          description: _descController.text,
          pricePerHour: double.parse(_priceController.text),
          address: _addressController.text,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await ref.read(fieldRepositoryProvider).addField(field);

        final fileExt = _selectedImage!.name.split('.').last;
        final fileName =
            '${fieldId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        await Supabase.instance.client.storage
            .from('field-images')
            .uploadBinary(
              fileName,
              _imageBytes!,
              fileOptions: FileOptions(contentType: 'image/$fileExt'),
            );
        await ref
            .read(fieldRepositoryProvider)
            .addFieldImage(fieldId, fileName);
      }

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
    final isEdit = widget.field != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Field' : 'Add New Field')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                decoration: const InputDecoration(
                  labelText: 'Price per Hour (Rp)',
                ),
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

              // Image Picker
              const Text(
                'Field Image',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_imageBytes != null)
                Stack(
                  children: [
                    Image.memory(
                      _imageBytes!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                            _imageBytes = null;
                          });
                        },
                      ),
                    ),
                  ],
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Select Image'),
                    ),
                  ),
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
