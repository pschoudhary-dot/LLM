import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:llm/pages/auth/user_survey_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_page.dart';
import '../../services/auth_service.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  bool _isLoggedIn = false;
  String? _profileImage;
  String? _username;
  String? _email;
  DateTime? _signupDate;
  String? _profession;
  String? _fullName;
  DateTime? _dateOfBirth;
  String? _heardFrom;
  final ImagePicker _picker = ImagePicker();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final userId = session.user.id;
      try {
        final userData = await Supabase.instance.client
            .from('user_profiles')
            .select()
            .eq('user_id', userId)
            .single();

        setState(() {
          _isLoggedIn = true;
          _email = session.user.email;
          _username = userData['username'];
          _profileImage = userData['profile_image'];
          _profession = userData['profession'];
          _signupDate = DateTime.parse(userData['created_at']);
          // Add other survey data
          _fullName = userData['full_name'];
          _dateOfBirth = userData['date_of_birth'] != null 
              ? DateTime.parse(userData['date_of_birth']) 
              : null;
          _heardFrom = userData['heard_from'];
        });
      } catch (e) {
        print('Error loading user data: $e');
      }
    } else {
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final bytes = await image.readAsBytes();
          final fileName = 'profile_$userId.jpg';
          
          // Upload to Supabase Storage
          await Supabase.instance.client.storage
              .from('profile_images')
              .uploadBinary(fileName, bytes);

          final imageUrl = Supabase.instance.client.storage
              .from('profile_images')
              .getPublicUrl(fileName);

          // Update profile in database
          await Supabase.instance.client
              .from('user_profiles')
              .update({'profile_image': imageUrl})
              .eq('user_id', userId);

          setState(() {
            _profileImage = imageUrl;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      setState(() {
        _isLoggedIn = false;
        _email = null;
        _username = null;
        _profileImage = null;
        _profession = null;
        _signupDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Widget _buildLoggedInView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 3,
                  ),
                  image: _profileImage != null
                      ? DecorationImage(
                          image: FileImage(File(_profileImage!)),
                          fit: BoxFit.cover,
                        )
                      : const DecorationImage(
                          image: AssetImage('assets/avatar1.jpg'),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              FloatingActionButton.small(
                onPressed: _pickImage,
                child: const Icon(Icons.edit),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _username ?? 'Username',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _email ?? 'email@example.com',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Member since ${_signupDate?.toString().split(' ')[0] ?? 'Unknown'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          _buildProfileSection(
            'Account Settings',
            [
              _buildSettingsTile(
                'Edit Profile',
                Icons.edit,
                () {},
              ),
              _buildSettingsTile(
                'Change Password',
                Icons.lock_outline,
                () {},
              ),
              _buildSettingsTile(
                'Privacy Settings',
                Icons.privacy_tip_outlined,
                () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProfileSection(
            'Preferences',
            [
              _buildSettingsTile(
                'Notifications',
                Icons.notifications_outlined,
                () {},
              ),
              _buildSettingsTile(
                'Language',
                Icons.language,
                () {},
              ),
              _buildSettingsTile(
                'Theme',
                Icons.palette_outlined,
                () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              setState(() {
                _isLoggedIn = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
        ),
      ),
      body: _isLoggedIn 
          ? _buildLoggedInView() 
          : AuthPage(
              onLoginSuccess: (email) async {
                // Check if user profile exists
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId != null) {
                  try {
                    final userProfile = await Supabase.instance.client
                        .from('user_profiles')
                        .select()
                        .eq('user_id', userId)
                        .single();
                    
                    if (userProfile == null) {
                      // Show survey if profile doesn't exist
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserSurveyPage(
                            userId: userId,
                            onComplete: () {
                              _loadUserData();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    } else {
                      await _loadUserData();
                    }
                  } catch (e) {
                    // If no profile exists, show survey
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserSurveyPage(
                          userId: userId,
                          onComplete: () {
                            _loadUserData();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  }
                }
              },
            ),
    );
  }
}