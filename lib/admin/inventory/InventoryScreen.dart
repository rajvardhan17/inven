import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("Inventory"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 SEARCH BAR
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search products...",
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🧱 GRID CARDS
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, // 🔥 2 cards per row
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9, // controls height
                children: const [
                  ProductCard(
                    name: "Agarbatti",
                    price: "₹120",
                    quantity: "50 pcs",
                  ),
                  ProductCard(
                    name: "Sandal Oil",
                    price: "₹80",
                    quantity: "30 pcs",
                  ),
                  ProductCard(
                    name: "Rose Perfume",
                    price: "₹200",
                    quantity: "20 pcs",
                  ),
                  ProductCard(
                    name: "Lavender Oil",
                    price: "₹150",
                    quantity: "25 pcs",
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

// 🔥 CARD UI (MODERN)
class ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String quantity;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🔹 TOP ICON
          Align(
            alignment: Alignment.topRight,
            child: Icon(Icons.delete_outline, color: Colors.red.shade400),
          ),

          Column(
            children: [
              // 🔹 PRODUCT ICON
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory,
                  size: 28,
                  color: Colors.deepPurple,
                ),
              ),

              const SizedBox(height: 10),

              // 🔹 NAME
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 6),

              // 🔹 QUANTITY
              Text(
                "Qty: $quantity",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),

          // 🔹 PRICE
          Text(
            price,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
