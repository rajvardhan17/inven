import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_order_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // ✅ SAFE ITEM PARSER (FIXES ALL CRASHES)
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

  // 🔹 CREATE ORDER
  Future<void> _createOrder() async {
    try {
      final shopSnapshot = await db.collection('shops').get();
      final productSnapshot = await db.collection('products').get();

      final shops = shopSnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data()})
          .toList();

      final products = productSnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data()})
          .toList();

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
        await db.collection('orders').add({
          ...result,
          "status": "pending",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Create Order Error: $e");
    }
  }

  // 🔥 PACK ORDER (SAFE + PRODUCTION LEVEL)
  Future<void> _packOrder(
    String orderId,
    Map<String, dynamic> order,
  ) async {
    try {
      final paymentsRef = db.collection('payments');

      final invoiceNo =
          "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

      await db.runTransaction((txn) async {
        txn.update(db.collection('orders').doc(orderId), {
          "status": "packed",
        });

        txn.set(paymentsRef.doc(), {
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
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Packed • Invoice $invoiceNo")),
      );
    } catch (e) {
      debugPrint("Pack Order Error: $e");
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
        stream: db
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

              final items = _parseItems(order["items"]);

              final subTotal =
                  (order["subTotal"] ?? 0).toDouble();
              final gstPercent =
                  (order["gstPercent"] ?? 0).toDouble();
              final gstAmount =
                  (order["gstAmount"] ?? 0).toDouble();
              final total =
                  (order["totalAmount"] ?? 0).toDouble();

              final status =
                  (order["status"] ?? "pending").toString();

              return _orderCard(
                doc.id,
                order,
                items,
                subTotal,
                gstPercent,
                gstAmount,
                total,
                status,
              );
            },
          );
        },
      ),
    );
  }

  // 🔥 ORDER CARD (FULL SAFE UI)
  Widget _orderCard(
    String id,
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
    double subTotal,
    double gstPercent,
    double gstAmount,
    double total,
    String status,
  ) {
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
            "Shop: ${order["shopName"] ?? "Unknown"}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 10),

          // 📦 ITEMS (FULL SAFE)
          ...items.map((item) {
            final name = item["productName"]?.toString() ?? "Item";
            final qty = item["qty"]?.toString() ?? "0";
            final price = item["price"]?.toString() ?? "0";
            final totalItem = item["total"]?.toString() ?? "0";

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text("$name x$qty")),
                  Text("₹$price"),
                  const SizedBox(width: 10),
                  Text(
                    "₹$totalItem",
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

          // 🔘 STATUS + ACTION
          Row(
            children: [
              Expanded(
                child: Text(
                  "Status: ${status.toUpperCase()}",
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
                  onPressed: () => _packOrder(id, order),
                  child: const Text("Pack"),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 BILL ROW
  Widget _billRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight:
                isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          "₹${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight:
                isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}