import 'package:flutter/material.dart';
import '../production/production_screen.dart';

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

  Map<String, Map<String, double>> recipe = {
    "Rose Agarbatti": {
      "Wood Powder": 0.7,
      "Perfume": 0.1,
    },
    "Sandal Agarbatti": {
      "Wood Powder": 0.6,
      "Perfume": 0.2,
    },
  };

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  // 🔹 Add Dialog
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
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: "Name")),
            TextField(
                controller: qty,
                decoration: const InputDecoration(labelText: "Quantity")),
            if (isRaw)
              TextField(
                  controller: unit,
                  decoration: const InputDecoration(labelText: "Unit")),
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

  // 🔹 Edit Quantity Dialog
  void _editQtyDialog(int index, bool isRaw) {
    TextEditingController controller = TextEditingController();

    controller.text = isRaw
        ? rawMaterials[index]["qty"].toString()
        : products[index]["qty"].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Quantity"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (isRaw) {
                  rawMaterials[index]["qty"] = double.parse(controller.text);
                } else {
                  products[index]["qty"] = int.parse(controller.text);
                }
              });
              Navigator.pop(context);
            },
            child: const Text("Update"),
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

      // ❌ NO FLOATING BUTTON HERE

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

              return _cardEditable(
                name: item["name"],
                subtitle: "${item["qty"]} ${item["unit"]}",
                color: Colors.blue,
                onAdd: () {
                  setState(() => item["qty"] += 1);
                },
                onRemove: () {
                  setState(() {
                    if (item["qty"] > 0) item["qty"] -= 1;
                  });
                },
                onEdit: () => _editQtyDialog(index, true),
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

              return _cardEditable(
                name: item["name"],
                subtitle: "Qty: ${item["qty"]}",
                color: Colors.green,
                onAdd: () {
                  setState(() => item["qty"] += 1);
                },
                onRemove: () {
                  setState(() {
                    if (item["qty"] > 0) item["qty"] -= 1;
                  });
                },
                onEdit: () => _editQtyDialog(index, false),
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
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Row(
            children: [
              // 🔥 PRODUCE BUTTON (only for products)
              if (!isRaw)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductionScreen(
                            rawMaterials: rawMaterials,
                            products: products,
                            recipe: recipe,
                          ),
                        ),
                      ).then((_) {
                        setState(() {}); // 🔥 refresh after production
                      });
                    },
                    child: const Text("Produce"),
                  ),
                ),

              ElevatedButton.icon(
                onPressed: () => showAddDialog(isRaw),
                icon: const Icon(Icons.add),
                label: const Text("Add"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Editable Card UI
  Widget _cardEditable({
    required String name,
    required String subtitle,
    required Color color,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
    required VoidCallback onEdit,
  }) {
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
          Row(
            children: [
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, color: Colors.blue),
              ),
            ],
          )
        ],
      ),
    );
  }
}
