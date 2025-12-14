import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasi_sewa_lapangan/features/auth/data/auth_repository.dart';
import 'package:aplikasi_sewa_lapangan/features/auth/presentation/login_screen.dart';
import 'package:aplikasi_sewa_lapangan/features/auth/presentation/register_screen.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/presentation/owner_dashboard_screen.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/presentation/add_field_screen.dart';
import 'package:aplikasi_sewa_lapangan/features/home/presentation/home_screen.dart'; // New Home
import 'package:aplikasi_sewa_lapangan/features/bookings/presentation/field_search_screen.dart'; // Renamed Search
import 'package:aplikasi_sewa_lapangan/features/bookings/presentation/booking_screen.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/data/field_model.dart';
import 'package:aplikasi_sewa_lapangan/features/bookings/presentation/my_bookings_screen.dart';
import 'package:aplikasi_sewa_lapangan/features/maps/presentation/fields_map_screen.dart';
import 'package:aplikasi_sewa_lapangan/features/settings/presentation/settings_screen.dart';
import 'package:aplikasi_sewa_lapangan/core/theme_provider.dart';
import 'package:aplikasi_sewa_lapangan/features/fields/presentation/field_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Env
  try {
    await dotenv.load(fileName: ".env");
    print('DEBUG: .env loaded successfully');
  } catch (e) {
    print('DEBUG: Failed to load .env: $e');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'] ?? '',
  );

  // Initialize Shared Preferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authRepositoryProvider).authStateChanges(),
    ),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;
      final path = state.uri.path;
      print('DEBUG: Redirect Check - Path: $path, Auth: $isAuthenticated');

      // Fallback for user role debug
      if (isAuthenticated) {
        final user = Supabase.instance.client.auth.currentUser;
        print('DEBUG: Metadata: ${user?.userMetadata}');
      }

      final isLogin = path == '/login';
      final isRegister = path == '/register';

      final publicRoutes = [
        '/',
        '/login',
        '/register',
        '/fields',
        '/field-detail',
        '/map',
        '/settings',
      ];

      final isPublic =
          publicRoutes.contains(path) || path.startsWith('/field-detail');

      if (!isAuthenticated) {
        if (!isPublic && !path.startsWith('/booking')) {
          print('DEBUG: Unauth access to protected -> Redirect to /');
          return '/';
        }
        if (path.startsWith('/booking')) {
          print('DEBUG: Unauth booking -> Redirect to /login');
          return '/login';
        }
        return null; // Allowed public route
      }

      // Authenticated
      if (isAuthenticated) {
        final email = session.user.email;
        String role = session.user.userMetadata?['role'] ?? 'user';

        print('DEBUG: Auth Check - Email: $email, RawRole: $role, Path: $path');

        if (email == 'owner@gmail.com') role = 'owner';
        if (email == 'admin@gmail.com') role = 'admin';

        print('DEBUG: ComputedRole: $role');

        final isOwnerOrAdmin = role == 'owner' || role == 'admin';

        // If Owner/Admin is on Login, Register, OR Home ('/'), send to Dashboard
        if (isOwnerOrAdmin && (isLogin || isRegister || path == '/')) {
          print('DEBUG: Owner/Admin redirect to Dashboard');
          return '/owner-dashboard';
        }

        // If User is on Login or Register, send to Home
        if (!isOwnerOrAdmin && (isLogin || isRegister)) {
          print('DEBUG: User redirect to Home');
          return '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/fields',
        name: 'fields',
        builder: (context, state) => const FieldSearchScreen(),
      ),
      GoRoute(
        path: '/owner-dashboard',
        name: 'owner_dashboard',
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        path: '/owner/add-field',
        name: 'add_field',
        builder: (context, state) {
          final field = state.extra as FieldModel?;
          return AddFieldScreen(field: field);
        },
      ),
      GoRoute(
        path: '/booking',
        name: 'booking',
        builder: (context, state) {
          final field = state.extra as FieldModel;
          return BookingScreen(field: field);
        },
      ),
      GoRoute(
        path: '/my-bookings',
        name: 'my_bookings',
        builder: (context, state) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const FieldsMapScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/field-detail',
        name: 'field_detail',
        builder: (context, state) {
          final field = state.extra as FieldModel;
          return FieldDetailScreen(field: field);
        },
      ),
    ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Sewa Lapangan',
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green.shade600,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
          primary: Colors.green.shade400,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.green.shade900,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
