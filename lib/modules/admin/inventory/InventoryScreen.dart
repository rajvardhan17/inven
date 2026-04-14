import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  final rawRef = FirebaseFirestore.instance.collection('raw_materials');
  final productRef = FirebaseFirestore.instance.collection('products');

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // 🔥 ADD ITEM (WITH VALIDATION)
  void showAddDialog(bool isRaw) {
    final name = TextEditingController();
    final qty = TextEditingController();
    final unit = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isRaw ? "Add Raw Material" : "Add Product"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
            TextField(
              controller: qty,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity"),
            ),
            if (isRaw)
              TextField(controller: unit, decoration: const InputDecoration(labelText: "Unit")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String itemName = name.text.trim();
              double quantity = double.tryParse(qty.text.trim()) ?? 0;

              if (itemName.isEmpty || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Enter valid data")),
                );
                return;
              }

              try {
                if (isRaw) {
                  await rawRef.add({
                    "name": itemName,
                    "qty": quantity,
                    "unit": unit.text.trim(),
                    "createdAt": Timestamp.now(),
                  });
                } else {
                  await productRef.add({
                    "name": itemName,
                    "qty": quantity.toInt(),
                    "createdAt": Timestamp.now(),
                  });
                }

                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  // 🔥 UPDATE QTY (SAFE)
  Future<void> updateQty(DocumentSnapshot doc, num newQty) async {
    if (newQty < 0) return;

    try {
      await doc.reference.update({"qty": newQty});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed")),
      );
    }
  }

  // 🔥 DELETE ITEM
  Future<void> deleteItem(DocumentSnapshot doc) async {
    await doc.reference.delete();
  }

  // 🔥 CARD UI (UPGRADED)
  Widget _card(DocumentSnapshot doc, bool isRaw) {
    var data = doc.data() as Map<String, dynamic>;

    String name = data['name'] ?? "";
    num qty = data['qty'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple.withOpacity(0.1),
            child: const Icon(Icons.inventory, color: Colors.deepPurple),
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
                Text(
                  isRaw
                      ? "${qty.toString()} ${data['unit'] ?? ''}"
                      : "Qty: $qty",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          Row(
            children: [
              IconButton(
                onPressed: () => updateQty(doc, qty - 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              IconButton(
                onPressed: () => updateQty(doc, qty + 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
              PopupMenuButton(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: "delete", child: Text("Delete")),
                ],
                onSelected: (value) {
                  if (value == "delete") {
                    deleteItem(doc);
                  }
                },
              )
            ],
          )
        ],
      ),
    );
  }

  // 🔥 STREAM LIST (OPTIMIZED)
  Widget _buildList(Stream<QuerySnapshot> stream, bool isRaw) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No data found"));
        }

        var docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, index) => _card(docs[index], isRaw),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Inventory"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Raw Materials"),
            Tab(text: "Products"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              _header("Raw Materials", true),
              Expanded(
                child: _buildList(
                  rawRef.orderBy('createdAt', descending: true).snapshots(),
                  true,
                ),
              ),
            ],
          ),
          Column(
            children: [
              _header("Products", false),
              Expanded(
                child: _buildList(
                  productRef.orderBy('createdAt', descending: true).snapshots(),
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 HEADER
  Widget _header(String title, bool isRaw) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ElevatedButton.icon(
            onPressed: () => showAddDialog(isRaw),
            icon: const Icon(Icons.add),
            label: const Text("Add"),
          ),
        ],
      ),
    );
  }
}