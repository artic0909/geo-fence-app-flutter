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
    const Color bgDark = Color(0xFF121212);
    const Color cardDark = Color(0xFF1E1E1E);
    const Color goldMain = Color(0xFFD4AF37);
    const Color goldLight = Color(0xFFF9F1CC);

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: cardDark,
      ),
      child: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              decoration: const BoxDecoration(
                color: bgDark,
                border: Border(bottom: BorderSide(color: Color(0xFF333333), width: 1)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: goldMain, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/playstore.png',
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.admin_panel_settings, size: 40, color: goldMain);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'GEOFENCE',
                    style: TextStyle(color: goldLight, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3),
                  ),
                  const Text(
                    'SMART ATTENDANCE',
                    style: TextStyle(color: goldMain, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: cardDark,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    _buildDrawerItem(
                      context: context,
                      title: 'DASHBOARD',
                      icon: Icons.dashboard_outlined,
                      routeName: 'Dashboard',
                      onTap: () {
                        if (currentRoute != 'Dashboard') {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: 'TODAY PRESENT',
                      icon: Icons.how_to_reg_outlined,
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
                      title: 'TODAY ABSENT',
                      icon: Icons.person_off_outlined,
                      routeName: 'TodayAbsent',
                      onTap: () {
                        if (currentRoute != 'TodayAbsent') {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TodayAbsentScreen()));
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Divider(color: Colors.grey[800]),
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: 'SETTINGS',
                      icon: Icons.settings_outlined,
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
            ),
            Material(
              color: bgDark,
              child: Column(
                children: [
                  Divider(height: 1, color: Colors.grey[900]),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                    leading: const Icon(Icons.power_settings_new, color: Colors.redAccent),
                    title: const Text('SECURE LOGOUT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13)),
                    onTap: () => _logout(context),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
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
    const Color goldMain = Color(0xFFD4AF37);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected ? BorderSide(color: goldMain.withValues(alpha: 0.5), width: 1) : BorderSide.none,
        ),
        tileColor: isSelected ? goldMain.withValues(alpha: 0.15) : Colors.transparent,
        leading: Icon(icon, color: isSelected ? goldMain : Colors.grey[500], size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? goldMain : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            letterSpacing: 1.2,
            fontSize: 13,
          ),
        ),
        trailing: isSelected ? const Icon(Icons.chevron_right, color: goldMain, size: 20) : null,
        onTap: onTap,
      ),
    );
  }
}
