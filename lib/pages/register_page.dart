import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../widgets/app_theme.dart';
import '../widgets/custom_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add_alt_1_rounded, size: 72, color: AppTheme.primary),
              const SizedBox(height: 12),
              Text(
                'Create Your Account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        hint: 'Username',
                        icon: Icons.person_outline,
                        controller: _nameController,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        controller: _passwordController,
                        validator: (value) =>
                            value == null || value.length < 4 ? 'Min 4 characters' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.app_registration),
                        label: const Text('Register'),
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            setState(() => _errorMessage = null);
                            final name = _nameController.text.trim();
                            final pwd = _passwordController.text.trim();
                            final success = await context.read<AuthCubit>().register(name, pwd);

                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User registered successfully!'),
                                  backgroundColor: AppTheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              await Future.delayed(const Duration(seconds: 2));
                              if (mounted) {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            } else {
                              setState(() => _errorMessage = 'Username already exists');
                            }
                          }
                        },
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Already have an account? Login here',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
