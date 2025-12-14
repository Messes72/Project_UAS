import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasi_sewa_lapangan/features/auth/data/auth_repository.dart';
import 'package:aplikasi_sewa_lapangan/core/theme_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sewa Lapangan'),
        actions: [
          // Theme Toggle
          Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeModeProvider);
              return IconButton(
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                onPressed: () {
                  final newMode = themeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                  ref.read(themeModeProvider.notifier).setMode(newMode);
                },
              );
            },
          ),
          // Settings (Global)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.pushNamed('settings'),
          ),
          // Logout (if logged in)
          authStateAsync.when(
            data: (state) {
              if (state.session != null) {
                return IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: authStateAsync.when(
        data: (authState) {
          final user = authState.session?.user;
          final isAuthenticated = user != null;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section
                Container(
                  width: double.infinity,
                  color: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 60,
                    horizontal: 24,
                  ),
                  child: Column(
                    children: [
                      Text(
                        isAuthenticated
                            ? 'Welcome back, ${user.userMetadata?['name'] ?? 'User'}!'
                            : 'Sewa Lapangan Olahraga',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Dengan Mudah & Cepat',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Temukan dan booking lapangan futsal, basket, badminton, dan lainnya di sekitar Anda.',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 40),
                      // Buttons
                      Column(
                        children: [
                          if (isAuthenticated) ...[
                            ElevatedButton(
                              onPressed: () => context.pushNamed('fields'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.green.shade700,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text('Mulai Cari Lapangan'),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () => context.pushNamed('my_bookings'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text('Booking Saya'),
                            ),
                          ] else ...[
                            ElevatedButton(
                              onPressed: () => context.pushNamed('login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.green.shade700,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text('Cari Lapangan (Login)'),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () => context.pushNamed('register'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text('Daftar Sekarang'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Features Section
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        'Kenapa Memilih Kami?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildFeatureCard(
                        context,
                        title: 'Booking Instan',
                        desc:
                            'Pilih jam, cek ketersediaan, dan langsung booking.',
                        icon: Icons.touch_app,
                      ),
                      _buildFeatureCard(
                        context,
                        title: 'Pembayaran Mudah',
                        desc: 'Upload bukti pembayaran dan konfirmasi instan.',
                        icon: Icons.payment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
