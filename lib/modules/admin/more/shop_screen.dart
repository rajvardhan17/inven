import 'package:flutter/material.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  List<Map<String, String>> shops = [
    {
      "name": "Sharma Store",
      "owner": "Mr. Sharma",
      "phone": "9876543210",
      "address": "Indore"
    }
  ];

  // 🔹 Add Shop Dialog
  void _showAddShopDialog() {
    TextEditingController name = TextEditingController();
    TextEditingController owner = TextEditingController();
    TextEditingController phone = TextEditingController();
    TextEditingController address = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Shop"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: "Shop Name"),
              ),
              TextField(
                controller: owner,
                decoration: const InputDecoration(labelText: "Owner Name"),
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: "Address"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                shops.add({
                  "name": name.text,
                  "owner": owner.text,
                  "phone": phone.text,
                  "address": address.text,
                });
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  // 🔹 Delete
  void _deleteShop(int index) {
    setState(() {
      shops.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Shops"),
      ),
      body: Column(
        children: [
          // 🔹 Add Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _showAddShopDialog,
                icon: const Icon(Icons.add),
                label: const Text("Add Shop"),
              ),
            ),
          ),

          // 🔹 List
          Expanded(
            child: ListView.builder(
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];

                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: const Icon(Icons.store, color: Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shop["name"]!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Owner: ${shop["owner"]}",
                                style: const TextStyle(color: Colors.grey)),
                            Text("📞 ${shop["phone"]}",
                                style: const TextStyle(color: Colors.grey)),
                            Text("📍 ${shop["address"]}",
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteShop(index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
