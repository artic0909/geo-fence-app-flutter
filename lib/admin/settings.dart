import 'package:flutter/material.dart';
import 'admin_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF121212);
    const Color cardDark = Color(0xFF1E1E1E);
    const Color goldMain = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.w800, color: goldMain, letterSpacing: 1.5, fontSize: 16)),
        backgroundColor: bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: goldMain),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_open, color: goldMain),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const AdminDrawer(currentRoute: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(25),
        children: [
          Text('PREFERENCES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 2)),
          const SizedBox(height: 15),
          _buildSettingsCard([
            _buildSettingsItem(Icons.person_outline, 'Profile Management', goldMain, cardDark),
            _buildDivider(),
            _buildSettingsItem(Icons.notifications_active_outlined, 'Alerts & Notifications', goldMain, cardDark),
            _buildDivider(),
            _buildSettingsItem(Icons.security_outlined, 'Security & Privacy', goldMain, cardDark),
          ], cardDark),
          
          const SizedBox(height: 35),
          Text('SYSTEM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 2)),
          const SizedBox(height: 15),
          _buildSettingsCard([
            _buildSettingsItem(Icons.language_outlined, 'Language', goldMain, cardDark),
            _buildDivider(),
            _buildSettingsItem(Icons.dark_mode_outlined, 'Theme (Dark Golden)', goldMain, cardDark),
            _buildDivider(),
            _buildSettingsItem(Icons.info_outline, 'About App', goldMain, cardDark),
          ], cardDark),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[850]!, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, Color goldMain, Color cardDark) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: goldMain.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: goldMain, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () {},
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey[850], indent: 60);
  }
}
