import 'package:flutter/material.dart';
import 'create_order_screen.dart';
import '../../../services/order_service.dart';
import '../../../data/inventory_data.dart';
import '../../../core/widgets/custom_button.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> orders = [];

  final List<Map<String, dynamic>> shops = [
    {"name": "Sharma Store"},
  ];

  // 🔹 Create Order
  void _createOrder() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOrderScreen(
          shops: shops,
          products: InventoryData.products, // ✅ shared data
        ),
      ),
    );

    if (result != null) {
      setState(() {
        orders.add({
          ...result,
          "status": "Pending",
        });
      });
    }
  }

  // 🔹 Pack Order
  void _packOrder(int index) {
    final order = orders[index];

    final success = OrderService.packOrder(order);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough stock")),
      );
      return;
    }

    setState(() {
      orders[index]["status"] = "Packed";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text("Orders")),
      floatingActionButton: FloatingActionButton(
        onPressed: _createOrder,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (_, index) {
          final order = orders[index];

          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Shop Name
                Text(
                  "Shop: ${order["shop"]}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),

                // 🔹 Items List
                ...order["items"].map<Widget>(
                  (item) => Text("${item["product"]} x${item["qty"]}"),
                ),

                const SizedBox(height: 10),

                // 🔹 Status + Button Row
                Row(
                  children: [
                    // 🔹 Status
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Status: ${order["status"]}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: order["status"] == "Packed"
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),

                    // 🔹 Pack Button
                    if (order["status"] == "Pending")
                      Expanded(
                        flex: 1,
                        child: CustomButton(
                          text: "Pack",
                          height: 40, // 🔥 smaller button
                          onPressed: () => _packOrder(index),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
