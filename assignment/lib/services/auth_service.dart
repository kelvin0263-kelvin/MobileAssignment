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

  Future<Map<String, dynamic>> resetPassword(String email) async {
    if (!_supabaseReady) {
      throw StateError('Supabase not initialized. Configure SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    
    // Simple email cleaning - just trim and lowercase
    String cleanEmail = email.trim().toLowerCase();
    
    print('Original email: "$email"');
    print('Cleaned email: "$cleanEmail"');
    print('Email length: ${cleanEmail.length}');
    print('Email bytes: ${cleanEmail.codeUnits}');
    
    // Validate email format
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return {'success': false, 'message': 'Please enter a valid email address.'};
    }
    
    // Let's try a different approach - attempt to sign in with a dummy password
    // This will tell us if the email exists without revealing if it's valid
    try {
      print('Attempting to check if user exists by trying dummy sign-in...');
      await Supabase.instance.client.auth.signInWithPassword(
        email: cleanEmail, 
        password: 'dummy_password_check'
      );
    } catch (e) {
      if (e is AuthApiException) {
        print('User check error code: ${e.code}');
        print('User check error message: ${e.message}');
        if (e.code == 'invalid_credentials') {
          print('✅ User exists but password is wrong (expected)');
        } else if (e.code == 'email_address_invalid') {
          print('❌ User does not exist in database');
        } else if (e.code == 'email_not_confirmed') {
          print('⚠️ User exists but email not confirmed - this might be the issue!');
        } else {
          print('Other error during user check: ${e.code} - ${e.message}');
        }
      }
    }
    
    try {
      print('Attempting password reset for: $cleanEmail');
      
      await Supabase.instance.client.auth.resetPasswordForEmail(
        cleanEmail,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
      return {'success': true, 'message': 'Password reset email sent successfully'};
    } catch (e) {
      print('Supabase reset password error: $e');
      
      // Handle specific Supabase AuthApiException
      if (e is AuthApiException) {
        print('Error code: ${e.code}');
        print('Error message: ${e.message}');
        print('Status code: ${e.statusCode}');
        
        // More specific error handling
        switch (e.code) {
          case 'email_address_invalid':
            return {'success': false, 'message': 'This email address is not registered or not confirmed. Please check your email or contact support.\n\nNote: If you recently registered, please check your email for a confirmation link first.'};
          case 'rate_limit_exceeded':
            return {'success': false, 'message': 'Too many requests. Please try again later.'};
          case 'email_not_confirmed':
            return {'success': false, 'message': 'Please confirm your email address before resetting password.'};
          case 'signup_disabled':
            return {'success': false, 'message': 'Account registration is currently disabled.'};
          case 'email_not_authorized':
            return {'success': false, 'message': 'This email address is not authorized to reset password.'};
          default:
            return {'success': false, 'message': 'Failed to send reset email: ${e.message ?? 'Unknown error'}. Please try again or contact support.'};
        }
      }
      
      // Fallback for other error types
      return {'success': false, 'message': 'Failed to send reset email. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    if (!_supabaseReady) {
      throw StateError('Supabase not initialized. Configure SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    
    try {
      // First verify the current password by attempting to sign in
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return {'success': false, 'message': 'No user is currently logged in.'};
      }

      // Verify current password
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: currentUser.email,
          password: currentPassword,
        );
      } catch (e) {
        if (e is AuthApiException && e.code == 'invalid_credentials') {
          return {'success': false, 'message': 'Current password is incorrect.'};
        }
        throw e;
      }

      // Update password
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return {'success': true, 'message': 'Password changed successfully'};
    } catch (e) {
      print('Supabase change password error: $e');
      
      if (e is AuthApiException) {
        switch (e.code) {
          case 'invalid_credentials':
            return {'success': false, 'message': 'Current password is incorrect.'};
          case 'weak_password':
            return {'success': false, 'message': 'New password is too weak. Please choose a stronger password.'};
          case 'same_password':
            return {'success': false, 'message': 'New password must be different from current password.'};
          default:
            return {'success': false, 'message': 'Failed to change password: ${e.message ?? 'Unknown error'}'};
        }
      }
      
      return {'success': false, 'message': 'Failed to change password. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String email) async {
    if (!_supabaseReady) {
      throw StateError('Supabase not initialized. Configure SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    
    // Simple email cleaning - just trim and lowercase
    String cleanEmail = email.trim().toLowerCase();
    
    print('Verifying email: "$cleanEmail"');
    
    // Validate email format
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return {'success': false, 'message': 'Please enter a valid email address.'};
    }
    
    try {
      // Try to sign in with a dummy password to check if email exists
      await Supabase.instance.client.auth.signInWithPassword(
        email: cleanEmail, 
        password: 'dummy_password_check'
      );
      
      // If we get here, the email exists but password is wrong (expected)
      return {'success': true, 'message': 'Email verified successfully'};
    } catch (e) {
      if (e is AuthApiException) {
        print('Email verification error code: ${e.code}');
        print('Email verification error message: ${e.message}');
        
        switch (e.code) {
          case 'invalid_credentials':
            // Email exists but password is wrong - this is what we want
            print('✅ Email exists - returning success');
            return {'success': true, 'message': 'Email verified successfully'};
          case 'email_address_invalid':
            print('❌ Email does not exist');
            return {'success': false, 'message': 'This email address is not registered with our system.'};
          case 'email_not_confirmed':
            print('⚠️ Email not confirmed');
            return {'success': false, 'message': 'Please confirm your email address first.'};
          default:
            print('❓ Other error: ${e.code}');
            return {'success': false, 'message': 'Email verification failed: ${e.message ?? 'Unknown error'}'};
        }
      }
      
      return {'success': false, 'message': 'Email verification failed. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> resetPasswordForEmail(String email, String currentPassword, String newPassword) async {
    if (!_supabaseReady) {
      throw StateError('Supabase not initialized. Configure SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    
    // Simple email cleaning - just trim and lowercase
    String cleanEmail = email.trim().toLowerCase();
    
    print('Resetting password for email: "$cleanEmail"');
    
    try {
      // First verify the current password by attempting to sign in
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: cleanEmail,
          password: currentPassword,
        );
      } catch (e) {
        if (e is AuthApiException && e.code == 'invalid_credentials') {
          return {'success': false, 'message': 'Current password is incorrect.'};
        }
        throw e;
      }

      // Update password
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return {'success': true, 'message': 'Password reset successfully'};
    } catch (e) {
      print('Supabase reset password error: $e');
      
      if (e is AuthApiException) {
        switch (e.code) {
          case 'invalid_credentials':
            return {'success': false, 'message': 'Current password is incorrect.'};
          case 'weak_password':
            return {'success': false, 'message': 'New password is too weak. Please choose a stronger password.'};
          case 'same_password':
            return {'success': false, 'message': 'New password must be different from current password.'};
          default:
            return {'success': false, 'message': 'Failed to reset password: ${e.message ?? 'Unknown error'}'};
        }
      }
      
      return {'success': false, 'message': 'Failed to reset password. Please try again.'};
    }
  }
}
