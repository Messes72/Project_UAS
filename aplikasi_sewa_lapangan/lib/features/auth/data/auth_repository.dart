import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client.auth);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

class AuthRepository {
  final GoTrueClient _auth;

  AuthRepository(this._auth);

  Stream<AuthState> authStateChanges() {
    return _auth.onAuthStateChange;
  }

  User? get currentUser => _auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    return await _auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': role},
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
