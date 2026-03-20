import 'package:flutter/material.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildOverview(),
              _buildRecentOrders(),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 HEADER
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "BizAdmin",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Welcome back, Admin",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.notifications_none),
          ),
        ],
      ),
    );
  }

  // 🔹 OVERVIEW CARDS
  Widget _buildOverview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Overview",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _card("1,284", "Orders", Icons.shopping_bag, Colors.blue),
              _card("₹48K", "Sales", Icons.currency_rupee, Colors.green),
              _card("37", "Pending", Icons.access_time, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(String value, String title, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // 🔹 RECENT ORDERS
  Widget _buildRecentOrders() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Recent Orders",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text("View all", style: TextStyle(color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 10),

            _orderTile("#4521", "₹124", "Completed", Colors.green),
            _orderTile("#4520", "₹389", "Processing", Colors.orange),
            _orderTile("#4519", "₹56", "Pending", Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _orderTile(String id, String price, String status, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(Icons.receipt, color: color),
      ),
      title: Text("Order $id"),
      subtitle: const Text("2 items • 10 mins ago"),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(status, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  // 🔹 QUICK ACTIONS
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Quick Actions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _action(Icons.add, "Add", Colors.blue),
              _action(Icons.inventory, "Inventory", Colors.green),
              _action(Icons.bar_chart, "Reports", Colors.orange),
              _action(Icons.payment, "Payments", Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String text, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
