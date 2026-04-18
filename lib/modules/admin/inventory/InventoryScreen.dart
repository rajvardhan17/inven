import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  final rawRef     = FirebaseFirestore.instance.collection('raw_materials');
  final productRef = FirebaseFirestore.instance.collection('products');

  bool showRaw = true;
  String searchQuery = '';
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          setState(() => showRaw = _tabCtrl.index == 0);
        }
      });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────
  int getQty(Map<String, dynamic> data) {
    if (data['stock'] != null) return (data['stock'] as num).toInt();
    if (data['qty'] != null)   return (data['qty'] as num).toInt();
    return 0;
  }

  Future<void> updateStock(DocumentSnapshot doc, int value) async {
    if (value < 0) return;
    await doc.reference.update({'stock': value, 'qty': value});
  }

  // ── Add dialog ────────────────────────────────────────────
  void _showAddDialog() {
    final name         = TextEditingController();
    final fragrance    = TextEditingController();
    final minStock     = TextEditingController();
    final packaging    = TextEditingController();
    final price        = TextEditingController();
    final sticksPerBox = TextEditingController();
    final stock        = TextEditingController();
    final type         = TextEditingController();
    final weight       = TextEditingController();
    bool isActive = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, sc) => SingleChildScrollView(
              controller: sc,
              padding: EdgeInsets.fromLTRB(
                20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    showRaw ? "Add Raw Material" : "Add Product",
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Fill in the details below",
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _field(name, "Name", Icons.label_outline),
                  if (!showRaw) _field(fragrance, "Fragrance", Icons.air),
                  if (!showRaw) _field(type, "Type", Icons.category_outlined),
                  if (!showRaw) _field(packaging, "Packaging", Icons.inventory_outlined),
                  _numField(stock, "Stock Quantity", Icons.warehouse_outlined),
                  _numField(minStock, "Min Stock Alert", Icons.warning_amber_outlined),
                  if (!showRaw) _numField(price, "Price (₹)", Icons.currency_rupee),
                  if (!showRaw) _numField(sticksPerBox, "Sticks Per Box", Icons.grid_view_outlined),
                  if (!showRaw) _numField(weight, "Weight (g)", Icons.monitor_weight_outlined),
                  if (!showRaw) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface2,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.toggle_on_outlined, color: AppTheme.textSecondary, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(child: Text("Active", style: TextStyle(color: AppTheme.textPrimary))),
                          Switch.adaptive(
                            value: isActive,
                            activeColor: AppTheme.accent,
                            onChanged: (v) => setSheetState(() => isActive = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (name.text.trim().isEmpty) return;
                        await (showRaw ? rawRef : productRef).add({
                          'name':        name.text.trim(),
                          'fragrance':   fragrance.text.trim(),
                          'type':        type.text.trim(),
                          'packaging':   packaging.text.trim(),
                          'price':       double.tryParse(price.text) ?? 0,
                          'stock':       int.tryParse(stock.text) ?? 0,
                          'qty':         int.tryParse(stock.text) ?? 0,
                          'minStock':    int.tryParse(minStock.text) ?? 0,
                          'sticksPerBox':int.tryParse(sticksPerBox.text) ?? 0,
                          'weight':      int.tryParse(weight.text) ?? 0,
                          'isActive':    isActive,
                          'createdAt':   Timestamp.now(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Add to Inventory"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 18),
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 18),
        ),
      ),
    );
  }

  // ── Main build ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text("Inventory"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: AppTheme.border),
              TabBar(
                controller: _tabCtrl,
                labelColor: AppTheme.accent,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.accent,
                indicatorWeight: 2,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
                tabs: const [
                  Tab(text: "RAW MATERIALS"),
                  Tab(text: "PRODUCTS"),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "inventory_fab",
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: AppTheme.bg),
      ),
      body: Column(
        children: [
          _searchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _inventoryList(rawRef.orderBy('name').snapshots()),
                _inventoryList(productRef.orderBy('name').snapshots()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────
  Widget _searchBar() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: "Search inventory...",
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                  onPressed: () => setState(() => searchQuery = ''),
                )
              : null,
        ),
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────
  Widget _inventoryList(Stream<QuerySnapshot> stream) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const AppLoader();

        final docs = snapshot.data!.docs.where((doc) {
          final name = ((doc.data() as Map)['name'] ?? '').toString().toLowerCase();
          return searchQuery.isEmpty || name.contains(searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return AppEmptyState(
            icon: Icons.inventory_2_outlined,
            title: searchQuery.isNotEmpty ? "No results" : "Empty Inventory",
            subtitle: searchQuery.isNotEmpty
                ? "Try a different search term"
                : "Tap + to add items",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100, top: 8),
          itemCount: docs.length,
          itemBuilder: (_, i) => _inventoryCard(docs[i]),
        );
      },
    );
  }

  // ── Card ──────────────────────────────────────────────────
  Widget _inventoryCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = (data['name'] ?? '').toString();
    final unit = (data['unit'] ?? '').toString();
    final qty  = getQty(data);
    final min  = (data['minStock'] ?? 0) as int;
    final price = (data['price'] ?? 0).toDouble();

    final bool low = qty > 0 && qty <= min;
    final bool out = qty <= 0;

    Color statusColor = AppTheme.green;
    String statusLabel = 'In Stock';
    if (out) { statusColor = AppTheme.red; statusLabel = 'Out of Stock'; }
    else if (low) { statusColor = AppTheme.orange; statusLabel = 'Low Stock'; }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Icon(
              showRaw ? Icons.grain_outlined : Icons.inventory_2_outlined,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                )),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text("$qty ${unit.isEmpty ? 'units' : unit}",
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    if (price > 0) ...[
                      const Text("  ·  ", style: TextStyle(color: AppTheme.textMuted)),
                      Text("₹${price.toInt()}", style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel, style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  )),
                ),
              ],
            ),
          ),

          // Stepper
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _stepBtn(Icons.remove_rounded, () => updateStock(doc, qty - 1), qty <= 0),
                SizedBox(
                  width: 36,
                  child: Text(
                    "$qty",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                _stepBtn(Icons.add_rounded, () => updateStock(doc, qty + 1), false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, bool disabled) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon,
          color: disabled ? AppTheme.textMuted : AppTheme.textSecondary,
          size: 16,
        ),
      ),
    );
  }
}