import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasi_sewa_lapangan/features/auth/data/auth_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _role = 'user';
  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _emailController.text,
            password: _passwordController.text,
            name: _nameController.text,
            role: _role,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        final msg = _extractErrorMessage(e);
        final lower = msg.toLowerCase();
        setState(() {
          if (lower.contains('email')) {
            _emailError = msg;
          } else if (lower.contains('password')) {
            _passwordError = msg;
          } else if (lower.contains('name')) {
            _nameError = msg;
          } else {
            _generalError = msg;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _extractErrorMessage(Object e) {
    // Prefer a `message` property on exception-like objects
    try {
      final dyn = e as dynamic;
      if (dyn is String) return dyn;
      if (dyn.message != null && dyn.message is String) return dyn.message as String;
      if (dyn.error != null) {
        final err = dyn.error;
        if (err is String) return err;
        if ((err as dynamic).message != null) return (err as dynamic).message as String;
      }
    } catch (_) {}

    final s = e.toString();
    // Extract after common prefixes like 'Exception: ' or 'Error: '
    final m = RegExp(r'(?:(?:Exception|Error):\s*)(.*)', dotAll: true).firstMatch(s);
    if (m != null) return m.group(1)!.trim();
    return s;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Label & Field tetap rata kiri
          children: [
            // --- BAGIAN HEADER (LOGO & JUDUL DI TENGAH) ---
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 100, // Sesuaikan ukuran logo Anda
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Registrasi User',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Silakan isi formulir di bawah untuk membuat akun baru.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32), // Jarak ke input pertama

            // --- FIELD NAMA ---
            const Text(
              'Masukkan Nama Anda',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                hintText: 'Nama Lengkap',
                errorText: _nameError,
                border: const OutlineInputBorder(), // Menambah border agar lebih rapi
              ),
            ),
            
            const SizedBox(height: 16),

            // --- FIELD EMAIL ---
            const Text(
              'Masukkan Email Anda',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
              decoration: InputDecoration(
                hintText: 'email@contoh.com',
                errorText: _emailError,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            // --- FIELD PASSWORD ---
            const Text(
              'Masukkan Password Anda',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              onChanged: (_) {
                if (_passwordError != null) setState(() => _passwordError = null);
              },
              decoration: InputDecoration(
                hintText: 'Min. 6 karakter',
                errorText: _passwordError,
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),

            const SizedBox(height: 32),

            // --- TOMBOL REGISTER ---
            SizedBox(
              width: double.infinity,
              height: 50, // Membuat tombol sedikit lebih tebal
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Register', style: TextStyle(fontSize: 16)),
              ),
            ),

            // --- ERROR GENERAL ---
            if (_generalError != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _generalError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // --- NAVIGASI LOGIN ---
            Center(
              child: TextButton(
                onPressed: () => context.pushNamed('login'),
                child: const Text('Already have an account? Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  }