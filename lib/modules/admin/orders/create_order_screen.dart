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

  List<Map<String, dynamic>> orderItems = [];

  @override
  void initState() {
    super.initState();
    qtyController = TextEditingController(text: "1");
  }

  @override
  void dispose() {
    qtyController.dispose();
    super.dispose();
  }

  // 🔹 Add Item
  void _addItem() {
    if (selectedProduct == null || qtyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select product & enter quantity")),
      );
      return;
    }

    int qty = int.tryParse(qtyController.text) ?? 0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid quantity")),
      );
      return;
    }

    setState(() {
      orderItems.add({
        "product": selectedProduct,
        "qty": qty,
      });

      qtyController.text = "1"; // reset after adding
    });
  }

  // 🔹 Place Order
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
      "date": DateTime.now().toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text("Create Order")),
      body: Padding(
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
                  // 🔹 Shop Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Select Shop",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedShop,
                    items: widget.shops
                        .map<DropdownMenuItem<String>>(
                          (s) => DropdownMenuItem<String>(
                            value: s["name"],
                            child: Text(s["name"]),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => selectedShop = val),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Product Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Select Product",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedProduct,
                    items: widget.products
                        .map<DropdownMenuItem<String>>(
                          (p) => DropdownMenuItem<String>(
                            value: p["name"],
                            child: Text(p["name"]),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => selectedProduct = val),
                  ),

                  const SizedBox(height: 16),

                  // 🔥 Quantity Input
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Enter Quantity",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Add Item Button

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: CustomButton(
                      text: "Add Item",
                      onPressed: _addItem, // ✅ your actual function
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 ORDER ITEMS LIST
            Expanded(
              child: orderItems.isEmpty
                  ? const Center(
                      child: Text(
                        "No items added",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
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
                                child: Text(
                                  item["product"],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text("x${item["qty"]}"),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // 🔹 Place Order Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  "Place Order",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
