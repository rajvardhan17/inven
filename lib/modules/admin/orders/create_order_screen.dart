import 'package:flutter/material.dart';

class CreateOrderScreen extends StatefulWidget {
  final List<Map<String, dynamic>> shops;
  final List<Map<String, dynamic>> products;

  const CreateOrderScreen({
    super.key,
    required this.shops,
    required this.products,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  String? selectedShopId;
  String? selectedProductId;

  final qtyController = TextEditingController(text: "1");
  final priceController = TextEditingController();
  final gstController = TextEditingController(text: "18");

  List<Map<String, dynamic>> orderItems = [];

  Map<String, dynamic>? get selectedProduct {
    try {
      return widget.products.firstWhere(
        (p) => p["id"].toString() == selectedProductId,
      );
    } catch (_) {
      return null;
    }
  }

  // 💰 CALCULATIONS
  double get subTotal =>
      orderItems.fold(0.0, (sum, item) => sum + (item["total"] as double));

  double get gstPercent => double.tryParse(gstController.text) ?? 0;

  double get gstAmount => (subTotal * gstPercent) / 100;

  double get grandTotal => subTotal + gstAmount;

  // ➕ ADD ITEM
  void addItem() {
    if (selectedProduct == null) {
      _showError("Select a product");
      return;
    }

    int qty = int.tryParse(qtyController.text) ?? 0;
    double price = double.tryParse(priceController.text) ?? 0;

    if (qty <= 0 || price <= 0) {
      _showError("Enter valid quantity & price");
      return;
    }

    setState(() {
      orderItems.add({
        "productId": selectedProductId,
        "productName": selectedProduct!["name"],
        "qty": qty,
        "price": price,
        "total": qty * price,
      });

      qtyController.text = "1";
    });
  }

  // ❌ REMOVE ITEM
  void removeItem(int index) {
    setState(() => orderItems.removeAt(index));
  }

  // 🚀 PLACE ORDER
  void placeOrder() {
    if (selectedShopId == null) {
      _showError("Select a shop");
      return;
    }

    if (orderItems.isEmpty) {
      _showError("Add at least one item");
      return;
    }

    final selectedShop = widget.shops.firstWhere(
      (s) => s["id"].toString() == selectedShopId,
    );

    Navigator.pop(context, {
      "shopId": selectedShopId,
      "shopName": selectedShop["shopName"],
      "items": orderItems,
      "subTotal": subTotal,
      "gstPercent": gstPercent,
      "gstAmount": gstAmount,
      "totalAmount": grandTotal,
      "status": "pending",
      "createdAt": DateTime.now(),
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text("Create Order")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 🏪 SHOP
            _card(
              DropdownButtonFormField<String>(
                hint: const Text("Select Shop"),
                value: selectedShopId,
                items: widget.shops.map((s) {
                  return DropdownMenuItem(
                    value: s["id"].toString(),
                    child: Text(s["shopName"] ?? "No Name"),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedShopId = val),
              ),
            ),

            const SizedBox(height: 12),

            // 📦 PRODUCT
            _card(
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    hint: const Text("Select Product"),
                    value: selectedProductId,
                    items: widget.products.map((p) {
                      return DropdownMenuItem(
                        value: p["id"].toString(),
                        child: Text(p["name"] ?? "No Name"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedProductId = val;
                        final product = selectedProduct;
                        if (product != null) {
                          priceController.text =
                              product["price"].toString();
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Qty",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Price",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: gstController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "GST %",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: addItem,
                      child: const Text("Add Item"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📋 ITEMS
            _card(
              orderItems.isEmpty
                  ? const Center(child: Text("No items added"))
                  : Column(
                      children: List.generate(orderItems.length, (i) {
                        final item = orderItems[i];

                        return ListTile(
                          title: Text(item["productName"]),
                          subtitle:
                              Text("₹${item["price"]} x ${item["qty"]}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "₹${item["total"].toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => removeItem(i),
                              )
                            ],
                          ),
                        );
                      }),
                    ),
            ),

            const SizedBox(height: 20),

            // 💰 TOTALS
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Subtotal: ₹${subTotal.toStringAsFixed(2)}"),
                  Text(
                      "GST (${gstPercent.toStringAsFixed(0)}%): ₹${gstAmount.toStringAsFixed(2)}"),
                  const Divider(),
                  Text(
                    "Total: ₹${grandTotal.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🚀 PLACE ORDER
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: placeOrder,
                child: const Text("Place Order"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 COMMON CARD UI
  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: child,
    );
  }
}