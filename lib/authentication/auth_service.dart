import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign up with email, password, and username
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'avatar_url': null,
        },
      );

      // Assign doctor role after successful signup
      if (response.user != null) {
        await _supabase.from('user_roles').insert({
          'user_id': response.user!.id,
          'role': 'doctor',
        });
      }

      return response;
    } on AuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign in with email and password - ONLY FOR doctor
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // If user signed in, validate role
      if (response.user != null) {
        final roleResponse = await _supabase
            .from('user_roles')
            .select('role')
            .eq('user_id', response.user!.id)
            .maybeSingle();

        String? userRole;
        if (roleResponse != null && roleResponse.containsKey('role')) {
          userRole = roleResponse['role'] as String?;
        }

        // If we couldn't find a role via the DB response, attempt a simpler query path:
        if (userRole == null) {
          try {
            final simple = await _supabase
                .from('user_roles')
                .select('role')
                .eq('user_id', response.user!.id)
                .single();
            if (simple.containsKey('role')) {
              userRole = simple['role'] as String?;
            }
          } catch (_) {
            // ignore and fallback to deny if no role found
          }
        }

        if (userRole != 'doctor') {
          await _supabase.auth.signOut();
          throw Exception('Access denied. Only doctors can login through this app.');
        }
      }

      return response;
    } on AuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get current user email
  String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }

  // Check if user is signed in
  bool isSignedIn() {
    return _supabase.auth.currentSession != null;
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  // Get current user metadata
  Map<String, dynamic>? getCurrentUserMetadata() {
    return _supabase.auth.currentUser?.userMetadata;
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      final user = _supabase.auth.currentUser;
      debugPrint('👤 DEBUG: getUserRole - Current user: ${user?.email} (ID: ${user?.id})');
      
      if (user == null) {
        debugPrint('❌ DEBUG: No authenticated user found');
        return null;
      }

      debugPrint('🔍 DEBUG: Querying user_roles table for user_id: ${user.id}');
      
      try {
        final resp = await _supabase
            .from('user_roles')
            .select('role')
            .eq('user_id', user.id)
            .maybeSingle();

        debugPrint('📋 DEBUG: user_roles query result: $resp');
        
        // Extract role defensively
        if (resp != null && resp.containsKey('role')) {
          final role = resp['role'] as String?;
          debugPrint('✅ DEBUG: User role found: $role');
          return role;
        } else {
          debugPrint('⚠️ DEBUG: No role found or invalid response format');
        }
      } catch (e) {
        debugPrint('❌ DEBUG: Error querying user_roles table: $e');
      }

      return null;
    } catch (e) {
      debugPrint('❌ DEBUG: Error in getUserRole: $e');
      return null;
    }
  }

  // Check if user has specific role
  Future<bool> hasRole(String role) async {
    final userRole = await getUserRole();
    return userRole == role;
  }

  // Check if current user is patient
  Future<bool> isPatient() async {
    return await hasRole('doctor');
  }

  // NEW: Fetch display name from auth user (priority: metadata.username/name/full_name -> email prefix)
  Future<String?> fetchDisplayName() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final metadata = user.userMetadata ?? <String, dynamic>{};

      debugPrint('Auth user id: ${user.id}');
      debugPrint('Auth user email: ${user.email}');
      debugPrint('Auth user metadata: $metadata');

      final keysToTry = ['username', 'name', 'full_name', 'fullName'];

      for (final k in keysToTry) {
        final v = metadata[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }

      // Use first string value in metadata if present
      for (final entry in metadata.entries) {
        final v = entry.value;
        if (v is String && v.trim().isNotEmpty) {
          debugPrint('Using metadata.${entry.key} as display name');
          return v.trim();
        }
      }

      // Fallback to email prefix
      final email = user.email;
      if (email != null && email.isNotEmpty) {
        return email.split('@').first;
      }

      return null;
    } catch (e, st) {
      debugPrint('fetchDisplayName error: $e\n$st');
      return null;
    }
  }
}