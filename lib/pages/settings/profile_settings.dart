import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth/auth_page.dart';
import 'dart:io';

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
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _profileImage = prefs.getString('profileImage');
      _username = prefs.getString('username');
      _email = prefs.getString('email');
      final signupTimestamp = prefs.getInt('signupDate');
      _signupDate = signupTimestamp != null 
          ? DateTime.fromMillisecondsSinceEpoch(signupTimestamp) 
          : null;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = image.path;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImage', image.path);
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
        title: Row(
          children: [
            // SvgPicture.asset(
            //   'assets/SizeSmall.svg',
            //   height: 24,
            //   width: 24,
            // ),
            const SizedBox(width: 8),
            const Text('Profile'),
          ],
        ),
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
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', true);
                await prefs.setString('username', email.split('@')[0]);
                await prefs.setString('email', email);
                await prefs.setInt('signupDate', DateTime.now().millisecondsSinceEpoch);
                setState(() {
                  _isLoggedIn = true;
                });
              },
            ),
    );
  }
}