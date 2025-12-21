// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSettingTile(
            Icons.language,
            'Language',
            'Bahasa Indonesia',
            () {},
          ),
          _buildSettingTile(
            Icons.dark_mode,
            'Theme',
            'Dark Mode',
            () {},
          ),
          _buildSettingTile(
            Icons.notifications,
            'Notifications',
            'Enabled',
            () {},
          ),
          _buildSettingTile(
            Icons.backup,
            'Backup Data',
            'Last backup: Today',
            () {},
          ),
          _buildSettingTile(
            Icons.info,
            'About',
            'Version 1.0.0',
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFD4AF37)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
      onTap: onTap,
    );
  }
}