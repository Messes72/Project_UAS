import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_model.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_repository.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/presentation/location_picker_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart'; 
import 'dart:typed_data';

class AddFieldScreen extends ConsumerStatefulWidget {
  final FieldModel? field; 
  const AddFieldScreen({super.key, this.field});

  @override
  ConsumerState<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends ConsumerState<AddFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _addressController;
  
  // Coordinate Controllers 
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  bool _isLoading = false;
  XFile? _selectedImage;
  Uint8List? _imageBytes;

  final List<String> _availableFacilities = [
    'Free WiFi',
    'Parking Area',
    'Shower Room',
    'Canteen',
    'Locker Room',
    'Musholla',
    'Toilet'
  ];
  List<String> _selectedFacilities = [];

  @override
  void initState() {
    super.initState();
    final f = widget.field;
    _nameController = TextEditingController(text: f?.name ?? '');
    _descController = TextEditingController(text: f?.description ?? '');
    _priceController = TextEditingController(text: f?.pricePerHour.toString() ?? '');
    _addressController = TextEditingController(text: f?.address ?? '');
    
    if (f != null) {
      if (f.lat != null) _latController.text = f.lat.toString();
      if (f.lng != null) _lngController.text = f.lng.toString();
      _selectedFacilities = List.from(f.facilities); 
    }
    
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
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

  // --- LOGIC BUKA MAP ---
  Future<void> _openMapPicker() async {
    final LatLng? result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (result != null) {
      setState(() {
        _latController.text = result.latitude.toString();
        _lngController.text = result.longitude.toString();
      });
    }
  }

  double? _parseCoordinate(String input) {
    if (input.isEmpty) return null;
    
    final decimal = double.tryParse(input);
    if (decimal != null) return decimal;

    try {
      final regex = RegExp(r'''(\d+)[°\s]+(\d+)['\s]+(\d+(?:\.\d+)?)["\s]*([NSEW])''', caseSensitive: false);
      final match = regex.firstMatch(input.trim());

      if (match != null) {
        double deg = double.parse(match.group(1)!);
        double min = double.parse(match.group(2)!);
        double sec = double.parse(match.group(3)!);
        String dir = match.group(4)!.toUpperCase();

        double result = deg + (min / 60) + (sec / 3600);
        if (dir == 'S' || dir == 'W') result = -result;
        
        return result;
      }
    } catch (e) {
      debugPrint("Conversion Error: $e");
    }
    return null;
  }
  void _toggleFacility(String facility, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        _selectedFacilities.add(facility);
      } else {
        _selectedFacilities.remove(facility);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.field == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image for the field')),
      );
      return;
    }

    double? finalLat = _parseCoordinate(_latController.text);
    double? finalLng = _parseCoordinate(_lngController.text);

    if (finalLat == null || finalLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Coordinates! Use Map or format like -7.25')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      final dataMap = {
        'name': _nameController.text,
        'description': _descController.text,
        'price_per_hour': double.parse(_priceController.text),
        'address': _addressController.text,
        'lat': finalLat, 
        'lng': finalLng, 
        'facilities': _selectedFacilities,
      };

      String targetFieldId;

      if (widget.field != null) {
        targetFieldId = widget.field!.id;
        await ref.read(fieldRepositoryProvider).updateField(targetFieldId, dataMap);
      } else {
        targetFieldId = const Uuid().v4();
        final newField = FieldModel(
          id: targetFieldId,
          ownerId: currentUser.id,
          name: _nameController.text,
          description: _descController.text,
          pricePerHour: double.parse(_priceController.text),
          address: _addressController.text,
          lat: finalLat,
          lng: finalLng,
          isActive: true,
          createdAt: DateTime.now(),
          images: [],
          facilities: _selectedFacilities,
        );
        await ref.read(fieldRepositoryProvider).addField(newField);
      }

