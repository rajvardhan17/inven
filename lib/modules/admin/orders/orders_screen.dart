import 'package:flutter/material.dart';
import 'create_order_screen.dart';

// 🔥 Temporary global inventory (later DB/API)
List<Map<String, dynamic>> globalProducts = [
  {"name": "Rose Agarbatti", "qty": 100},
  {"name": "Sandal Agarbatti", "qty": 80},
];

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
          products: globalProducts,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        orders.add({
          ...result,
          "status": "Pending", // ✅ default status
        });
      });
    }
  }

  // 🔹 Mark as Packed & Deduct Inventory
  void _markAsPacked(int index) {
    final order = orders[index];

    if (order["status"] == "Packed") return; // ❌ prevent double packing

    bool canPack = true;

    // 🔹 Check stock first
    for (var item in order["items"]) {
      final product = globalProducts.firstWhere(
        (p) => p["name"] == item["product"],
        orElse: () => {},
      );

      if (product.isEmpty || product["qty"] < item["qty"]) {
        canPack = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Not enough stock for ${item["product"]}"),
          ),
        );
        break;
      }
    }

    if (!canPack) return;

    // 🔹 Deduct stock and update status
    setState(() {
      for (var item in order["items"]) {
        final product = globalProducts.firstWhere(
          (p) => p["name"] == item["product"],
        );
        product["qty"] -= item["qty"];
      }

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
                // 🔹 Shop
                Text(
                  "Shop: ${order["shop"]}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),

                // 🔹 Items
                ...order["items"].map<Widget>((item) => Text(
                      "${item["product"]} x${item["qty"]}",
                    )),

                const SizedBox(height: 10),

                // 🔹 Status & Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Status: ${order["status"]}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: order["status"] == "Packed"
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    if (order["status"] == "Pending")
                      ElevatedButton(
                        onPressed: () => _markAsPacked(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                        child: const Text("Mark as Packed"),
                      ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
