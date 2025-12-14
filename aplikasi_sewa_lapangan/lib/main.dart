import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasi_sewa_lapangan/features/auth/data/auth_repository.dart';
import 'package:aplikasi_sewa_lapangan/features/auth/presentation/login_screen.dart';
import 'package:aplikasi_sewa_lapangan/features/auth/presentation/register_screen.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/presentation/owner_dashboard_screen.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/presentation/add_field_screen.dart';
import 'package:aplikasi_sewa_lapangan/features/bookings/presentation/home_screen.dart';
import 'package:aplikasi_sewa_lapangan/features/bookings/presentation/booking_screen.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Env
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthStateWrapper()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/owner/add-field',
      builder: (context, state) => const AddFieldScreen(),
    ),
    GoRoute(
      path: '/booking',
      builder: (context, state) {
        final field = state.extra as FieldModel;
        return BookingScreen(field: field);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sewa Lapangan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class AuthStateWrapper extends ConsumerWidget {
  const AuthStateWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      data: (authState) {
        final session = authState.session;
        if (session != null) {
          // Check role from metadata
          final role = session.user.userMetadata?['role'] ?? 'user';
          if (role == 'owner') {
            return const OwnerDashboardScreen();
          }
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}
