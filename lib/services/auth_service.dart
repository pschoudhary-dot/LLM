import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late final SupabaseClient _supabase;
  final _storage = const FlutterSecureStorage();

  Future<void> initialize() async {
    await Supabase.initialize(
      url: await _getSupabaseUrl(),
      anonKey: await _getSupabaseAnonKey(),
    );
    _supabase = Supabase.instance.client;
  }

  Future<String> _getSupabaseUrl() async {
    return await _storage.read(key: 'supabase_url') ?? 
           'https://hefbwdfqslvybebwyebd.supabase.co';
  }

  Future<String> _getSupabaseAnonKey() async {
    return await _storage.read(key: 'supabase_anon_key') ?? 
           'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhlZmJ3ZGZxc2x2eWJlYnd5ZWJkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkzNjI3MTIsImV4cCI6MjA1NDkzODcxMn0.P8Es06ng0TEL6PeW5QEdNkUW7g1ED-YcDNdVrU0vCXE';
  }
  Future<bool> checkEmailExists(String email) async {
    try {
      final List<dynamic> response = await _supabase
          .from('auth.users')
          .select('email')
          .eq('email', email);
      return response.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        // Create initial profile
        await _supabase.from('user_profiles').insert({
          'user_id': response.user!.id,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> saveUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _supabase
          .from('user_profiles')
          .upsert([
            {
              'user_id': userId,
              ...data,
              'updated_at': DateTime.now().toIso8601String(),
            }
          ]);
    } catch (e) {
      throw 'Failed to save user profile: $e';
    }
  }
}