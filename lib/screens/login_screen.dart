import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_utils.dart';
import 'dashboard_screen.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Auth screens use a distinct blue palette (keeps rest of app green)
  static const Color _primaryBlue = Color(0xFF2F57D9);
  static const Color _inputFill = Color(0xFFF4F6FF);

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Background accents to echo the mockup style
            Positioned(
              top: -130,
              left: -90,
              child: _softBlueBlob(260),
            ),
            Positioned(
              bottom: -160,
              right: -110,
              child: _softBlueBlob(300),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 24 - 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      // Title and subtitle (no card container)
                      Text(
                        'Login here',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headline1.copyWith(
                          color: _primaryBlue,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Welcome back you've\nbeen missed!",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headline2,
                      ),
                      const SizedBox(height: 24),
                      // Username Field
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          filled: true,
                          fillColor: _inputFill,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryBlue.withOpacity(0.35), width: 1.2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          filled: true,
                          fillColor: _inputFill,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey[700],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryBlue.withOpacity(0.20), width: 1.2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (!ValidationHelper.isValidPassword(value)) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password recovery is not implemented.')),
                            );
                          },
                          child: const Text(
                            'Forgot your password?',
                            style: TextStyle(
                              color: _primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Login Button
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 6,
                                shadowColor: _primaryBlue.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'Sign in',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                            ),
                          );
                        },
                      ),
                      // Error Message
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          if (authProvider.error != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                authProvider.error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
            // Back icon on top (above content for tap priority)
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: Colors.black87,
                onPressed: () {
                  final navigator = Navigator.of(context);
                  if (navigator.canPop()) {
                    navigator.pop();
                  } else {
                    navigator.pushReplacement(
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    );
                  }
                },
                tooltip: 'Back',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      }
    }
  }
}

Widget _softBlueBlob(double size) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [Color(0x112F57D9), Colors.transparent],
        center: Alignment.center,
        radius: 0.9,
      ),
    ),
  );
}
