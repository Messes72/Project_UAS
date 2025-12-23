import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasi_sewa_lapangan/features/auth/data/auth_repository.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_model.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- PROVIDERS ---

final allFieldsProvider = FutureProvider<List<FieldModel>>((ref) async {
  return ref.watch(fieldRepositoryProvider).getAllActiveFields();
});

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// --- MAIN SCREEN ---

class FieldSearchScreen extends ConsumerWidget {
  const FieldSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(allFieldsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final searchBarColor = isDarkMode ? Colors.grey[800] : Colors.grey[100];
    final searchBarBorderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final headerIconColor = isDarkMode ? Colors.white : Colors.green;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            
            SliverAppBar(
              floating: true,
              pinned: true, 
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: theme.scaffoldBackgroundColor,
              toolbarHeight: 70,
              
              title: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: searchBarColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: searchBarBorderColor),
                ),
                child: TextField(
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'Search name or location...',
                    hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: theme.hintColor),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: theme.hintColor, size: 20),
                            onPressed: () {
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                  ),
                ),
              ),

              actions: [
                IconButton(
                  icon: Icon(Icons.map_outlined, color: headerIconColor),
                  onPressed: () => context.push('/map'),
                  tooltip: 'Map View',
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: headerIconColor),
                  onSelected: (value) {
                    switch (value) {
                      case 'history':
                        context.push('/my-bookings');
                        break;
                      case 'settings':
                        context.push('/settings');
                        break;
                      case 'logout':
                        ref.read(authRepositoryProvider).signOut();
                        context.push('/home');
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem(
                        value: 'history',
                        child: Row(children: [Icon(Icons.history), SizedBox(width: 8), Text('My Bookings')]),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(children: [Icon(Icons.settings), SizedBox(width: 8), Text('Settings')]),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text('Logout', style: TextStyle(color: Colors.red))]),
                      ),
                    ];
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            // --- B. HEADER TEXT (Scrollable) ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Your Court',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Book the best sport venues nearby',
                      style: TextStyle(color: theme.hintColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // --- C. LIST CONTENT ---
            fieldsAsync.when(
              data: (fields) {
                final filteredFields = fields.where((field) {
                  final query = searchQuery.toLowerCase();
                  final name = field.name.toLowerCase();
                  final address = field.address.toLowerCase();
                  return name.contains(query) || address.contains(query);
                }).toList();

                if (filteredFields.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: theme.disabledColor),
                          const SizedBox(height: 16),
                          Text(
                            fields.isEmpty 
                                ? 'No active fields found.' 
                                : 'No result found for "$searchQuery"',
                            style: TextStyle(color: theme.disabledColor),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final field = filteredFields[index];
                        return _ModernFieldCard(field: field);
                      },
                      childCount: filteredFields.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET CARD (Modern Style) ---

class _ModernFieldCard extends StatelessWidget {
  final FieldModel field;

  const _ModernFieldCard({required this.field});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
        ],
        border: isDarkMode 
            ? Border.all(color: Colors.white.withOpacity(0.1)) 
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/field-detail', extra: field),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: field.images.isNotEmpty
                          ? Image.network(
                              field.images.first.startsWith('http')
                                  ? field.images.first
                                  : Supabase.instance.client.storage
                                      .from('field-images')
                                      .getPublicUrl(field.images.first),
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                                child: Icon(Icons.broken_image, 
                                  color: isDarkMode ? Colors.grey[700] : Colors.grey),
                              ),
                            )
                          : Container(
                              color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                              child: Icon(Icons.sports_soccer, 
                                size: 50, 
                                color: isDarkMode ? Colors.grey[700] : Colors.grey),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black87 : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text(
                            "4.8",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, 
                          size: 16, 
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            field.address,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: theme.dividerColor),
                    const SizedBox(height: 12),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Starts from',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${field.pricePerHour}',
                              style: TextStyle(
                                fontFamily: theme.textTheme.titleLarge?.fontFamily,
                                fontWeight: FontWeight.w800,
                                color: theme.primaryColor,
                                fontSize: 18
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Book Now',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}