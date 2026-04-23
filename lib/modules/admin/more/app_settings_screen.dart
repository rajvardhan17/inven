import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_theme.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  bool notifications = true;
  bool darkMode = false;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 🔥 LOAD ALL SETTINGS
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = userDoc.data() ?? {};

    setState(() {
      notifications = data['notifications'] ?? true;
      darkMode = prefs.getBool('darkMode') ?? false;
      loading = false;
    });
  }

  /// 🔥 TOGGLE NOTIFICATIONS (Firestore)
  Future<void> _toggleNotifications(bool value) async {
    setState(() => notifications = value);

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'notifications': value,
    }, SetOptions(merge: true));
  }

  /// 🌙 TOGGLE DARK MODE (Local)
  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);

    setState(() => darkMode = value);

    _toast("Restart app to apply theme");
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text("App Settings"),
        backgroundColor: AppTheme.surface,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [

                /// 🔹 SAME STYLE AS MORE SCREEN
                _section("Preferences"),

                _tileSwitch(
                  icon: Icons.notifications_active,
                  title: "Notifications",
                  value: notifications,
                  color: AppTheme.blue,
                  onChanged: _toggleNotifications,
                ),

                _tileSwitch(
                  icon: Icons.dark_mode,
                  title: "Dark Mode",
                  value: darkMode,
                  color: AppTheme.purple,
                  onChanged: _toggleDarkMode,
                ),

                const SizedBox(height: 20),

                /// 🔴 LOGOUT
                _tileButton(
                  icon: Icons.logout,
                  title: "Logout",
                  color: AppTheme.red,
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 10),
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

  /// 🔥 SWITCH TILE (WORKING)
  Widget _tileSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required Color color,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _tileButton({
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
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}