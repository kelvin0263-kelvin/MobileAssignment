import 'package:flutter/material.dart';
import '../utils/app_utils.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Auth screens use a blue palette independent from the app's green theme
  static const Color _primaryBlue = Color(0xFF2F57D9);
  static const Color _primaryBlueDark = Color(0xFF1C3DB3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle geometric background accents
            Positioned(
              top: -120,
              right: -80,
              child: _softCircle(220),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: _softCircle(260),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          // Illustration from assets
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Image.asset(
                              'assets/images/welcomeimage.png',
                              height: 230,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              children: [
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: AppTextStyles.headline1.copyWith(
                                      fontSize: 26,
                                      height: 1.3,
                                    ),
                                    children: const [
                                      TextSpan(text: 'Discover Your\n'),
                                      TextSpan(
                                        text: 'Dream Job ',
                                        style: TextStyle(color: _primaryBlue),
                                      ),
                                      TextSpan(text: 'here'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Explore all the existing job roles based on your\ninterest and study major',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body2,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 6,
                                      shadowColor: _primaryBlue.withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _softCircle(double size) {
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
}
