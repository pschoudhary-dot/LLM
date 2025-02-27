import 'package:flutter/material.dart';
import 'dart:ui';
import 'settings/profile_settings.dart';
import '../component/model_config_dialog.dart';
import 'model_settings_page.dart';
import 'api_keys_page.dart';
import '../services/model_service.dart';
import 'search_settings_page.dart';

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
            showActionButtons: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ModelSettingsPage()),
              ).then((_) {
                // Refresh the state when returning from the model settings page
                setState(() {});
              });
            },
            onAddPressed: () {
              showDialog(
                context: context,
                builder: (context) => ModelConfigDialog(
                  onSave: (config) async {
                    await ModelService.saveModelConfig(config);
                    // If this is the first model, set it as selected
                    final configs = await ModelService.getModelConfigs();
                    if (configs.length == 1) {
                      await ModelService.setSelectedModel(config.id);
                    }
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Model configuration saved')),
                    );
                  },
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.search,
            iconColor: Colors.green,
            title: 'Search Configuration',
            subtitle: 'Customize search behavior and sources',
            showActionButtons: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchConfigPage()),
              );
            },
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ApiKeysPage()),
              );
            },
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
    bool showActionButtons = false,
    VoidCallback? onTap,
    VoidCallback? onAddPressed,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (showActionButtons)
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: Color(0xFF8B5CF6)),
                      onPressed: onAddPressed,
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                )
              else
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}