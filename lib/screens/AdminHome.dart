import 'package:flutter/material.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔹 STATS CARDS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCard("Products", "120", Icons.inventory),
                _buildCard("Stock In", "45", Icons.arrow_downward),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCard("Stock Out", "30", Icons.arrow_upward),
                _buildCard("Low Stock", "10", Icons.warning),
              ],
            ),

            const SizedBox(height: 30),

            // 🔹 ACTION BUTTONS
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to Add Product
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Add Product"),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to Inventory List
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("View Inventory"),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 CARD WIDGET
  Widget _buildCard(String title, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(title),
        ],
      ),
    );
  }
}
