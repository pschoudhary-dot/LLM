import 'package:flutter/material.dart';
import '../pages/library_page.dart';
import '../pages/config_page.dart';

class Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(top: 50, bottom: 20),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      'PocketLLM',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B4EFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.collections_bookmark),  // Changed from library_books
              title: Text('Library'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LibraryPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.chat_bubble_outline),  // Changed from history
              title: Text('Chat History'),
              onTap: () {
                print('Chat History selected');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline),  // Changed from description
              title: Text('Docs'),
              onTap: () {
                print('Docs selected');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline),  // Changed from info
              title: Text('About'),
              onTap: () {
                print('About selected');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.computer),  // Changed from settings to system_info
              title: Text('Config'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfigPage(appName: 'PocketLLM'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

