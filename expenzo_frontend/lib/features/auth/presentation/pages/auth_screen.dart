import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../shared/presentation/pages/main_navigation.dart';
import '../../../../core/database/hive_database.dart';
import '../../../../core/network/api_client.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showServerSettingsDialog() {
    final controller = TextEditingController(
      text: HiveDatabase.settingsBox.get('serverUrl') as String? ?? ApiClient.baseUrl,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text('Server Settings', style: TextStyle(color: Colors.white, fontFamily: 'Outfit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure backend server API URL:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Server Base URL',
                  hintText: 'e.g., http://10.178.220.222:8081/api',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Default: ${ApiClient.defaultBaseUrl}',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUrl = controller.text.trim();
                await HiveDatabase.settingsBox.put('serverUrl', newUrl);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Server URL updated to: $newUrl')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    bool success;

    if (_isLogin) {
      success = await authVm.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      success = await authVm.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isLogin ? 'Welcome back!' : 'Account created!')),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVm.error ?? 'Authentication failed'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded, color: AppTheme.textSecondary),
            tooltip: 'Server Settings',
            onPressed: _showServerSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Header
                  const Center(
                    child: Text(
                      '⚡',
                      style: TextStyle(fontSize: 64),
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Expenzo',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Type naturally. Understand instantly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 40),

                  // Name Field (only for Register)
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textSecondary),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Please enter your name';
                        return null;
                      },
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                  ],

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter your email';
                      if (!val.contains('@')) return 'Please enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter your password';
                      if (val.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: authVm.isLoading ? null : _submit,
                    child: authVm.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(_isLogin ? 'Sign In' : 'Sign Up'),
                  ),
                  const SizedBox(height: 16),

                  // Toggle Login / Register
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin ? "Don't have an account? Sign Up" : 'Already have an account? Sign In',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white10)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('OR', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.white10)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Guest Mode Button
                  OutlinedButton(
                    onPressed: () {
                      // Login as anonymous / guest
                      // We don't save token, but navigate directly to MainNavigation
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MainNavigation()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Continue as Guest (Offline Mode)'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
