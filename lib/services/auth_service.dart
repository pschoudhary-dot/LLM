import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;
  final _secureStorage = const FlutterSecureStorage();

  // Get the current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if a user is logged in
  bool get isLoggedIn => currentUser != null;

  // Check if an email exists in the system
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: 'dummy_password_for_check',
      );
      // If we get here without an error, the email exists
      return true;
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('invalid login credentials')) {
        // Invalid credentials means the email exists but password was wrong
        return true;
      }
      if (errorMessage.contains('email not confirmed') || 
          errorMessage.contains('user not found')) {
        // Email doesn't exist
        return false;
      }
      // For any other error, assume the email doesn't exist
      return false;
    }
  }

  // Sign up a new user
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      // First check if the email exists
      final exists = await checkEmailExists(email);
      if (exists) {
        throw AuthException('Email is already in use.');
      }
      
      // Proceed with signup
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      
      // If user is null, throw error
      if (response.user == null) {
        throw AuthException('Signup failed: User is null');
      }
      
      // Create a profile for the user
      try {
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'updated_at': DateTime.now().toIso8601String(),
          'survey_completed': false,
        }).execute();
      } catch (e) {
        print('Error creating profile: $e');
        // Continue even if profile creation fails, we'll handle it later
      }
      
      // Store the session in secure storage
      await _storeSession(response.session);
      
      return response;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  // Sign in an existing user
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Store the session in secure storage
      await _storeSession(response.session);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _clearSession();
  }

  // Store the session in secure storage
  Future<void> _storeSession(Session? session) async {
    if (session != null) {
      await _secureStorage.write(
        key: 'access_token',
        value: session.accessToken,
      );
      await _secureStorage.write(
        key: 'refresh_token',
        value: session.refreshToken,
      );
    }
  }

  // Clear the session from secure storage
  Future<void> _clearSession() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  // Restore the session from secure storage
  Future<void> restoreSession() async {
    final refreshToken = await _secureStorage.read(key: 'refresh_token');

    if (refreshToken != null) {
      try {
        await _supabase.auth.setSession(refreshToken);
      } catch (e) {
        // If session restoration fails, clear the stored tokens
        await _clearSession();
      }
    }
  }

  // Reset password for a user
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Get user profile data from the database
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser == null) {
        return null;
      }
      
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();
      
      return data;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? username,
    String? bio,
    DateTime? dateOfBirth,
    String? profession,
    String? heardFrom,
    String? avatarUrl,
    bool? surveyCompleted,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      
      if (fullName != null) updateData['full_name'] = fullName;
      if (username != null) updateData['username'] = username;
      if (bio != null) updateData['bio'] = bio;
      if (dateOfBirth != null) updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      if (profession != null) updateData['profession'] = profession;
      if (heardFrom != null) updateData['heard_from'] = heardFrom;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (surveyCompleted != null) updateData['survey_completed'] = surveyCompleted;
      
      // Always update the timestamp
      updateData['updated_at'] = DateTime.now().toIso8601String();
      
      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId)
          .execute();
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
}