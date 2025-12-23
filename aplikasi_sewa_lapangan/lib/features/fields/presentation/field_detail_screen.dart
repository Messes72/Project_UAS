import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FieldDetailScreen extends StatelessWidget {
  final FieldModel field;

  const FieldDetailScreen({super.key, required this.field});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    // Helper untuk load image
    Widget buildImage() {
      if (field.images.isEmpty) {
        return Container(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[300],
          child: const Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
        );
      }
      
      final imageUrl = field.images.first;
      final imageProvider = imageUrl.startsWith('http')
          ? NetworkImage(imageUrl)
          : NetworkImage(
              Supabase.instance.client.storage
                  .from('field-images')
                  .getPublicUrl(imageUrl),
            );

      return Image(
        image: imageProvider,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey,
          child: const Icon(Icons.broken_image),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. APP BAR
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: Icon(Icons.favorite_border, color: Colors.white),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  buildImage(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black45, Colors.transparent, Colors.transparent, Colors.black54],
                        stops: [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. CONTENT
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),

                    // Title & Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            field.name,
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber)),
                          child: const Row(children: [Icon(Icons.star, color: Colors.amber, size: 16), SizedBox(width: 4), Text("4.8", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Address
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(child: Text(field.address, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Price & Status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey.shade200),
                        boxShadow: [if (!isDarkMode) BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Price per hour', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('Rp ${field.pricePerHour.toString()}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.greenAccent : Colors.green[700])),
                          ]),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: field.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text(field.isActive ? 'Available' : 'Unavailable', style: TextStyle(color: field.isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- FACILITIES SECTION (DYNAMIC) ---
                    if (field.facilities.isNotEmpty) ...[
                      Text('Facilities', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: field.facilities.map((facilityName) {
                            return _buildFacilityChip(context, facilityName);
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Description
                    Text('Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      (field.description != null && field.description!.isNotEmpty) ? field.description! : 'No description provided.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), height: 1.6),
                    ),
                    
                    const SizedBox(height: 100), 
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: field.isActive ? () => context.pushNamed('booking', extra: field) : null,
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), disabledBackgroundColor: Colors.grey[300]),
            child: const Text('Book Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk Chip Fasilitas (Dynamic Icon)
  Widget _buildFacilityChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Mapping Nama Fasilitas ke Icon
    IconData getIcon(String name) {
      final n = name.toLowerCase();
      if (n.contains('wifi')) return Icons.wifi;
      if (n.contains('parking')) return Icons.local_parking;
      if (n.contains('shower')) return Icons.shower;
      if (n.contains('canteen') || n.contains('food')) return Icons.fastfood;
      if (n.contains('locker')) return Icons.lock;
      if (n.contains('toilet') || n.contains('wc')) return Icons.wc;
      if (n.contains('mosque') || n.contains('musholla')) return Icons.mosque;
      if (n.contains('tribun')) return Icons.stadium;
      return Icons.check_circle_outline; // Default icon
    }

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getIcon(label), size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}