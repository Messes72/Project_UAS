import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_model.dart';
import 'package:aplikasi_sewa_lapangan/features/bookings/presentation/field_search_screen.dart'; // Pastikan path ini benar
import 'package:supabase_flutter/supabase_flutter.dart';

class FieldsMapScreen extends ConsumerStatefulWidget {
  const FieldsMapScreen({super.key});

  @override
  ConsumerState<FieldsMapScreen> createState() => _FieldsMapScreenState();
}

class _FieldsMapScreenState extends ConsumerState<FieldsMapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(allFieldsProvider);
    final theme = Theme.of(context);
    // Kita tidak butuh isDarkMode lagi untuk URL tile, karena OSM warnanya tetap sama

    return Scaffold(
      // extendBodyBehindAppBar agar peta fullscreen sampai ke belakang status bar
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Field Locations'),
        backgroundColor: Colors.transparent, 
        elevation: 0,
        // Gradient agar tombol back & title tetap terbaca di atas peta
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: fieldsAsync.when(
        data: (fields) {
          // 1. Ambil hanya field yang punya koordinat valid
          final validFields = fields
              .where((f) => f.lat != null && f.lng != null)
              .toList();

          // 2. Tentukan titik tengah awal
          final initialCenter = validFields.isNotEmpty
              ? LatLng(validFields.first.lat!, validFields.first.lng!)
              : const LatLng(-7.2575, 112.7521); // Default: Surabaya

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 13.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  // --- PERUBAHAN DI SINI (Ganti TileLayer) ---
                  TileLayer(
                    // URL Standar OpenStreetMap (Berwarna)
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // Wajib diisi sesuai policy OSM
                    userAgentPackageName: 'com.sewalapangan.app', 
                  ),

                  // Layer Marker (Pin Lokasi)
                  MarkerLayer(
                    markers: validFields.map((field) {
                      return Marker(
                        point: LatLng(field.lat!, field.lng!),
                        width: 60,
                        height: 60,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () {
                            _showFieldPreview(context, field);
                            _mapController.move(LatLng(field.lat!, field.lng!), 15);
                          },
                          // Marker tetap menggunakan logic dark mode agar iconnya kontras jika user ganti tema HP
                          child: _CustomMarker(isDarkMode: theme.brightness == Brightness.dark),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              
              // Widget "My Location"
              Positioned(
                bottom: 30,
                right: 20,
                child: FloatingActionButton(
                  heroTag: 'my_loc',
                  backgroundColor: theme.cardColor,
                  child: Icon(Icons.my_location, color: theme.primaryColor),
                  onPressed: () {
                     _mapController.move(initialCenter, 13);
                  },
                ),
              )
            ],
          );
        },
        loading: () => Container(
          color: theme.scaffoldBackgroundColor,
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Container(
          color: theme.scaffoldBackgroundColor,
          child: Center(child: Text('Error loading map: $err')),
        ),
      ),
    );
  }

  // Fungsi memunculkan Bottom Sheet Preview
  void _showFieldPreview(BuildContext context, FieldModel field) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FieldPreviewCard(field: field),
    );
  }
}

// --- WIDGET PENDUKUNG ---

class _CustomMarker extends StatelessWidget {
  final bool isDarkMode;
  const _CustomMarker({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Icon(
          Icons.location_on,
          color: Colors.red[600],
          size: 50,
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        const Positioned(
          top: 8,
          child: Icon(
            Icons.sports_soccer,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }
}

class _FieldPreviewCard extends StatelessWidget {
  final FieldModel field;
  const _FieldPreviewCard({required this.field});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: field.images.isNotEmpty
                  ? Image.network(
                      field.images.first.startsWith('http')
                          ? field.images.first
                          : Supabase.instance.client.storage
                              .from('field-images')
                              .getPublicUrl(field.images.first),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.sports_soccer, size: 50, color: Colors.grey),
                    ),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        field.address,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price/hour', style: theme.textTheme.bodySmall),
                        Text(
                          'Rp ${field.pricePerHour}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.pop(); 
                        context.push('/field-detail', extra: field);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View Detail'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}