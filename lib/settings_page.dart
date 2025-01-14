import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final Function(bool) toggleTheme;

  const SettingsPage({super.key, required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme Mode'),
            trailing: Switch(
              value: !isDarkMode,
              onChanged: toggleTheme,
            ),
            subtitle: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
          ),
        ],
      ),
    );
  }
} 