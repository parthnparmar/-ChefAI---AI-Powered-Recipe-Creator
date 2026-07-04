import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../providers/recipe_provider.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fb = FirebaseService();
      if (_isLogin) {
        await fb.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
      } else {
        await fb.signUpWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
      }
      if (mounted) {
        // Sync cloud recipes after login
        final cloudRecipes = await fb.fetchCloudRecipes();
        if (cloudRecipes.isNotEmpty && mounted) {
          for (final r in cloudRecipes) {
            await context.read<RecipeProvider>().saveRecipe(r);
          }
        }
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isLogin
                  ? 'Signed in! Recipes synced.'
                  : 'Account created!')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Sign In' : 'Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(Icons.cloud_sync,
                    size: 72, color: Theme.of(context).primaryColor)
                .animate()
                .scale()
                .fadeIn(),
            const SizedBox(height: 8),
            Text('Cloud Sync & Backup',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Sign in to sync your recipes across devices',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ).animate().shake(),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isLogin ? 'Sign In' : 'Create Account'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _isLogin = !_isLogin;
                _error = null;
              }),
              child: Text(_isLogin
                  ? "Don't have an account? Sign Up"
                  : 'Already have an account? Sign In'),
            ),
            if (_isLogin)
              TextButton(
                onPressed: () async {
                  if (_emailCtrl.text.trim().isEmpty) {
                    setState(() => _error = 'Enter your email first');
                    return;
                  }
                  await FirebaseService()
                      .sendPasswordReset(_emailCtrl.text.trim());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password reset email sent')),
                    );
                  }
                },
                child: const Text('Forgot Password?'),
              ),
          ],
        ),
      ),
    );
  }
}
