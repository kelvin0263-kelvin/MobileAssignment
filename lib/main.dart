import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/job_provider.dart';
import 'providers/procedure_provider.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'utils/app_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final url = const String.fromEnvironment('SUPABASE_URL', defaultValue: Env.supabaseUrl);
    final anon = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: Env.supabaseAnonKey);

    bool _validUrl(String s) {
      final u = Uri.tryParse(s);
      return u != null && (u.scheme == 'https' || u.scheme == 'http') && u.host.isNotEmpty;
    }

    if (_validUrl(url) && anon.isNotEmpty) {
      await Supabase.initialize(
        url: url,
        anonKey: anon,
      );
    } else {
      // Skip supabase init if not configured; app will use mocks
      // Helpful log for devs
      // ignore: avoid_print
      print('Supabase not initialized: invalid URL or missing anon key.');
    }
  } catch (_) {
    // If not provided, the app works with mock services
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => ProcedureProvider()),
      ],
      child: MaterialApp(
        title: 'Mechanic Hub',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          chipTheme: const ChipThemeData(
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(color: AppColors.textPrimary),
            secondaryLabelStyle: TextStyle(color: Colors.white),
            checkmarkColor: Colors.white,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (authProvider.isLoggedIn) {
          return const DashboardScreen();
        }
        
        // Show welcome before login when logged out
        return const WelcomeScreen();
      },
    );
  }
}
