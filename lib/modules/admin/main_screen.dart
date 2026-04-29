import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/theme_provider.dart';
import 'dashboard/AdminHome.dart';
import 'inventory/InventoryScreen.dart';
import 'payments/payments_screen.dart';
import 'orders/orders_screen.dart';
import 'invoices/presentation/screens/invoice_dashboard_screen.dart';
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
    const InvoiceDashboardScreen(),
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
        child: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
      ),

      // 🔥 MODERN BOTTOM NAV (FIXED)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: AppTheme.cardShadow,
          border: const Border(
            top: BorderSide(color: AppTheme.border),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.accent,
          unselectedItemColor: AppTheme.textSecondary,
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
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: "Invoices",
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

  // 🔥 DRAWER (ERP STYLE - FIXED)
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.bg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: AppTheme.accentGrad,
            ),
            child: const SafeArea(
              child: Text(
                "BizAdmin ERP",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.bg,
                ),
              ),
            ),
          ),

          _drawerItem(Icons.dashboard, "Dashboard", 0),
          _drawerItem(Icons.inventory, "Inventory", 1),
          _drawerItem(Icons.payment, "Payments", 2),
          _drawerItem(Icons.shopping_cart, "Orders", 3),
          _drawerItem(Icons.receipt_long, "Invoices", 4),
          _drawerItem(Icons.more_horiz, "More", 5),

          const Divider(color: AppTheme.border),

          // 🌙 DARK MODE TOGGLE
          ListTile(
            leading: const Icon(Icons.dark_mode, color: AppTheme.textSecondary),
            title: const Text(
              "Dark Mode",
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            trailing: Switch(
              value: context.watch<ThemeProvider>().isDark,
              activeColor: AppTheme.accent,
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
        color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        setState(() => currentIndex = index);
      },
    );
  }
}