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
      // Try to sign up with a dummy password to check if the email exists
      final response = await _supabase.auth.signUp(
        email: email,
        password: 'check_only_password',
      );
      
      // If identities array is empty, the email already exists
      if (response.user != null && response.user!.identities != null && response.user!.identities!.isEmpty) {
        return true; // Email exists
      } else {
        return false; // Email doesn't exist
      }
    } catch (e) {
      // If we get an error about email already in use, it exists
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('email already in use') || 
          errorMessage.contains('user already registered')) {
        return true;
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
      // First check if the user already exists by trying to sign in
      try {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: 'dummy_check_password',
        );
        // If we get here, it means authentication failed but the user exists
        throw AuthException('Email is already in use.');
      } catch (e) {
        // If the error is not about the user existing, continue with signup
        if (!e.toString().contains('Invalid login credentials')) {
          // Re-throw if it's not an invalid credentials error
          if (e is AuthException && e.message == 'Email is already in use.') {
            rethrow;
          }
        }
      }
      
      // Proceed with signup
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      
      // If user is null or identities is empty, throw error
      if (response.user == null) {
        throw AuthException('Signup failed: User is null');
      }
      
      // Create a profile for the user
      if (response.user != null) {
        try {
          await _supabase.from('profiles').insert({
            'id': response.user!.id,
            'email': email,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          print('Error creating profile: $e');
          // Continue even if profile creation fails, we'll handle it later
        }
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