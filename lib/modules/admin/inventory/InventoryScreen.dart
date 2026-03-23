import 'package:flutter/material.dart';
import '../production/production_screen.dart';
import '../../../data/inventory_data.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Recipe for production
  final Map<String, Map<String, double>> recipe = {
    "Rose Agarbatti": {"Wood Powder": 0.7, "Perfume": 0.1},
    "Sandal Agarbatti": {"Wood Powder": 0.6, "Perfume": 0.2},
  };

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  // 🔹 Add Raw Material / Product
  void showAddDialog(bool isRaw) {
    final TextEditingController name = TextEditingController();
    final TextEditingController qty = TextEditingController();
    final TextEditingController unit = TextEditingController();

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
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number),
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
                  InventoryData.rawMaterials.add({
                    "name": name.text,
                    "qty": double.tryParse(qty.text) ?? 0,
                    "unit": unit.text,
                  });
                } else {
                  InventoryData.products.add({
                    "name": name.text,
                    "qty": int.tryParse(qty.text) ?? 0,
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
    final TextEditingController controller = TextEditingController();
    final item = isRaw
        ? InventoryData.rawMaterials[index]
        : InventoryData.products[index];

    controller.text = isRaw ? item["qty"].toString() : item["qty"].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Quantity"),
        content: TextField(
            controller: controller, keyboardType: TextInputType.number),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (isRaw) {
                  item["qty"] = double.tryParse(controller.text) ?? item["qty"];
                } else {
                  item["qty"] = int.tryParse(controller.text) ?? item["qty"];
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRawMaterialTab(),
          _buildProductsTab(),
        ],
      ),
    );
  }

  // 🔹 Raw Material Tab
  Widget _buildRawMaterialTab() {
    final rawMaterials = InventoryData.rawMaterials;

    return Column(
      children: [
        _sectionHeader("Raw Materials", true),
        Expanded(
          child: ListView.builder(
            itemCount: rawMaterials.length,
            itemBuilder: (_, index) {
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

  // 🔹 Products Tab
  Widget _buildProductsTab() {
    final products = InventoryData.products;

    return Column(
      children: [
        _sectionHeader("Finished Products", false),
        Expanded(
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (_, index) {
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

  // 🔹 Section Header
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
              // 🔹 Produce Button (Products Only)
              if (!isRaw)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductionScreen(
                            rawMaterials: InventoryData.rawMaterials,
                            products: InventoryData.products,
                            recipe: recipe,
                          ),
                        ),
                      ).then((_) {
                        setState(() {}); // refresh after production
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

  // 🔹 Editable Card Widget
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
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
                  icon: const Icon(Icons.remove_circle_outline)),
              IconButton(
                  onPressed: onAdd, icon: const Icon(Icons.add_circle_outline)),
              IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, color: Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }
}
