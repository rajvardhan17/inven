import 'package:flutter/material.dart';
import 'create_order_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> orders = [];

  // Dummy data (connect later)
  List<Map<String, dynamic>> shops = [
    {"name": "Sharma Store"},
  ];

  List<Map<String, dynamic>> products = [
    {"name": "Rose Agarbatti"},
    {"name": "Sandal Agarbatti"},
  ];

  void _createOrder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOrderScreen(
          shops: shops,
          products: products,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        orders.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Orders"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createOrder,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (_, i) {
          final order = orders[i];

          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Shop: ${order["shop"]}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...order["items"].map<Widget>((item) => Text(
                      "${item["product"]} x${item["qty"]}",
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}
