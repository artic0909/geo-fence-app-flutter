import 'package:flutter/material.dart';
import 'admin_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2E3192);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      endDrawer: const AdminDrawer(currentRoute: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('General Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
