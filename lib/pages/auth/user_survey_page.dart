import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

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
  DateTime? _selectedDate;
  String? _selectedProfession;
  String? _selectedSource;

  final List<String> _professions = [
    'Student',
    'Developer',
    'Designer',
    'Business',
    'Other'
  ];

  final List<String> _sources = [
    'Search Engine',
    'Social Media',
    'Friend',
    'Advertisement',
    'Other'
  ];

  Future<void> _submitSurvey() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      try {
        await AuthService().saveUserProfile(
          userId: widget.userId,
          data: {
            'full_name': _nameController.text,
            'username': _usernameController.text,
            'date_of_birth': _selectedDate!.toIso8601String(),
            'profession': _selectedProfession,
            'heard_from': _selectedSource,
          },
        );
        if (!mounted) return;
        widget.onComplete();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter your name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a username' : null,
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Select Date of Birth'
                    : 'DoB: ${_selectedDate!.toString().split(' ')[0]}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedProfession,
                decoration: InputDecoration(labelText: 'Profession'),
                items: _professions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedProfession = value),
                validator: (value) =>
                    value == null ? 'Please select your profession' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSource,
                decoration: InputDecoration(labelText: 'How did you hear about us?'),
                items: _sources
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedSource = value),
                validator: (value) =>
                    value == null ? 'Please select an option' : null,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitSurvey,
                child: Text('Complete Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}