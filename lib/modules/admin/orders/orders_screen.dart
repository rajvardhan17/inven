import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_order_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {

  // 🔹 CREATE ORDER
  Future<void> _createOrder() async {
    try {
      final shopSnapshot =
          await FirebaseFirestore.instance.collection('shops').get();

      final productSnapshot =
          await FirebaseFirestore.instance.collection('products').get();

      final shops = shopSnapshot.docs.map((doc) {
        return {
          "id": doc.id,
          ...doc.data(),
        };
      }).toList();

      final products = productSnapshot.docs.map((doc) {
        return {
          "id": doc.id,
          ...doc.data(),
        };
      }).toList();

      if (shops.isEmpty || products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Add shops & products first")),
        );
        return;
      }

      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => CreateOrderScreen(
            shops: shops,
            products: products,
          ),
        ),
      );

      if (result != null) {
        await FirebaseFirestore.instance.collection('orders').add({
          ...result,
          "status": "pending",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // 🔥 PACK ORDER (FIXED)
  Future<void> _packOrder(String orderId, Map<String, dynamic> order) async {
  try {
    final db = FirebaseFirestore.instance;

    // 🔹 Generate invoice
    final snapshot = await db.collection('payments').get();
    int count = snapshot.docs.length + 1;
    String invoiceNo = "INV-${count.toString().padLeft(3, '0')}";

    // 🔹 Update order
    await db.collection('orders').doc(orderId).update({
      "status": "packed",
    });

    // 🔹 Create payment
    await db.collection('payments').add({
      "orderId": orderId,
      "shopId": order["shopId"],
      "shopName": order["shopName"],
      "totalAmount": order["totalAmount"],
      "subTotal": order["subTotal"],
      "gstAmount": order["gstAmount"],
      "gstPercent": order["gstPercent"],
      "items": order["items"],
      "status": "unpaid",
      "invoiceNo": invoiceNo,
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Packed • Invoice $invoiceNo created")),
    );

  } catch (e) {
    print("Error: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text('Orders')),

      floatingActionButton: FloatingActionButton(
        onPressed: _createOrder,
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Orders Yet"));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (_, index) {
              final doc = orders[index];
              final order = doc.data() as Map<String, dynamic>;
              final items = (order["items"] ?? []) as List;

              final subTotal = (order["subTotal"] ?? 0).toDouble();
              final gstPercent = (order["gstPercent"] ?? 0).toDouble();
              final gstAmount = (order["gstAmount"] ?? 0).toDouble();
              final total = (order["totalAmount"] ?? 0).toDouble();
              final status = (order["status"] ?? "pending");

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

                    // 🏪 SHOP
                    Text(
                      "Shop: ${order["shopName"] ?? ""}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 📦 ITEMS
                    ...items.map<Widget>((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "${item["productName"]} x${item["qty"]}",
                              ),
                            ),
                            Text("₹${item["price"]}"),
                            const SizedBox(width: 10),
                            Text(
                              "₹${item["total"]}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),

                    const Divider(height: 20),

                    // 💰 BILL
                    _billRow("Subtotal", subTotal),
                    _billRow("GST (${gstPercent.toStringAsFixed(0)}%)", gstAmount),
                    _billRow("Total", total, isBold: true),

                    const SizedBox(height: 10),

                    // 🔹 STATUS + BUTTON
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Status: $status",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: status == "packed"
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                        if (status == "pending")
                          ElevatedButton(
                            onPressed: () => _packOrder(doc.id, order), // ✅ FIXED
                            child: const Text("Pack"),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🔹 BILL ROW
  Widget _billRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text("₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}