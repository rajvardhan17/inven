import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final rawRef = FirebaseFirestore.instance.collection('raw_materials');
  final productRef = FirebaseFirestore.instance.collection('products');

  bool showRaw = true;
  String searchQuery = "";

  // =========================
  // ADD PRODUCT (FULL FIELDS)
  // =========================
  void showAddDialog() {
    final name = TextEditingController();
    final fragrance = TextEditingController();
    final minStock = TextEditingController();
    final packaging = TextEditingController();
    final price = TextEditingController();
    final sticksPerBox = TextEditingController();
    final stock = TextEditingController();
    final type = TextEditingController();
    final weight = TextEditingController();

    bool isActive = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(showRaw ? "Add Raw Material" : "Add Product"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(name, "Name"),
                  if (!showRaw) _field(fragrance, "Fragrance"),
                  if (!showRaw) _field(type, "Type"),
                  if (!showRaw) _field(packaging, "Packaging"),

                  _numField(stock, "Stock"),
                  _numField(minStock, "Min Stock"),

                  if (!showRaw) _numField(price, "Price"),
                  if (!showRaw) _numField(sticksPerBox, "Sticks Per Box"),
                  if (!showRaw) _numField(weight, "Weight"),

                  if (!showRaw)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Active"),
                        Switch(
                          value: isActive,
                          onChanged: (v) => setState(() => isActive = v),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await (showRaw ? rawRef : productRef).add({
                    "name": name.text.trim(),
                    "fragrance": fragrance.text.trim(),
                    "type": type.text.trim(),
                    "packaging": packaging.text.trim(),

                    "price": double.tryParse(price.text) ?? 0,
                    "stock": int.tryParse(stock.text) ?? 0,
                    "qty": int.tryParse(stock.text) ?? 0,
                    "minStock": int.tryParse(minStock.text) ?? 0,
                    "sticksPerBox": int.tryParse(sticksPerBox.text) ?? 0,
                    "weight": int.tryParse(weight.text) ?? 0,

                    "isActive": isActive,
                    "createdAt": Timestamp.now(),
                  });

                  Navigator.pop(context);
                },
                child: const Text("Add"),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================
  // FIELDS
  // =========================
  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // =========================
  // LOGIC
  // =========================
  int getQty(Map<String, dynamic> data) {
    if (data['stock'] != null) return (data['stock'] as num).toInt();
    if (data['qty'] != null) return (data['qty'] as num).toInt();
    return 0;
  }

  Future<void> updateStock(DocumentSnapshot doc, int value) async {
    await doc.reference.update({
      "stock": value,
      "qty": value,
    });
  }

  // =========================
  // TOGGLE (NO HEADER)
  // =========================
  Widget _toggle() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => showRaw = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: showRaw ? Colors.indigo : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  "RAW",
                  style: TextStyle(
                    color: showRaw ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => showRaw = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !showRaw ? Colors.indigo : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  "PRODUCTS",
                  style: TextStyle(
                    color: !showRaw ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // SEARCH
  // =========================
  Widget _search() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: "Search...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // =========================
  // CARD
  // =========================
  Widget _card(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    String name = (data['name'] ?? "").toString();
    String unit = (data['unit'] ?? "").toString();

    int qty = getQty(data);
    int min = data['minStock'] ?? 0;

    bool low = qty <= min && qty > 0;
    bool out = qty <= 0;

    if (searchQuery.isNotEmpty &&
        !name.toLowerCase().contains(searchQuery)) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory, color: Colors.indigo),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Qty: $qty $unit"),
                if (low)
                  const Text("LOW STOCK",
                      style: TextStyle(color: Colors.orange)),
                if (out)
                  const Text("OUT OF STOCK",
                      style: TextStyle(color: Colors.red)),
              ],
            ),
          ),

          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => updateStock(doc, qty + 1),
              ),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => updateStock(doc, qty - 1),
              ),
            ],
          )
        ],
      ),
    );
  }

  // =========================
  // LIST
  // =========================
  Widget _list(Stream<QuerySnapshot> stream) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            _toggle(),
            _search(),
            const SizedBox(height: 8),
            ...docs.map((d) => _card(d)),
          ],
        );
      },
    );
  }

  // =========================
  // MAIN UI (NO APPBAR TITLE)
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: "inventory_fab", // FIX HERO CRASH
        onPressed: showAddDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),

      body: showRaw
          ? _list(rawRef.snapshots())
          : _list(productRef.snapshots()),
    );
  }
}