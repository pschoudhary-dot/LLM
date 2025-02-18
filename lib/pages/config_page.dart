import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui'; // Add this import for ImageFilter
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:disk_space/disk_space.dart';
import 'package:system_info2/system_info2.dart';
import 'package:path_provider/path_provider.dart';

class ConfigPage extends StatefulWidget {
  final String appName;

  const ConfigPage({Key? key, required this.appName}) : super(key: key);

  @override
  _ConfigPageState createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  Map<String, String> deviceInfo = {};
  Map<String, String> storageInfo = {};
  bool isTermuxInstalled = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissions();  // Call this first
    _loadDeviceInfo();
    _loadStorageInfo();
    _checkTermux();
  }

  Future<void> _loadStorageInfo() async {
    try {
      // Get RAM information
      final totalRam = SysInfo.getTotalPhysicalMemory();
      final freeRam = SysInfo.getFreePhysicalMemory();
      
      // Get storage information
      final directory = await getExternalStorageDirectory();
      final stat = await directory?.parent.parent.parent.parent.statSync();
      final totalBytes = stat?.size ?? 0;
      final freeBytes = FileStat.statSync(directory?.parent.parent.parent.parent.path ?? '').size ?? 0;

      setState(() {
        storageInfo = {
          'Total RAM': '${(totalRam / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
          'Free RAM': '${(freeRam / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
          'Total Storage': '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
          'Available Storage': '${(freeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
        };
      });
    } catch (e) {
      print("Error loading storage info: $e");
      setState(() {
        storageInfo = {
          'Error': 'Failed to load storage information',
        };
      });
    }
  }

  Widget _buildInfoCard(String title, List<MapEntry<String, String>> items, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            ...items.map((item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 3,
                    child: Text(
                      item.key,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('System Configuration'),
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    'Device Information',
                    deviceInfo.entries.toList(),
                    Icons.phone_android,
                  ),
                  SizedBox(height: 16),
                  _buildInfoCard(
                    'Storage Information',
                    storageInfo.entries.toList(),
                    Icons.storage,
                  ),
                  SizedBox(height: 16),
                  _buildTermuxCard(),
                ],
              ),
            ),
    );
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.storage,
    ].request();

    if (statuses[Permission.phone]!.isGranted) {
      _loadDeviceInfo();
    } else {
      setState(() {
        deviceInfo = {
          'Error': 'Permissions required to show device information',
        };
        isLoading = false;
      });
    }
    _checkTermux();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      print("Getting Android Info...");
      final androidInfo = await deviceInfoPlugin.androidInfo;
      print("Android Info received: ${androidInfo.model}");

      if (!mounted) return;  // Check if widget is still mounted

      setState(() {
        deviceInfo = {
          'Device Name': androidInfo.model,
          'Manufacturer': androidInfo.manufacturer,
          'Android Version': '${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})',
          'Security Patch': androidInfo.version.securityPatch ?? 'Unknown',
          'Build Number': androidInfo.id,
          'Brand': androidInfo.brand,
          'Board': androidInfo.board,
          'Hardware': androidInfo.hardware,
        };
        isLoading = false;
      });
    } catch (e) {
      print("Error loading device info: $e");
      if (!mounted) return;

      setState(() {
        deviceInfo = {
          'Error': 'Failed to load device information. Please grant permissions and try again.',
        };
        isLoading = false;
      });
    }
  }

  Future<void> _checkTermux() async {
    bool termuxExists = await File('/data/data/com.termux/files/usr/bin/bash').exists();
    setState(() {
      isTermuxInstalled = termuxExists;
    });
  }

  Future<void> _launchTermuxDownload() async {
    final Uri url = Uri.parse('https://f-droid.org/en/packages/com.termux/');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
  Widget _buildTermuxCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isTermuxInstalled 
            ? () {
                // Will be used for Termux configuration later
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Termux is installed and ready to use')),
                );
              }
            : _launchTermuxDownload,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.terminal, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Termux',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      isTermuxInstalled 
                          ? 'Installed and ready to use'
                          : 'Click to download Termux',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isTermuxInstalled)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 4),
                      Text('Installed', 
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _launchTermuxDownload,
                  icon: Icon(Icons.download),
                  label: Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
