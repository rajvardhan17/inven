import 'package:flutter/material.dart';
import '../../../core/widgets/custom_button.dart';

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
  String? selectedShop;
  String? selectedProduct;

  late TextEditingController qtyController;
  late TextEditingController priceController;
  late TextEditingController gstController;

  List<Map<String, dynamic>> orderItems = [];

  @override
  void initState() {
    super.initState();
    qtyController = TextEditingController(text: "");
    priceController = TextEditingController();
    gstController = TextEditingController(text: "18"); // default GST
  }

  @override
  void dispose() {
    qtyController.dispose();
    priceController.dispose();
    gstController.dispose();
    super.dispose();
  }

  // ✅ SUBTOTAL
  double get subTotal {
    return orderItems.fold<double>(0, (sum, item) {
      final value = item["total"];
      if (value is num) return sum + value;
      if (value is String) return sum + (double.tryParse(value) ?? 0);
      return sum;
    });
  }

  // ✅ GST %
  double get gstPercent {
    return double.tryParse(gstController.text) ?? 0;
  }

  // ✅ GST AMOUNT
  double get gstAmount {
    return (subTotal * gstPercent) / 100;
  }

  // ✅ GRAND TOTAL
  double get grandTotal {
    return subTotal + gstAmount;
  }

  // 🔹 ADD ITEM
  void _addItem() {
    if (selectedProduct == null ||
        qtyController.text.isEmpty ||
        priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    int qty = int.tryParse(qtyController.text) ?? 0;
    double price = double.tryParse(priceController.text) ?? 0;

    if (qty <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid qty & price")),
      );
      return;
    }

    setState(() {
      orderItems.add({
        "product": selectedProduct,
        "qty": qty,
        "price": price,
        "total": qty * price,
      });

      qtyController.text = "1";
      priceController.clear();
    });
  }

  // 🔹 PLACE ORDER
  void _placeOrder() {
    if (selectedShop == null || orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete order details")),
      );
      return;
    }

    Navigator.pop(context, {
      "shop": selectedShop,
      "items": orderItems,
      "subTotal": subTotal,
      "gstPercent": gstPercent,
      "gstAmount": gstAmount,
      "totalAmount": grandTotal,
      "date": DateTime.now().toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text("Create Order")),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🔹 FORM CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // 🔹 SHOP
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Select Shop",
                          border: OutlineInputBorder(),
                        ),
                        value:
                            widget.shops.any((s) => s["name"] == selectedShop)
                                ? selectedShop
                                : null,
                        items: widget.shops
                            .map<DropdownMenuItem<String>>(
                              (s) => DropdownMenuItem<String>(
                                value: s["name"].toString(),
                                child: Text(s["name"].toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => selectedShop = val),
                      ),

                      const SizedBox(height: 16),

                      // 🔹 PRODUCT
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Select Product",
                          border: OutlineInputBorder(),
                        ),
                        value: widget.products
                                .any((p) => p["name"] == selectedProduct)
                            ? selectedProduct
                            : null,
                        items: widget.products
                            .map<DropdownMenuItem<String>>(
                              (p) => DropdownMenuItem<String>(
                                value: p["name"].toString(),
                                child: Text(p["name"].toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedProduct = val),
                      ),

                      const SizedBox(height: 16),

                      // 🔹 QTY + PRICE
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

                      const SizedBox(height: 16),

                      // 🔹 GST INPUT
                      TextField(
                        controller: gstController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "GST (%)",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🔹 ADD ITEM BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: CustomButton(
                          text: "Add Item",
                          onPressed: _addItem,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 ITEMS LIST
                orderItems.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "No items added",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: orderItems.length,
                        itemBuilder: (_, i) {
                          final item = orderItems[i];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shopping_bag,
                                    color: Colors.deepPurple),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item["product"],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "₹${item["price"]} x ${item["qty"]}",
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "₹${item["total"]}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                const SizedBox(height: 10),

                // 🔥 TOTAL SECTION
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Subtotal: ₹${subTotal.toStringAsFixed(2)}"),
                          Text(
                              "GST (${gstPercent.toStringAsFixed(0)}%): ₹${gstAmount.toStringAsFixed(2)}"),
                          const SizedBox(height: 4),
                          Text(
                            "Total: ₹${grandTotal.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: "Place Order",
                        onPressed: _placeOrder,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
