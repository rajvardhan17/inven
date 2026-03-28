import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'create_order_screen.dart';
import '../../../services/order_service.dart';
import '../../../data/inventory_data.dart';
import '../../../data/order_data.dart';
import '../../../core/widgets/custom_button.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final List<Map<String, dynamic>> shops = [
    {"name": "Sharma Store"},
  ];

  // 🔹 CREATE ORDER
  void _createOrder() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOrderScreen(
          shops: shops,
          products: InventoryData.products,
        ),
      ),
    );

    if (result != null) {
      Provider.of<OrderData>(context, listen: false).addOrder(result);
    }
  }

  // 🔹 PACK ORDER
  void _packOrder(int index) {
    final orderData = Provider.of<OrderData>(context, listen: false);

    final success = OrderService.packOrder(orderData.orders[index]);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough stock")),
      );
      return;
    }

    orderData.packOrder(index);
  }

  @override
  Widget build(BuildContext context) {
    final orderData = Provider.of<OrderData>(context);
    final orders = orderData.orders;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text("Orders")),
      floatingActionButton: FloatingActionButton(
        onPressed: _createOrder,
        child: const Icon(Icons.add),
      ),
      body: orders.isEmpty
          ? const Center(child: Text("No Orders Yet"))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (_, index) {
                final order = orders[index];
                final items = (order["items"] ?? []) as List;

                // ✅ VALUES FROM CREATE ORDER SCREEN
                final subTotal = (order["subTotal"] ?? 0).toDouble();
                final gstPercent = (order["gstPercent"] ?? 0).toDouble();
                final gstAmount = (order["gstAmount"] ?? 0).toDouble();
                final total = (order["totalAmount"] ?? 0).toDouble();

                return Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 SHOP
                      Text(
                        "Shop: ${order["shop"]}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 🔹 ITEMS
                      ...items.map<Widget>((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${item["product"]} x${item["qty"]}",
                                ),
                              ),
                              Text(
                                "₹${item["price"]} x ${item["qty"]}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "₹${item["total"]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const Divider(height: 20),

                      // 🔥 BILL DETAILS
                      _billRow("Subtotal", subTotal),
                      _billRow(
                        "GST (${gstPercent.toStringAsFixed(0)}%)",
                        gstAmount,
                      ),
                      const SizedBox(height: 5),
                      _billRow("Total", total, isBold: true),

                      const SizedBox(height: 10),

                      // 🔹 STATUS + BUTTON
                      Row(
                        children: [
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
                          if (order["status"] == "Pending")
                            Expanded(
                              flex: 1,
                              child: CustomButton(
                                text: "Pack",
                                height: 40,
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

  // 🔹 BILL ROW
  Widget _billRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          "₹${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
