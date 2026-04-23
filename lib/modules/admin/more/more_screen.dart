import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/app_theme.dart';
import './user_screen.dart';
import './shop_screen.dart';
import './add_user_screen.dart';
import './reports/reports_screen.dart';
import './orders/order_history_screen.dart';
import './logs/logs_screen.dart';
import './app_settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            /// 🔥 TOP PROFILE SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppTheme.accentGrad,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.surface,
                    child: Icon(Icons.person, size: 30, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? user?.email ?? 'User',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.bg,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Welcome back 👋',
                          style: TextStyle(color: AppTheme.bg),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 MAIN CONTENT
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  /// 🔹 MANAGEMENT SECTION
                  _sectionTitle('Management'),
                  _tile(
                    icon: Icons.people,
                    title: 'Manage Users',
                    color: AppTheme.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UsersScreen()),
                    ),
                  ),
                  _tile(
                    icon: Icons.person_add,
                    title: 'Add User',
                    color: AppTheme.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddUserScreen()),
                    ),
                  ),
                  _tile(
                    icon: Icons.store,
                    title: 'Shops',
                    color: AppTheme.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShopsScreen()),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// 🔹 ANALYTICS SECTION
                  _sectionTitle('Analytics'),
                  _tile(
                    icon: Icons.bar_chart,           // ✅ Fixed: Reports icon
                    title: 'Reports',
                    color: AppTheme.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    ),
                  ),
                  _tile(
                    icon: Icons.history,             // ✅ Fixed: distinct icon for Order History
                    title: 'Order History',
                    color: AppTheme.blue,            // ✅ Fixed: distinct color
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                    ),
                  ),

                  _tile(
                    icon: Icons.terminal,
                    title: 'Admin Logs',
                    color: Colors.redAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LogsScreen()),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// 🔹 SETTINGS SECTION
                  _sectionTitle('Settings'),
                  _tile(
                    icon: Icons.settings,
                    title: 'App Settings',
                    color: AppTheme.textSecondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AppSettingsScreen()),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔴 LOGOUT BUTTON
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.red,
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    onPressed: () => _logout(context),
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

  /// 🔐 LOGOUT FUNCTION
  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Logout', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: AppTheme.surface2,
          ),
        );
      }
    }
  }

  /// 🔹 SECTION TITLE
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  /// 🔹 MODERN TILE
  Widget _tile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}