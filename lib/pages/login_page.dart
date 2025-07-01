import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../widgets/app_theme.dart';
import '../widgets/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthLoaded) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (state is AuthFailure) {
            setState(() {
              _errorMessage = state.message;
            });
          }
        },
        child: Center(
          child: SizedBox(
            width: 380,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_menu, size: 72, color: AppTheme.primary),
                const SizedBox(height: 12),
                Text(
                  'Welcome Back, Chef!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
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
                          icon: const Icon(Icons.login),
                          label: const Text('Login'),
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              setState(() => _errorMessage = null);
                              final name = _nameController.text.trim();
                              final pwd = _passwordController.text.trim();
                              context.read<AuthCubit>().login(name, pwd);
                            }
                          },
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text(
                    "Don't have an account? Register here",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
