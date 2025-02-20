import 'dart:ui';
import 'package:flutter/material.dart';
import 'appbar/settings_popup.dart';
import '../pages/config_page.dart';
import '../pages/library_page.dart';
import '../pages/settings_page.dart';
import '../pages/settings_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String appName;
  final VoidCallback onSettingsPressed;

  const CustomAppBar({
    required this.appName,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: Colors.white.withOpacity(0.2),
            elevation: 0,
            title: Text(
              appName,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 20,
              ),
            ),
            leading: PopupMenuButton<int>(
              icon: Icon(Icons.menu),
              color: const Color.fromARGB(255, 56, 56, 56),
              itemBuilder: (context) => [
                PopupMenuItem<int>(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(Icons.library_books, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Library', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem<int>(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Chat History', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem<int>(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(Icons.description, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Docs', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem<int>(
                  value: 3,
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.white),
                      SizedBox(width: 8),
                      Text('About', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem<int>(
                  value: 4,
                  child: Row(
                    children: [
                      Icon(Icons.computer, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Configs', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
              onSelected: (item) => _selectedMenuItem(context, item),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.create_outlined),
                onPressed: () {
                  // Handle new chat
                  print('New Chat pressed');
                },
              ),
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectedMenuItem(BuildContext context, int item) {
    switch (item) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LibraryPage(),
          ),
        );
        break;
      case 1:
        print('Chat History selected');
        break;
      case 2:
        print('Docs selected');
        break;
      case 3:
        print('About selected');
        break;
      // In the _selectedMenuItem method, replace the case 4 block:
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfigPage(appName: appName),
                ),
              );
              break;
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}