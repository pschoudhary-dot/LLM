import 'package:flutter/material.dart';
import 'dart:ui';
import 'settings/profile_settings.dart';
import '../component/model_input_dialog.dart';
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Account'),
          _buildSettingsItem(
            icon: Icons.person_outline,
            iconColor: Colors.blue,
            title: 'Profile Settings',
            subtitle: 'Manage your account and preferences',
          ),
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            title: 'Notifications',
            subtitle: 'Configure app notifications',
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('AI Configuration'),
          _buildSettingsItem(
            icon: Icons.psychology,
            iconColor: Colors.purple,
            title: 'Model Settings',
            subtitle: 'Configure AI models and parameters',
            showActionButtons: true,  // Add this line
          ),
          _buildSettingsItem(
            icon: Icons.search,
            iconColor: Colors.green,
            title: 'Search Configuration',
            subtitle: 'Customize search behavior and sources',
            showActionButtons: true,  // Add this line
          ),
          _buildSettingsItem(
            icon: Icons.search,
            iconColor: Colors.green,
            title: 'Search Configuration',
            subtitle: 'Customize search behavior and sources',
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('Database'),
          _buildSettingsItem(
            icon: Icons.schema,
            iconColor: Colors.indigo,
            title: 'Vector Databases',
            subtitle: 'Manage embeddings and vector storage',
          ),
          _buildSettingsItem(
            icon: Icons.share,
            iconColor: Colors.blue,
            title: 'Graph Databases',
            subtitle: 'Configure knowledge graph settings',
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('Security'),
          _buildSettingsItem(
            icon: Icons.security,
            iconColor: Colors.green,
            title: 'Privacy',
            subtitle: 'Manage data and privacy settings',
          ),
          _buildSettingsItem(
            icon: Icons.key,
            iconColor: Colors.orange,
            title: 'API Keys',
            subtitle: 'Manage API keys and authentication',
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('Advanced'),
          _buildSettingsItem(
            icon: Icons.memory,
            iconColor: Colors.deepPurple,
            title: 'Memory Management',
            subtitle: 'Configure context and history settings',
          ),
          _buildSettingsItem(
            icon: Icons.terminal,
            iconColor: Colors.grey[800]!,
            title: 'Developer Options',
            subtitle: 'Advanced configuration and debugging',
          ),
          _buildSettingsItem(
            icon: Icons.backup,
            iconColor: Colors.teal,
            title: 'Backup & Sync',
            subtitle: 'Manage data backup and synchronization',
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('About'),
          _buildSettingsItem(
            icon: Icons.info_outline,
            iconColor: Colors.blue,
            title: 'App Information',
            subtitle: 'Version, licenses, and documentation',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool showActionButtons = false,  // Add this parameter
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: showActionButtons ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.add, color: Color(0xFF8B5CF6)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => PermissionDialog(
                    title: 'Configure $title',
                    description: 'Add new configuration for $title',
                    onContinue: () {
                      Navigator.of(context).pop();
                      // Handle configuration
                    },
                    onCancel: () {
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.expand_more, color: Colors.grey[600]),
              onPressed: () {
                // Handle expand
              },
            ),
          ],
        ) : null,
        onTap: () {
          // Handle item tap
        },
      ),
    );
  }
}