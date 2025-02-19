import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class TermuxService {
  static Future<void> runCommand(BuildContext context, String command) async {
    try {
      print('Attempting to run command: $command');
      
      // First try to launch Termux directly
      final termuxUri = Uri.parse('termux://');
      if (await canLaunchUrl(termuxUri)) {
        await launchUrl(
          termuxUri,
          mode: LaunchMode.externalApplication,
        );
        
        // Wait briefly for Termux to open
        await Future.delayed(const Duration(seconds: 1));
        
        // Then send the command
        final amCommand = 'am broadcast --user 0 '
            '-a com.termux.app.RUN_COMMAND '
            '--es com.termux.app.RUN_COMMAND_PATH "/data/data/com.termux/files/usr/bin/bash" '
            '--es com.termux.app.RUN_COMMAND_ARGUMENTS "-c \'$command\'"';

        final result = await Process.run('sh', ['-c', amCommand]);
        print('Process result: ${result.stdout}');
        print('Process error: ${result.stderr}');
        
        if (result.exitCode == 0) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Command sent to Termux: $command'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Failed to send command to Termux');
        }
      } else {
        throw Exception('Cannot launch Termux');
      }
    } catch (e, stackTrace) {
      print('Error in runCommand: $e');
      print('Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to execute command: $command\nError: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}