import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app;

class AuthService {
  bool get _supabaseReady {
    try {
      final _ = Supabase.instance.client; // throws if not initialized
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    if (!_supabaseReady) {
      throw StateError('Supabase not initialized. Configure SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    try {
      final res = await Supabase.instance.client.auth
          .signInWithPassword(email: usernameOrEmail, password: password);
      return res.user != null;
    } catch (e) {
      print('Supabase login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    if (!_supabaseReady) {
      throw StateError('Supabase not initialized.');
    }
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      print('Supabase logout error: $e');
    }
  }

  Future<String?> getToken() async {
    if (!_supabaseReady) return null;
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (e) {
      print('Supabase get token error: $e');
      return null;
    }
  }

  Future<app.User?> getCurrentUser() async {
    if (!_supabaseReady) return null;
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

  Future<bool> isLoggedIn() async {
    if (!_supabaseReady) return false;
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (e) {
      print('Supabase isLoggedIn error: $e');
      return false;
    }
  }
}
