import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';

class SalesmanShopsScreen extends StatefulWidget {
  final String uid;
  const SalesmanShopsScreen({super.key, required this.uid});

  @override
  State<SalesmanShopsScreen> createState() => _SalesmanShopsScreenState();
}

class _SalesmanShopsScreenState extends State<SalesmanShopsScreen> {
  final db = FirebaseFirestore.instance;
  String search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text("My Shops"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.bg,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text("Add Shop", style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          _searchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('shops')
                  .where('assignedSalesmanId', isEqualTo: widget.uid)
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) return const AppLoader();

                final docs = snap.data!.docs.where((d) {
                  final name = ((d.data() as Map)['shopName'] ?? '')
                      .toString()
                      .toLowerCase();
                  return search.isEmpty || name.contains(search);
                }).toList();

                if (docs.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.storefront_outlined,
                    title: "No Shops Yet",
                    subtitle: "Tap + to add your first shop",
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100, top: 8),
                  itemCount: docs.length,
                  itemBuilder: (_, i) => _shopCard(context, docs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        onChanged: (v) => setState(() => search = v.toLowerCase()),
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: "Search shops...",
          prefixIcon:
              const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
          suffixIcon: search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      color: AppTheme.textSecondary, size: 18),
                  onPressed: () => setState(() => search = ''))
              : null,
        ),
      ),
    );
  }

  Widget _shopCard(BuildContext context, DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final name = d['shopName'] ?? 'Unknown';
    final owner = d['ownerName'] ?? '—';
    final phone = d['phone'] ?? '—';

    final addressMap = d['address'] ?? {};
    final street = addressMap['street'] ?? '';
    final city = addressMap['City'] ?? ''; // ✅ FIX
    final pincode = addressMap['pincode'] ?? '';

    final fullAddress =
        "$street${city.isNotEmpty ? ', $city' : ''}${pincode.isNotEmpty ? ' - $pincode' : ''}";

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGrad,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                      color: AppTheme.bg,
                      fontSize: 20,
                      fontWeight: FontWeight.w900),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(owner,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              )),
              GestureDetector(
                onTap: () => _showEditSheet(context, doc),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: AppTheme.textSecondary, size: 16),
                ),
              ),
            ],
          ),
          const AccentDivider(),
          _infoRow(Icons.phone_outlined, phone),
          const SizedBox(height: 6),
          _infoRow(Icons.location_on_outlined, fullAddress),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 14),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg))),
      builder: (_) => AddShopSheet(uid: widget.uid),
    );
  }

  void _showEditSheet(BuildContext context, DocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg))),
      builder: (_) => EditShopSheet(doc: doc),
    );
  }
}

// ── Add Shop ─────────────────────────
class AddShopSheet extends StatelessWidget {
  final String uid;
  AddShopSheet({super.key, required this.uid});

  final shopName = TextEditingController();
  final ownerName = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final area = TextEditingController();
  final gst = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return _ShopForm(
      title: "Add New Shop",
      shopName: shopName,
      ownerName: ownerName,
      phone: phone,
      address: address,
      area: area,
      gst: gst,
      onSave: () async {
        if (shopName.text.trim().isEmpty) return;

        await FirebaseFirestore.instance.collection('shops').add({
          'shopName': shopName.text.trim(),
          'ownerName': ownerName.text.trim(),
          'phone': phone.text.trim(),
          'address': {
            'street': address.text.trim(),
            'City': area.text.trim(), // ✅ FIX
            'pincode': '',
          },
          'gst': gst.text.trim(),
          'assignedSalesmanId': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}

// ── Edit Shop ─────────────────────────
class EditShopSheet extends StatelessWidget {
  final DocumentSnapshot doc;
  EditShopSheet({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final addressMap = d['address'] ?? {};

    final shopName =
        TextEditingController(text: d['shopName'] ?? '');
    final ownerName =
        TextEditingController(text: d['ownerName'] ?? '');
    final phone =
        TextEditingController(text: d['phone'] ?? '');
    final address =
        TextEditingController(text: addressMap['street'] ?? '');
    final area =
        TextEditingController(text: addressMap['City'] ?? '');
    final gst =
        TextEditingController(text: d['gst'] ?? '');

    return _ShopForm(
      title: "Edit Shop",
      shopName: shopName,
      ownerName: ownerName,
      phone: phone,
      address: address,
      area: area,
      gst: gst,
      onSave: () async {
        await doc.reference.update({
          'shopName': shopName.text.trim(),
          'ownerName': ownerName.text.trim(),
          'phone': phone.text.trim(),
          'address': {
            'street': address.text.trim(),
            'City': area.text.trim(),
            'pincode': '',
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}

// ── FORM (MAIN FIX) ─────────────────────────
class _ShopForm extends StatelessWidget {
  final String title;
  final TextEditingController shopName, ownerName, phone, address, area, gst;
  final VoidCallback onSave;

  const _ShopForm({
    required this.title,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.area,
    required this.gst,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      expand: false,
      builder: (_, sc) => SingleChildScrollView(
        controller: sc,
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          children: [
            _f(shopName, "Shop Name", Icons.storefront_outlined),
            _f(ownerName, "Owner Name", Icons.person_outline_rounded),
            _f(phone, "Phone", Icons.phone_outlined),
            _f(address, "Street", Icons.location_on_outlined),
            _f(area, "City", Icons.map_outlined),
            _f(gst, "GST", Icons.receipt),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: onSave,
              child: Text(title),
            ),
          ],
        ),
      ),
    );
  }

  Widget _f(TextEditingController c, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}