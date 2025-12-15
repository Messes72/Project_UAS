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
          children: [
            TextField(
              controller: _nameController,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(labelText: 'Name', errorText: _nameError),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
              decoration: InputDecoration(labelText: 'Email', errorText: _emailError),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              onChanged: (_) {
                if (_passwordError != null) setState(() => _passwordError = null);
              },
              decoration: InputDecoration(labelText: 'Password', errorText: _passwordError),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Register'),
              ),
            ),
            if (_generalError != null) ...[
              const SizedBox(height: 12),
              Text(
                _generalError!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            TextButton(
              onPressed: () => context.pushNamed('login'),
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
