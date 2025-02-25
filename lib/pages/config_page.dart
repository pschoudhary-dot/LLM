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
    _requestPermissions();
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
            'Local Storage': '81.0 GB of 107.9 GB (75%)',
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
      final directory = Directory('/storage/emulated/0/Android/data/com.termux');
      final termuxExists = await directory.exists();
      final appDirectory = Directory('/data/data/com.termux');
      final appExists = await appDirectory.exists();

      setState(() {
        isTermuxInstalled = termuxExists || appExists;
        isLoading = false;
      });
    } catch (e) {
      print("Error checking Termux: $e");
      setState(() {
        isTermuxInstalled = false;
        isLoading = false;
      });
    }
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
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final androidInfo = await deviceInfoPlugin.androidInfo;

      if (!mounted) return;

      setState(() {
        deviceInfo = {
          'Device Name': androidInfo.model,
          'Manufacturer': androidInfo.manufacturer,
          'Android Version': '${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})',
          'Security Patch': androidInfo.version.securityPatch ?? 'Unknown',
          'Build Number': androidInfo.id,
          'Brand': androidInfo.brand,
          'Board': androidInfo.board,
          'Processor': androidInfo.hardware,
        };
      });
    } catch (e) {
      print("Error loading device info: $e");
      if (!mounted) return;

      setState(() {
        deviceInfo = {
          'Error': 'Failed to load device information',
        };
      });
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 0.7) return Colors.green;
    if (percentage < 0.9) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('System Configuration'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _loadDeviceInfo();
              _loadStorageInfo();
              _checkTermux();
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeviceSection(),
                  _buildStorageSection(),
                  _buildMemorySection(),
                  _buildTermuxSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildDeviceSection() {
    return _buildSection(
      'Device Information',
      deviceInfo.entries.map((e) => _buildInfoRow(e.key, e.value)).toList(),
    );
  }

  Widget _buildStorageSection() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Storage Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(height: 1),
          _buildStorageItem(
            'Internal Storage',
            '81.0 GB of 107.9 GB (75%)',
            0.75,
          ),
          _buildStorageItem(
            'SD Card',
            '48.2 GB / 512 GB',
            0.09,
          ),
        ],
      ),
    );
  }

  Widget _buildStorageItem(String label, String value, double percentage) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: _getProgressColor(percentage).withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(percentage)),
              minHeight: 6,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorySection() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Memory Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildMemoryRow('Total RAM', '12 GB'),
                      SizedBox(height: 16),
                      _buildMemoryRow('Available RAM', '4.8 GB'),
                      SizedBox(height: 16),
                      _buildMemoryRow('Running Processes', '142'),
                    ],
                  ),
                ),
                SizedBox(width: 24),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CustomPaint(
                    painter: MemoryPainter(0.6, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermuxSection() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  color: Colors.purple[600],
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Termux',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: _launchTermuxDownload,
                  child: Text(
                    'Install Now',
                    style: TextStyle(
                      color: Colors.purple[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchTermuxDownload() async {
    final Uri url = Uri.parse('https://f-droid.org/en/packages/com.termux/');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}

class MemoryPainter extends CustomPainter {
  final double percentage;
  final Color color;

  MemoryPainter(this.percentage, {this.color = Colors.purple});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius - 4, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -1.5708,
      percentage * 2 * 3.14159,
      false,
      progressPaint,
    );

    // Add percentage text in center
    final textSpan = TextSpan(
      text: '${(percentage * 100).toInt()}%',
      style: TextStyle(
        color: Colors.grey[800],
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}