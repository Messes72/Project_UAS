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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.pushNamed('settings'),
          ),
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
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          
          

          return SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section
                Container(
                  width: double.infinity,
                  height: 520,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        isDarkMode
                            ? 'assets/images/bg_home.png'
                            : 'assets/images/bg_home_light.png',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: isDarkMode
                            ? [
                                const Color.fromARGB(255, 16, 20, 15).withOpacity(0.95),
                                const Color.fromARGB(255, 16, 20, 15).withOpacity(0.55),
                                const Color.fromARGB(255, 16, 20, 15).withOpacity(0.25),
                                Colors.transparent,
                              ]
                            : [
                                Colors.white.withOpacity(0.35),
                                Colors.white.withOpacity(0.25),
                                Colors.white.withOpacity(0.15),
                                Colors.transparent,
                              ],
                      ),
                    ),

                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sewa Lapangan Olahraga',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Lebih Cepat, Mudah, Tanpa Ribet',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Temukan dan booking lapangan futsal, basket, badminton, dan lainnya di sekitar Anda.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 32),


                        if (!isAuthenticated)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () => context.pushNamed('login'),
                                child: const Text('Login'),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton(
                                onPressed: () => context.pushNamed('register'),
                                child: const Text('Daftar Sekarang'),
                              ),
                            ],
                          )
                        else
                          ElevatedButton(
                            onPressed: () => context.pushNamed('fields'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Booking Sekarang', style: TextStyle(fontSize: 16)),
                          ),
                      ],
                    ),
                  ),
                ),
                

                Padding(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'Kenapa Memilih Kami?',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: [
                        _featureBox(
                          context: context,
                          icon: Icons.touch_app,
                          title: 'Booking Instan',
                          desc: 'Pilih jam, cek ketersediaan, dan langsung booking.',
                        ),
                        _featureBox(
                          context: context,
                          icon: Icons.payment,
                          title: 'Pembayaran Mudah',
                          desc: 'Upload bukti pembayaran dan konfirmasi instan.',
                        ),
                        _featureBox(
                          context: context,
                          icon: Icons.access_time,
                          title: 'Tersedia Kapan Saja',
                          desc: 'Layanan 24 jam yang dapat diakses kapanpun.',
                        ),
                      ],
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

    Widget _featureBox({
    required IconData icon,
    required String title,
    required String desc,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

}
