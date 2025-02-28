import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'dart:math' as math;

class UserSurveyPage extends StatefulWidget {
  final String userId;
  final VoidCallback onComplete;

  const UserSurveyPage({
    super.key,
    required this.userId,
    required this.onComplete,
  });

  @override
  State<UserSurveyPage> createState() => _UserSurveyPageState();
}

class _UserSurveyPageState extends State<UserSurveyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedProfession;
  String? _selectedSource;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isComplete = false;
  String? _errorMessage;
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  late String _selectedAvatar;

  final List<String> _professions = [
    'Student',
    'Developer',
    'Designer',
    'Product Manager',
    'Data Scientist',
    'Researcher',
    'Educator',
    'Other'
  ];

  final List<String> _sources = [
    'Search Engine',
    'Social Media',
    'Friend/Colleague',
    'Advertisement',
    'App Store',
    'Other'
  ];

  final List<String> _avatarOptions = [
    'assets/avatar1.jpg',
    'assets/avatar2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    // Randomly select an avatar
    final random = math.Random();
    _selectedAvatar = _avatarOptions[random.nextInt(_avatarOptions.length)];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfileAndComplete() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isSubmitting = true;
        });
        
        // Update the user profile with the survey answers
        await _authService.updateUserProfile(
          userId: widget.userId,
          fullName: _nameController.text,
          username: _usernameController.text,
          bio: _bioController.text,
          profession: _selectedProfession,
          heardFrom: _selectedSource,
          avatarUrl: _selectedAvatar,
          surveyCompleted: true,
        );
        
        setState(() {
          _isSubmitting = false;
          _isComplete = true;
        });
        
        // Call the onComplete callback
        widget.onComplete();
        
        // Navigate to the home page
        if (mounted) {
          // Clear any existing routes and go directly to home
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } catch (e) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Error saving profile: ${e.toString()}';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage ?? ''),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.grey[50],
          elevation: 0,
          automaticallyImplyLeading: false, // Remove back button
          title: const Text(
            'Complete Profile',
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Tell us about yourself',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(_selectedAvatar),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100] ?? Colors.grey.shade100,
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100] ?? Colors.grey.shade100,
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100] ?? Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100] ?? Colors.grey.shade100,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Select date'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedProfession,
                decoration: InputDecoration(
                  labelText: 'Profession',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100] ?? Colors.grey.shade100,
                ),
                items: _professions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedProfession = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSource,
                decoration: InputDecoration(
                  labelText: 'How did you hear about us?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100] ?? Colors.grey.shade100,
                ),
                items: _sources.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedSource = newValue;
                  });
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _saveProfileAndComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text(
                        'Complete Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}