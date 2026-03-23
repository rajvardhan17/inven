import 'package:flutter/material.dart';

class ProductionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rawMaterials;
  final List<Map<String, dynamic>> products;
  final Map<String, Map<String, double>> recipe;

  const ProductionScreen({
    super.key,
    required this.rawMaterials,
    required this.products,
    required this.recipe,
  });

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  String? selectedProduct;
  TextEditingController qtyController = TextEditingController();

  // 🔥 PRODUCTION LOGIC
  void produce() {
    if (selectedProduct == null || qtyController.text.isEmpty) return;

    int qty = int.parse(qtyController.text);
    final productRecipe = widget.recipe[selectedProduct];

    if (productRecipe == null) return;

    // ✅ Check raw material availability
    for (var item in productRecipe.entries) {
      final raw = widget.rawMaterials.firstWhere(
        (e) => e["name"] == item.key,
      );

      double required = item.value * qty;

      if (raw["qty"] < required) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Not enough ${item.key}")),
        );
        return;
      }
    }

    // ✅ Deduct raw
    for (var item in productRecipe.entries) {
      final raw = widget.rawMaterials.firstWhere(
        (e) => e["name"] == item.key,
      );

      raw["qty"] -= item.value * qty;
    }

    // ✅ Add product
    final productIndex =
        widget.products.indexWhere((p) => p["name"] == selectedProduct);

    if (productIndex != -1) {
      widget.products[productIndex]["qty"] += qty;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Production Successful ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Production"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Card Container
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
                  // 🔹 Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Select Product",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedProduct,
                    items: widget.products
                        .map<DropdownMenuItem<String>>(
                            (p) => DropdownMenuItem<String>(
                                  value: p["name"] as String,
                                  child: Text(p["name"]),
                                ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedProduct = val;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Quantity Input
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Enter Quantity",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔹 Produce Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: produce,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Produce"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
