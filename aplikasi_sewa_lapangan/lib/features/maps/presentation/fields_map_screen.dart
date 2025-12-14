import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // import latlong2
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Add go_router import
import 'package:aplikasi_sewa_lapangan/features/bookings/presentation/field_search_screen.dart'; // For provider

class FieldsMapScreen extends ConsumerWidget {
  const FieldsMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(allFieldsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Field Locations')),
      body: fieldsAsync.when(
        data: (fields) {
          // Default to Indonesia center if no fields or invalid lat/lng
          // Need to handle fields that might not have lat/lng set
          final validFields = fields
              .where((f) => f.lat != null && f.lng != null)
              .toList();

          final initialCenter = validFields.isNotEmpty
              ? LatLng(validFields.first.lat!, validFields.first.lng!)
              : const LatLng(-6.200000, 106.816666); // Jakarta

          return FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.aplikasi_sewa_lapangan',
              ),
              MarkerLayer(
                markers: validFields.map((field) {
                  return Marker(
                    point: LatLng(field.lat!, field.lng!),
                    width: 80,
                    height: 80,
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to booking, similar to home screen
                        context.push('/booking', extra: field);
                      },
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [BoxShadow(blurRadius: 4)],
                            ),
                            child: Text(
                              field.name,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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
