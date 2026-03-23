import 'package:flutter/material.dart';
import './user_screen.dart';
import './shop_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("More"),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            icon: Icons.people,
            title: "Manage Users",
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsersScreen()),
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
                    builder: (_) => const ShopsScreen(),
                  ));
            },
          ),
          _tile(
            icon: Icons.bar_chart,
            title: "Reports",
            color: Colors.orange,
            onTap: () {},
          ),
          _tile(
            icon: Icons.settings,
            title: "Settings",
            color: Colors.grey,
            onTap: () {},
          ),
          const SizedBox(height: 20),
          _tile(
            icon: Icons.logout,
            title: "Logout",
            color: Colors.red,
            onTap: () {
              // logout logic later
            },
          ),
        ],
      ),
    );
  }

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
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
