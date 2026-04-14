import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {

  final db = FirebaseFirestore.instance;

  // 🔥 SAFE ITEMS PARSER (CRASH FIX)
  List<Map<String, dynamic>> _parseItems(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw.whereType<Map>().map((e) {
        return Map<String, dynamic>.from(e);
      }).toList();
    }

    if (raw is Map) {
      return raw.values.whereType<Map>().map((e) {
        return Map<String, dynamic>.from(e);
      }).toList();
    }

    return [];
  }

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
              _buildSalesTrend(),
              _buildRecentOrders(),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 HEADER (UNCHANGED)
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("BizAdmin",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("Welcome back, Admin",
                      style: TextStyle(color: Colors.grey)),
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

  // 🔹 OVERVIEW (SAFE)
  Widget _buildOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('orders').snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data!.docs;

        int totalOrders = docs.length;
        int pendingOrders = 0;
        double totalSales = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;

          final status = (data['status'] ?? '').toString().toLowerCase();
          final paymentStatus =
              (data['paymentStatus'] ?? data['status'] ?? '')
                  .toString()
                  .toLowerCase();

          final amount = (data['totalAmount'] ?? 0);

          final double safeAmount =
              amount is int ? amount.toDouble() : (amount is double ? amount : 0);

          if (status == 'pending') pendingOrders++;

          if (paymentStatus == 'paid' || status == 'delivered') {
            totalSales += safeAmount;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Overview",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _card("$totalOrders", "Orders", Icons.shopping_bag, Colors.blue),
                  _card("₹${totalSales.toInt()}", "Sales",
                      Icons.currency_rupee, Colors.green),
                  _card("$pendingOrders", "Pending",
                      Icons.access_time, Colors.red),
                ],
              ),
            ],
          ),
        );
      },
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
            Text(value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // 🔹 SALES TREND
  Widget _buildSalesTrend() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text("Sales Trend (Coming Soon)"),
      ),
    );
  }

  // 🔥 RECENT ORDERS (FULL FIXED)
  Widget _buildRecentOrders() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Recent Orders",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Live", style: TextStyle(color: Colors.green)),
              ],
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('orders')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                return Column(
                  children: docs.map<Widget>((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final status = (data['status'] ?? 'pending').toString();
                    final shopName = data['shopName'] ?? "Unknown Shop";

                    final items = _parseItems(data['items']);

                    String products = items
                        .take(2)
                        .map((e) =>
                            "${e['productName'] ?? ''} x${e['qty'] ?? 0}")
                        .join(", ");

                    if (items.length > 2) {
                      products += " +${items.length - 2} more";
                    }

                    return Column(
                      children: [
                        _orderTile(
                          shopName,
                          products.isEmpty ? "No items" : products,
                          "₹${data['totalAmount'] ?? 0}",
                          status,
                          _getStatusColor(status),
                        ),
                        const Divider(),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTile(
    String title,
    String subtitle,
    String price,
    String status,
    Color color,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(Icons.receipt, color: color),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(price,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status,
                style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'packed':
      case 'processing':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Quick Actions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _action(Icons.add, "Add Product", Colors.blue),
              _action(Icons.store, "Shops", Colors.green),
              _action(Icons.receipt, "Orders", Colors.orange),
              _action(Icons.people, "Users", Colors.red),
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