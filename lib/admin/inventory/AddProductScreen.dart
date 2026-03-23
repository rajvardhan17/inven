import 'package:flutter/material.dart';
import '../../services/app_data.dart'; // 🔥 IMPORTANT

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();

  // 🔹 SAVE PRODUCT FUNCTION
  void saveProduct() {
    String name = nameController.text.trim();
    String price = priceController.text.trim();
    String quantity = quantityController.text.trim();

    // 🔴 VALIDATION
    if (name.isEmpty || price.isEmpty || quantity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    // 🔥 STORE DATA (GLOBAL)
    AppData.products.add({
      "name": name,
      "price": price,
      "quantity": quantity,
    });

    // DEBUG
    print(AppData.products);

    // ✅ SUCCESS MESSAGE
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Product Added Successfully")),
    );

    // 🔙 GO BACK
    Navigator.pop(context);
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      // 🔹 APP BAR
      appBar: AppBar(
        title: const Text("Add Product"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      // 🔹 BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // 🔹 TITLE
                const Text(
                  "Enter Product Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                // 🔹 NAME
                _buildTextField(
                  controller: nameController,
                  label: "Product Name",
                  icon: Icons.inventory,
                ),

                const SizedBox(height: 15),

                // 🔹 PRICE
                _buildTextField(
                  controller: priceController,
                  label: "Price",
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 15),

                // 🔹 QUANTITY
                _buildTextField(
                  controller: quantityController,
                  label: "Quantity",
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 30),

                // 🔹 BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "Save Product",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 REUSABLE TEXTFIELD
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}