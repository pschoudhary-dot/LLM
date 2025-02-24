import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:system_info2/system_info2.dart';
import 'package:llm/services/termux_service.dart';

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
      final totalRam = SysInfo.getTotalPhysicalMemory();
      final freeRam = SysInfo.getFreePhysicalMemory();
      final usedRam = totalRam - freeRam;
      final ramPercentage = ((usedRam / totalRam) * 100).toStringAsFixed(0);
      
      final directory = Directory('/storage/emulated/0');
      final stat = await directory.statSync();
      final df = await Process.run('df', [directory.path]);
      final lines = df.stdout.toString().split('\n');
      if (lines.length > 1) {
        final values = lines[1].split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
        final totalBytes = int.parse(values[1]) * 1024;
        final freeBytes = int.parse(values[3]) * 1024;
        final usedBytes = totalBytes - freeBytes;
        final storagePercentage = ((usedBytes / totalBytes) * 100).toStringAsFixed(0);

        setState(() {
          storageInfo = {
            'System Memory': '${(usedRam / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB of ${(totalRam / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB ($ramPercentage%)',
            'Local Storage': '${(usedBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB of ${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB ($storagePercentage%)',
          };
        });
      }
    } catch (e) {
      print("Error loading storage info: $e");
      setState(() {
        storageInfo = {
          'Error': 'Failed to load storage information',
        };
      });
    }
  }

  Future<void> _checkTermux() async {
    try {
      // Check for Termux in Android/data directory
      final directory = Directory('/storage/emulated/0/Android/data/com.termux');
      final termuxExists = await directory.exists();
      
      // Additional check for the app directory
      final appDirectory = Directory('/data/data/com.termux');
      final appExists = await appDirectory.exists();

      setState(() {
        isTermuxInstalled = termuxExists || appExists;
      });
      
      print("Termux detection: Directory exists: $termuxExists, App exists: $appExists");
    } catch (e) {
      print("Error checking Termux: $e");
      setState(() {
        isTermuxInstalled = false;
      });
    }
  }
  Widget _buildInfoCard(String title, List<MapEntry<String, String>> items, IconData icon) {
    return Card(
      elevation: 8,
      margin: EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
            Divider(height: 24, thickness: 1, color: Colors.grey[300]),
            ...items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.key, 
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)
                  ),
                  SizedBox(height: 4),
                  if (item.key.contains('Storage') || item.key.contains('Memory'))
                    _buildProgressBar(item.value)
                  else
                    Text(item.value, 
                      style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w400)
                    ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressBar(String value) {
    final percentage = int.tryParse(value.split('(').last.split('%').first) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value.split(' (')[0],
              style: TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w400)
            ),
            Text(
              '${percentage}%',
              style: TextStyle(
                fontSize: 14,
                color: percentage > 90 ? Colors.red : 
                       percentage > 70 ? Colors.orange : 
                       Colors.grey[600],
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[100],
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage > 90 ? Colors.red.withOpacity(0.8) : 
            percentage > 70 ? Colors.orange.withOpacity(0.8) : 
            Theme.of(context).primaryColor.withOpacity(0.8),
          ),
          minHeight: 8,
        ),
      ],
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
  Future<void> _launchTermuxDownload() async {
    final Uri url = Uri.parse('https://f-droid.org/en/packages/com.termux/');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
  // Update Termux card text sizes
  Widget _buildTermuxCard() {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            InkWell(
              onTap: isTermuxInstalled 
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Termux is installed and ready to use'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                : null,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.terminal, 
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Termux',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Quick Guide:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            isTermuxInstalled 
                                ? 'Terminal emulator for Android'
                                : 'Required for command-line operations',
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
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withOpacity(0.5)),
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
                        icon: Icon(Icons.download_rounded, color: Colors.white),
                        label: Text('Install'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (isTermuxInstalled)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Guide:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildGuideItem('pkg update', 'Update package lists'),
                    _buildGuideItem('pkg upgrade', 'Upgrade installed packages'),
                    _buildGuideItem('termux-setup-storage', 'Setup storage access'),
                    _buildGuideItem('pkg install python', 'Install Python'),
                  ],
                ),
              ),
          ],
        ),
      );
    }
  }
  Widget _buildGuideItem(String command, String description) {
    return Builder(
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  command,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.play_circle_fill),
              color: Theme.of(context).primaryColor,
              tooltip: 'Run in Termux',
              onPressed: () => TermuxService.runCommand(context, command),
            ),
          ],
        ),
      ),
    );
  }