import 'package:flutter/material.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> rawMaterials = [
    {"name": "Wood Powder", "qty": 50.0, "unit": "kg"},
    {"name": "Perfume", "qty": 20.0, "unit": "L"},
  ];

  List<Map<String, dynamic>> products = [
    {"name": "Rose Agarbatti", "qty": 100},
    {"name": "Sandal Agarbatti", "qty": 80},
  ];

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  // 🔹 Dialog
  void showAddDialog(bool isRaw) {
    TextEditingController name = TextEditingController();
    TextEditingController qty = TextEditingController();
    TextEditingController unit = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isRaw ? "Add Raw Material" : "Add Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: qty, decoration: const InputDecoration(labelText: "Quantity")),
            if (isRaw)
              TextField(controller: unit, decoration: const InputDecoration(labelText: "Unit")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (isRaw) {
                  rawMaterials.add({
                    "name": name.text,
                    "qty": double.parse(qty.text),
                    "unit": unit.text
                  });
                } else {
                  products.add({
                    "name": name.text,
                    "qty": int.parse(qty.text),
                  });
                }
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("Inventory"),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Raw Material"),
            Tab(text: "Products"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRawMaterial(),
          _buildProducts(),
        ],
      ),
    );
  }

  // 🔹 RAW MATERIAL UI
  Widget _buildRawMaterial() {
    return Column(
      children: [
        _sectionHeader("Raw Materials", true),
        Expanded(
          child: ListView.builder(
            itemCount: rawMaterials.length,
            itemBuilder: (context, index) {
              final item = rawMaterials[index];
              return _card(
                item["name"],
                "${item["qty"]} ${item["unit"]}",
                Colors.blue,
              );
            },
          ),
        ),
      ],
    );
  }

  // 🔹 PRODUCTS UI
  Widget _buildProducts() {
    return Column(
      children: [
        _sectionHeader("Finished Products", false),
        Expanded(
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final item = products[index];
              return _card(
                item["name"],
                "Qty: ${item["qty"]}",
                Colors.green,
              );
            },
          ),
        ),
      ],
    );
  }

  // 🔹 Header
  Widget _sectionHeader(String title, bool isRaw) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ElevatedButton.icon(
            onPressed: () => showAddDialog(isRaw),
            icon: const Icon(Icons.add),
            label: const Text("Add"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )
        ],
      ),
    );
  }

  // 🔹 Card UI
  Widget _card(String name, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(Icons.inventory, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}