import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'today_present.dart';
import 'today_absent.dart';
import 'settings.dart';
import '../screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDrawer extends StatelessWidget {
  final String currentRoute;

  const AdminDrawer({super.key, required this.currentRoute});

  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2E3192);

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, Color(0xFF1BFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, size: 40, color: primaryColor),
                ),
                SizedBox(height: 15),
                Text(
                  'Admin Menu',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  title: 'Dashboard',
                  icon: Icons.dashboard,
                  routeName: 'Dashboard',
                  onTap: () {
                    if (currentRoute != 'Dashboard') {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
                    } else {
                      Navigator.pop(context); // Close drawer
                    }
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  title: 'Today Present',
                  icon: Icons.how_to_reg,
                  routeName: 'TodayPresent',
                  onTap: () {
                    if (currentRoute != 'TodayPresent') {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TodayPresentScreen()));
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  title: 'Today Absent',
                  icon: Icons.person_off,
                  routeName: 'TodayAbsent',
                  onTap: () {
                    if (currentRoute != 'TodayAbsent') {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TodayAbsentScreen()));
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  context: context,
                  title: 'Settings',
                  icon: Icons.settings,
                  routeName: 'Settings',
                  onTap: () {
                    if (currentRoute != 'Settings') {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String routeName,
    required VoidCallback onTap,
  }) {
    final bool isSelected = currentRoute == routeName;
    const Color primaryColor = Color(0xFF2E3192);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? primaryColor : Colors.grey[700]),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? primaryColor : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
