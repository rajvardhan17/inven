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
  String? selectedShop;
  String? selectedProduct;
  int quantity = 1;

  List<Map<String, dynamic>> orderItems = [];

  void _addItem() {
    if (selectedProduct == null) return;

    setState(() {
      orderItems.add({
        "product": selectedProduct,
        "qty": quantity,
      });
    });
  }

  void _placeOrder() {
    if (selectedShop == null || orderItems.isEmpty) return;

    Navigator.pop(context, {
      "shop": selectedShop,
      "items": orderItems,
      "date": DateTime.now().toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Order")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Shop Dropdown
            DropdownButtonFormField<String>(
              hint: const Text("Select Shop"),
              value: selectedShop,
              items: widget.shops
                  .map<DropdownMenuItem<String>>(
                      (s) => DropdownMenuItem<String>(
                            value: s["name"],
                            child: Text(s["name"]),
                          ))
                  .toList(),
              onChanged: (val) => setState(() => selectedShop = val),
            ),

            const SizedBox(height: 16),

            // 🔹 Product Dropdown
            DropdownButtonFormField<String>(
              hint: const Text("Select Product"),
              value: selectedProduct,
              items: widget.products
                  .map<DropdownMenuItem<String>>(
                      (p) => DropdownMenuItem<String>(
                            value: p["name"],
                            child: Text(p["name"]),
                          ))
                  .toList(),
              onChanged: (val) => setState(() => selectedProduct = val),
            ),

            const SizedBox(height: 16),

            // 🔹 Quantity
            Row(
              children: [
                const Text("Qty: "),
                IconButton(
                  onPressed: () {
                    if (quantity > 1) setState(() => quantity--);
                  },
                  icon: const Icon(Icons.remove),
                ),
                Text(quantity.toString()),
                IconButton(
                  onPressed: () => setState(() => quantity++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),

            ElevatedButton(
              onPressed: _addItem,
              child: const Text("Add Item"),
            ),

            const SizedBox(height: 20),

            // 🔹 Items List
            Expanded(
              child: ListView.builder(
                itemCount: orderItems.length,
                itemBuilder: (_, i) {
                  final item = orderItems[i];
                  return ListTile(
                    title: Text(item["product"]),
                    trailing: Text("x${item["qty"]}"),
                  );
                },
              ),
            ),

            ElevatedButton(
              onPressed: _placeOrder,
              child: const Text("Place Order"),
            )
          ],
        ),
      ),
    );
  }
}