      if (_selectedImage != null) {
        final fileExt = _selectedImage!.name.split('.').last;
        final fileName = '${targetFieldId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        
        await Supabase.instance.client.storage
            .from('field-images')
            .uploadBinary(
              fileName,
              _imageBytes!,
              fileOptions: FileOptions(contentType: 'image/$fileExt'),
            );
        
        await ref.read(fieldRepositoryProvider).addFieldImage(targetFieldId, fileName);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Field saved successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.field != null;
    final theme = Theme.of(context);
    final isDarkMode = true; 
    
    final cardColor = theme.cardColor;
    final inputFillColor = isDarkMode ? theme.scaffoldBackgroundColor : Colors.grey.shade50;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade300;
    final textColor = theme.textTheme.bodyLarge?.color;
    final hintColor = theme.hintColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Field' : 'Register New Field'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardColor, boxShadow: [if (!isDarkMode) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Save Field', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 1 ---
              _buildSectionTitle('Field Image', theme),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: inputFillColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    image: _imageBytes != null
                    ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                    : (isEdit && widget.field!.images.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(
                              widget.field!.images.first.contains('http')
                                  ? widget.field!.images.first 
                                  : Supabase.instance.client.storage
                                      .from('field-images')
                                      .getPublicUrl(widget.field!.images.first), 
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (_imageBytes == null && (!isEdit || widget.field!.images.isEmpty))
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 48, color: theme.primaryColor),
                            const SizedBox(height: 8),
                            Text('Tap to upload image', style: TextStyle(color: hintColor)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // --- SECTION 2 ---
              _buildSectionTitle('Basic Information', theme),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: isDarkMode ? Border.all(color: borderColor) : null,
                  boxShadow: !isDarkMode ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))] : null,
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Field Name',
                      icon: Icons.sports_soccer,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      theme: theme, isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _priceController,
                      label: 'Price per Hour (Rp)',
                      icon: Icons.monetization_on_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      theme: theme, isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descController,
                      label: 'Description',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      theme: theme, isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Facilities', theme),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: isDarkMode ? Border.all(color: borderColor) : null,
                  boxShadow: !isDarkMode ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))] : null,
                ),
                child: Column(
                  children: _availableFacilities.map((facility) {
                    final isChecked = _selectedFacilities.contains(facility);
                    return CheckboxListTile(
                      title: Text(facility, style: TextStyle(color: textColor)),
                      value: isChecked,
                      activeColor: theme.primaryColor,
                      checkColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading, 
                      onChanged: (val) => _toggleFacility(facility, val),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 24),

              // --- SECTION 3: LOCATION & COORDINATES ---
              _buildSectionTitle('Location & Coordinates', theme),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: isDarkMode ? Border.all(color: borderColor) : null,
                  boxShadow: !isDarkMode ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))] : null,
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _addressController,
                      label: 'Full Address',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      theme: theme, isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.map, size: 18, color: hintColor),
                            const SizedBox(width: 8),
                            Text('Coordinates', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                          ],
                        ),
                        
                        // TOMBOL PICK MAP
                        TextButton.icon(
                          onPressed: _openMapPicker,
                          icon: const Icon(Icons.pin_drop),
                          label: const Text('Pick on Map'),
                          style: TextButton.styleFrom(
                            iconColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select from map OR input manual (Decimal / DMS)',
                      style: TextStyle(fontSize: 12, color: hintColor, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _latController,
                            label: 'Latitude',
                            hint: '-7.2575',
                            theme: theme, isDarkMode: isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _lngController,
                            label: 'Longitude',
                            hint: '112.7521',
                            theme: theme, isDarkMode: isDarkMode,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ThemeData theme,
    required bool isDarkMode,
    String? hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final inputFillColor = isDarkMode ? theme.scaffoldBackgroundColor : Colors.grey.shade50;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade300;
    final iconColor = isDarkMode ? Colors.white54 : Colors.grey;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.hintColor),
        hintText: hint,
        hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.5)),
        alignLabelWithHint: maxLines > 1,
        prefixIcon: icon != null ? Icon(icon, color: iconColor) : null,
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor),
        ),
      ),
    );
  }
}