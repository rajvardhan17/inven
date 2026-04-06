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

  final qtyController = TextEditingController(text: "0");
  final priceController = TextEditingController();
  final gstController = TextEditingController(text: "18");

  List<Map<String, dynamic>> orderItems = [];

  // ✅ FIXED product finder
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
    if (selectedProduct == null) return;

    int qty = int.tryParse(qtyController.text) ?? 0;
    double price = double.tryParse(priceController.text) ?? 0;

    if (qty <= 0 || price <= 0) return;

    setState(() {
      orderItems.add({
        "productId": selectedProductId,
        "productName": selectedProduct!["name"].toString(),
        "qty": qty,
        "price": price,
        "total": qty * price,
      });

      qtyController.text = "1";
    });
  }

  // 🚀 PLACE ORDER
  void placeOrder() {
  if (selectedShopId == null || orderItems.isEmpty) return;

  final selectedShop = widget.shops.firstWhere(
    (s) => s["id"].toString() == selectedShopId,
  );

  Navigator.pop(context, {
    "shopId": selectedShopId,
    "shopName": selectedShop["shopName"], // ✅ ADD THIS
    "items": orderItems,
    "subTotal": subTotal,
    "gstPercent": gstPercent,
    "gstAmount": gstAmount,
    "totalAmount": grandTotal,
    "status": "pending",
    "date": DateTime.now(),
  });
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
            DropdownButtonFormField<String>(
              hint: const Text("Select Shop"),
              value: selectedShopId,
              items: widget.shops.map<DropdownMenuItem<String>>((s) {
                return DropdownMenuItem<String>(
                  value: s["id"].toString(),
                  child: Text(s["shopName"] ?? "No Name"),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedShopId = val),
            ),

            const SizedBox(height: 16),

            // 📦 PRODUCT
            DropdownButtonFormField<String>(
              hint: const Text("Select Product"),
              value: selectedProductId,
              items: widget.products.map<DropdownMenuItem<String>>((p) {
                return DropdownMenuItem<String>(
                  value: p["id"].toString(),
                  child: Text(p["name"] ?? "No Name"),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedProductId = val;
                  final product = selectedProduct;
                  if (product != null) {
                    priceController.text = product["price"].toString();
                  }
                });
              },
            ),

            const SizedBox(height: 16),

            // 🔢 QTY + PRICE
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Quantity",
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
                      labelText: "Price (₹)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 💸 GST
            TextField(
              controller: gstController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "GST (%)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ➕ ADD ITEM
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: addItem,
                child: const Text("Add Item"),
              ),
            ),

            const SizedBox(height: 20),

            // 📋 ITEMS LIST
            orderItems.isEmpty
                ? const Text("No items added")
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orderItems.length,
                    itemBuilder: (_, i) {
                      final item = orderItems[i];
                      return ListTile(
                        title: Text(item["productName"]),
                        subtitle:
                            Text("₹${item["price"]} x ${item["qty"]}"),
                        trailing: Text(
                          "₹${item["total"].toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 20),

            // 💰 TOTALS
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Subtotal: ₹${subTotal.toStringAsFixed(2)}"),
                Text(
                    "GST (${gstPercent.toStringAsFixed(0)}%): ₹${gstAmount.toStringAsFixed(2)}"),
                const SizedBox(height: 5),
                Text(
                  "Total: ₹${grandTotal.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
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
}