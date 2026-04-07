import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import './user_screen.dart';
import './shop_screen.dart';
import './add_user_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            /// 🔥 TOP PROFILE SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF6A82FB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.email ?? "User",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Welcome back 👋",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
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
                  _sectionTitle("Management"),
                  _tile(
                    icon: Icons.people,
                    title: "Manage Users",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UsersScreen()),
                      );
                    },
                  ),
                  _tile(
                    icon: Icons.person_add,
                    title: "Add User",
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddUserScreen()), // UsersScreen handles all roles
                      );
                    },
                  ),
                  _tile(
                    icon: Icons.store,
                    title: "Shops",
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ShopsScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  /// 🔹 ANALYTICS SECTION
                  _sectionTitle("Analytics"),
                  _tile(
                    icon: Icons.bar_chart,
                    title: "Reports",
                    color: Colors.orange,
                    onTap: () {},
                  ),
                  _tile(
                    icon: Icons.receipt_long,
                    title: "Order History",
                    color: Colors.purple,
                    onTap: () {},
                  ),

                  const SizedBox(height: 15),

                  /// 🔹 SETTINGS SECTION
                  _sectionTitle("Settings"),
                  _tile(
                    icon: Icons.settings,
                    title: "App Settings",
                    color: Colors.grey,
                    onTap: () {},
                  ),

                  const SizedBox(height: 20),

                  /// 🔴 LOGOUT BUTTON (BIG STYLE)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    onPressed: () => _logout(context),
                  ),
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
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logged out successfully")),
      );
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
          color: Colors.black54,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}