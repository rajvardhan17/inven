import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? selectedProductId;
  final qtyController = TextEditingController();

  bool isLoading = false;

  // 🔹 PRODUCTION LOGIC (TRANSACTION SAFE)
  Future<void> produce() async {
    if (selectedProductId == null || qtyController.text.isEmpty) return;

    int qty = int.tryParse(qtyController.text) ?? 0;
    if (qty <= 0) return;

    setState(() => isLoading = true);

    try {
      await _db.runTransaction((transaction) async {

        // 🔹 Get product
        final productRef = _db.collection('products').doc(selectedProductId);
        final productSnap = await transaction.get(productRef);

        if (!productSnap.exists) throw Exception("Product not found");

        final productData = productSnap.data()!;
        final recipe = Map<String, dynamic>.from(productData["recipe"] ?? {});

        if (recipe.isEmpty) throw Exception("Recipe not defined");

        // 🔹 Check raw materials
        for (var entry in recipe.entries) {
          final rawQuery = await _db
              .collection('raw_materials')
              .where('name', isEqualTo: entry.key)
              .limit(1)
              .get();

          if (rawQuery.docs.isEmpty) {
            throw Exception("${entry.key} not found");
          }

          final rawDoc = rawQuery.docs.first;
          final rawData = rawDoc.data();

          double available = (rawData["qty"] ?? 0).toDouble();
          double required = (entry.value as num).toDouble() * qty;

          if (available < required) {
            throw Exception("Not enough ${entry.key}");
          }
        }

        // 🔹 Deduct raw materials
        for (var entry in recipe.entries) {
          final rawQuery = await _db
              .collection('raw_materials')
              .where('name', isEqualTo: entry.key)
              .limit(1)
              .get();

          final rawDoc = rawQuery.docs.first;

          double required = (entry.value as num).toDouble() * qty;

          transaction.update(rawDoc.reference, {
            "qty": FieldValue.increment(-required),
          });
        }

        // 🔹 Add product stock
        transaction.update(productRef, {
          "qty": FieldValue.increment(qty),
        });

        // 🔹 LOG PRODUCTION (VERY IMPORTANT 🔥)
        await _db.collection('production_logs').add({
          "productId": selectedProductId,
          "qty": qty,
          "createdAt": FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Production Successful ✅")),
      );

      Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  // 🔹 PRODUCTS DROPDOWN (LIVE)
  Widget _productDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('products').snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final products = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: "Select Product",
            border: OutlineInputBorder(),
          ),
          value: selectedProductId,
          items: products.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: Text(data["name"] ?? "No Name"),
            );
          }).toList(),
          onChanged: (val) => setState(() => selectedProductId = val),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text("Production")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

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

                  _productDropdown(),

                  const SizedBox(height: 16),

                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Enter Quantity",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : produce,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Produce"),
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