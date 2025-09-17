import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app;

class AuthService {
  // We keep the previous keys to maintain backward compatibility if Supabase
  // env vars are not provided. This lets the app run with mock auth.
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  bool get _supabaseReady {
    try {
      // Accessing instance throws if not initialized
      final _ = Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    if (_supabaseReady) {
      try {
        final res = await Supabase.instance.client.auth
            .signInWithPassword(email: usernameOrEmail, password: password);
        return res.user != null;
      } catch (e) {
        print('Supabase login error: $e');
        return false;
      }
    }

    // Fallback mock login
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (usernameOrEmail == 'mechanic' && password == 'password') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            _tokenKey, 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}');
        await prefs.setString(_userIdKey, '1');
        return true;
      }
      return false;
    } catch (e) {
      print('Mock login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    if (_supabaseReady) {
      try {
        await Supabase.instance.client.auth.signOut();
        return;
      } catch (e) {
        print('Supabase logout error: $e');
      }
    }
    // Fallback mock logout
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
    } catch (e) {
      print('Mock logout error: $e');
    }
  }

  Future<String?> getToken() async {
    if (_supabaseReady) {
      try {
        return Supabase.instance.client.auth.currentSession?.accessToken;
      } catch (e) {
        print('Supabase get token error: $e');
        return null;
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Mock get token error: $e');
      return null;
    }
  }

  Future<app.User?> getCurrentUser() async {
    if (_supabaseReady) {
      try {
        final u = Supabase.instance.client.auth.currentUser;
        if (u == null) return null;

        // Try to fetch from 'profiles' table if it exists; ignore if not found
        try {
          final data = await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', u.id)
              .maybeSingle();
          if (data != null) {
            return app.User(
              id: u.id,
              name: (data['name'] ?? 'User') as String,
              email: u.email ?? '',
              role: (data['role'] ?? 'user') as String,
              contactNo: data['contact_no'] as String?,
              address: data['address'] as String?,
              state: data['state'] as String?,
              district: data['district'] as String?,
              gender: data['gender'] as String?,
            );
          }
        } catch (_) {}

        final meta = u.userMetadata ?? {};
        return app.User(
          id: u.id,
          name: (meta['name'] ?? 'User') as String,
          email: u.email ?? '',
          role: (meta['role'] ?? 'user') as String,
        );
      } catch (e) {
        print('Supabase getCurrentUser error: $e');
        return null;
      }
    }

    // Fallback mock user
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      if (userId == null) return null;
      return app.User(
        id: '1',
        name: 'John Mechanic',
        email: 'john.mechanic@greenstem.com',
        role: 'mechanic',
        contactNo: '+60123456789',
        address: '123 Workshop Street, Kuala Lumpur',
        state: 'Selangor',
        district: 'Petaling Jaya',
        gender: 'Male',
      );
    } catch (e) {
      print('Mock getCurrentUser error: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    if (_supabaseReady) {
      try {
        return Supabase.instance.client.auth.currentSession != null;
      } catch (e) {
        print('Supabase isLoggedIn error: $e');
        return false;
      }
    }
    try {
      final token = await getToken();
      return token != null;
    } catch (e) {
      print('Mock isLoggedIn error: $e');
      return false;
    }
  }
}
