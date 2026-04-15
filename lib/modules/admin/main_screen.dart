import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme_provider.dart';
import 'dashboard/AdminHome.dart';
import 'inventory/InventoryScreen.dart';
import 'payments/payments_screen.dart';
import 'orders/orders_screen.dart';
import 'more/more_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> screens = [
    const AdminHome(),
    const InventoryScreen(),
    const PaymentsScreen(),
    const OrdersScreen(),
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 🔥 DRAWER
      drawer: _buildDrawer(),

      // 🔥 BODY
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: IndexedStack(
            key: ValueKey(currentIndex),
            index: currentIndex,
            children: screens,
          ),
        ),
      ),

      // 🔥 MODERN BOTTOM NAV
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory),
              label: "Inventory",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment_outlined),
              activeIcon: Icon(Icons.payment),
              label: "Payments",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: "Orders",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              activeIcon: Icon(Icons.more_vert),
              label: "More",
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 DRAWER (ERP STYLE)
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
              ),
            ),
            child: const SafeArea(
              child: Text(
                "BizAdmin ERP",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          _drawerItem(Icons.dashboard, "Dashboard", 0),
          _drawerItem(Icons.inventory, "Inventory", 1),
          _drawerItem(Icons.payment, "Payments", 2),
          _drawerItem(Icons.shopping_cart, "Orders", 3),
          _drawerItem(Icons.more_horiz, "More", 4),

          const Divider(),

          // 🌙 DARK MODE TOGGLE
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text("Dark Mode"),
            trailing: Switch(
              value: context.watch<ThemeProvider>().isDark,
              onChanged: (_) {
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 DRAWER ITEM (CONNECTED TO NAVIGATION)
  Widget _drawerItem(IconData icon, String title, int index) {
    final isSelected = currentIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.deepPurple : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.deepPurple : null,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        setState(() => currentIndex = index);
      },
    );
  }
}