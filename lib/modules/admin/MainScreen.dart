import 'package:flutter/material.dart';

import 'dashboard/AdminHome.dart';
import 'inventory/InventoryScreen.dart';
import 'payments/payments_screen.dart'; // ✅ only one import
import 'orders/orders_screen.dart';
import 'more/more_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> screens =[
    AdminHome(),
    InventoryScreen(),
    PaymentsScreen(),
    OrdersScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
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
            icon: Icon(Icons.payment_rounded),
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
    );
  }
}