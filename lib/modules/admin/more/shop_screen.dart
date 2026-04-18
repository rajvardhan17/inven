import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/app_theme.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  String searchQuery = "";

  /// 🔹 INPUT FIELD
  Widget _input(TextEditingController c, String label,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        keyboardType: type,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          filled: true,
          fillColor: AppTheme.surface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.border),
          ),
        ),
      ),
    );
  }

  /// 🔹 ADD SHOP
  void _showAddShopDialog() {
    TextEditingController name = TextEditingController();
    TextEditingController owner = TextEditingController();
    TextEditingController phone = TextEditingController();
    TextEditingController street = TextEditingController();
    TextEditingController city = TextEditingController();
    TextEditingController pincode = TextEditingController();
    TextEditingController creditLimit = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add Shop",
            style: TextStyle(color: AppTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _input(name, "Shop Name"),
              _input(owner, "Owner Name"),
              _input(phone, "Phone", type: TextInputType.phone),

              const SizedBox(height: 10),

              _input(street, "Street"),
              _input(city, "City"),
              _input(pincode, "Pincode", type: TextInputType.number),

              const SizedBox(height: 10),

              _input(creditLimit, "Credit Limit",
                  type: TextInputType.number),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('shops').add({
                "shopName": name.text.trim(),
                "ownerName": owner.text.trim(),
                "phone": phone.text.trim(),
                "address": {
                  "street": street.text.trim(),
                  "city": city.text.trim(),
                  "pincode": pincode.text.trim(),
                },
                "balance": 0,
                "creditLimit": double.tryParse(creditLimit.text) ?? 0,
                "isActive": true,
                "createdAt": Timestamp.now(),
                "createdBy": "ADMIN_ID",
              });

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
            ),
            child: const Text("Add Shop"),
          )
        ],
      ),
    );
  }

  /// 🔹 TOGGLE STATUS
  Future<void> _toggleStatus(String id, bool currentStatus) async {
    await FirebaseFirestore.instance
        .collection('shops')
        .doc(id)
        .update({
      "isActive": !currentStatus,
    });
  }

  /// 🔹 DELETE SHOP
  void _deleteShop(String id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Delete Shop",
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          "Are you sure you want to delete this shop?",
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete",
                  style: TextStyle(color: AppTheme.red))),
        ],
      ),
    );

    if (confirm == true) {
      FirebaseFirestore.instance.collection('shops').doc(id).delete();
    }
  }

  /// 🔍 FILTER
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filter(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> list) {
    return list.where((doc) {
      String name =
          (doc.data()['shopName'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,

      /// ➕ ADD BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accent,
        onPressed: _showAddShopDialog,
        child: const Icon(Icons.add),
      ),

      body: SafeArea(
        child: Column(
          children: [
            /// 🔥 HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppTheme.accentGrad,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: AppTheme.bg),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Shops",
                        style: TextStyle(
                            color: AppTheme.bg,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// 🔍 SEARCH
                  TextField(
                    style: const TextStyle(color: AppTheme.textPrimary),
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search shop...",
                      hintStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// 🔥 SHOP LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('shops')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  var shops = _filter(snapshot.data!.docs);

                  if (shops.isEmpty) {
                    return const Center(
                      child: Text("No shops found",
                          style: TextStyle(
                              color: AppTheme.textSecondary)),
                    );
                  }

                  return ListView.builder(
                    itemCount: shops.length,
                    itemBuilder: (context, index) {
                      var shopDoc = shops[index];
                      String id = shopDoc.id;
                      var data = shopDoc.data();

                      String addressText = "";

                      if (data['address'] is Map) {
                        var address =
                            data['address'] as Map<String, dynamic>;

                        String street = address['street'] ?? '';
                        String city = address['city'] ?? '';
                        String pincode = address['pincode'] ?? '';

                        addressText = "$street, $city - $pincode";
                      } else if (data['address'] is String) {
                        addressText = data['address'];
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      AppTheme.accentSoft,
                                  child: const Icon(Icons.store,
                                      color: AppTheme.accent),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['shopName'] ?? '',
                                        style: const TextStyle(
                                            color:
                                                AppTheme.textPrimary,
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Owner: ${data['ownerName'] ?? ''}",
                                        style: const TextStyle(
                                            color:
                                                AppTheme.textSecondary),
                                      ),
                                      Text(
                                        "📞 ${data['phone'] ?? ''}",
                                        style: const TextStyle(
                                            color:
                                                AppTheme.textSecondary),
                                      ),
                                      Text(
                                        "📍 $addressText",
                                        style: const TextStyle(
                                            color:
                                                AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),

                                IconButton(
                                  onPressed: () => _deleteShop(id),
                                  icon: const Icon(Icons.delete,
                                      color: AppTheme.red),
                                )
                              ],
                            ),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "₹${data['balance'] ?? 0}",
                                      style: const TextStyle(
                                          color: AppTheme.red,
                                          fontWeight:
                                              FontWeight.bold),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "/ ₹${data['creditLimit'] ?? 0}",
                                      style: const TextStyle(
                                          color:
                                              AppTheme.accent),
                                    ),
                                  ],
                                ),

                                Row(
                                  children: [
                                    Text(
                                      (data['isActive'] ?? false)
                                          ? "Active"
                                          : "Inactive",
                                      style: TextStyle(
                                        color: (data['isActive'] ?? false)
                                            ? AppTheme.accent
                                            : AppTheme.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value:
                                          data['isActive'] ?? false,
                                      activeColor:
                                          AppTheme.accent,
                                      onChanged: (value) {
                                        _toggleStatus(id,
                                            data['isActive'] ?? false);
                                      },
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}