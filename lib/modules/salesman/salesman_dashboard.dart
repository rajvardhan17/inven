import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/app_theme.dart';
import 'salesman_shops.dart';
import 'salesman_create_order.dart';

class SalesmanDashboard extends StatefulWidget {
  final String uid;
  const SalesmanDashboard({super.key, required this.uid});

  @override
  State<SalesmanDashboard> createState() => _SalesmanDashboardState();
}

class _SalesmanDashboardState extends State<SalesmanDashboard>
    with TickerProviderStateMixin {
  final db = FirebaseFirestore.instance;
  int filterIdx = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final filters = ['Today', 'Week', 'Month'];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  bool _matchFilter(Timestamp? ts) {
    if (ts == null) return false;
    final date = ts.toDate();
    final now = DateTime.now();
    switch (filterIdx) {
      case 0: return date.year == now.year && date.month == now.month && date.day == now.day;
      case 1: return date.isAfter(now.subtract(const Duration(days: 7)));
      case 2: return date.year == now.year && date.month == now.month;
      default: return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _filterRow()),
              SliverToBoxAdapter(child: _kpiGrid()),
              SliverToBoxAdapter(child: _quickActions(context)),
              SliverToBoxAdapter(child: _recentActivity()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _header() {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.collection('users').doc(widget.uid).snapshots(),
      builder: (_, snap) {
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] ?? 'Salesman';
        final hour = DateTime.now().hour;
        final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1E2E), Color(0xFF1E2436)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(name, style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    )),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text("SALESMAN", style: TextStyle(
                        color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGrad,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.accentShadow,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      color: AppTheme.bg, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Filter Row ────────────────────────────────────────────
  Widget _filterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: List.generate(filters.length, (i) {
          final sel = filterIdx == i;
          return GestureDetector(
            onTap: () => setState(() => filterIdx = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                gradient: sel ? AppTheme.accentGrad : null,
                color: sel ? null : AppTheme.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: sel ? Colors.transparent : AppTheme.border),
                boxShadow: sel ? AppTheme.accentShadow : null,
              ),
              child: Text(filters[i], style: TextStyle(
                color: sel ? AppTheme.bg : AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              )),
            ),
          );
        }),
      ),
    );
  }

  // ── KPI Grid ──────────────────────────────────────────────
  Widget _kpiGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('orders')
          .where('salesmanId', isEqualTo: widget.uid)
          .snapshots(),
      builder: (_, orderSnap) {
        // Show loader until orders data arrives
        if (!orderSnap.hasData) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(height: 160, child: Center(child: AppLoader())),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          // shops use 'assignedSalesmanId' — matches AddShopSheet
          stream: db.collection('shops')
              .where('assignedSalesmanId', isEqualTo: widget.uid)
              .snapshots(),
          builder: (_, shopSnap) {
            // Render with 0 shops until shop data arrives (no extra loader needed)
            int shops = shopSnap.data?.docs.length ?? 0;
            int orders = 0;
            int pending = 0;
            double revenue = 0;

            for (var doc in orderSnap.data!.docs) {
  final data = doc.data() as Map<String, dynamic>;

  // ✅ FIX 1: safer timestamp handling
  final ts = data['createdAt'];
  if (ts is! Timestamp) continue;

  // ⚠️ TEMP DEBUG: comment this to verify data
  // if (!_matchFilter(ts)) continue;

  orders++;

  final status = (data['status'] ?? '').toString().toLowerCase();
  final payment = (data['paymentStatus'] ?? '').toString().toLowerCase();

  // ✅ FIX 2: correct pending logic
  if (status == 'pending' || status == 'packed' || status == 'processing') {
    pending++;
  }

  // ✅ FIX 3: SAFE revenue calculation
  if (payment == 'paid') {
    final amt = data['totalAmount'];
    if (amt != null) {
      revenue += (amt as num).toDouble(); // 🔥 THIS IS THE REAL FIX
    }
  }
}

            final kpis = [
              _KD("Shops",   "$shops",              Icons.storefront_outlined,   AppTheme.blue,   AppTheme.blueSoft),
              _KD("Orders",  "$orders",             Icons.receipt_outlined,      AppTheme.accent, AppTheme.accentSoft),
              _KD("Pending", "$pending",            Icons.hourglass_top_rounded, AppTheme.orange, AppTheme.orangeSoft),
              _KD("Revenue", "₹${revenue.toInt()}", Icons.currency_rupee,        AppTheme.green,  AppTheme.greenSoft),
            ];

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: kpis.map((k) => _kpiCard(k)).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _kpiCard(_KD k) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: k.bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(k.icon, color: k.color, size: 15),
          ),
          const Spacer(),
          Text(k.value, style: TextStyle(
            color: k.color, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(k.label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────
  Widget _quickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _actionBtn(
              icon: Icons.add_business_outlined,
              label: "Add Shop",
              color: AppTheme.blue,
              onTap: () => _goAddShop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionBtn(
              icon: Icons.post_add_outlined,
              label: "New Order",
              color: AppTheme.accent,
              onTap: () => _goCreateOrder(context),
              primary: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: primary ? AppTheme.accentGrad : null,
          color: primary ? null : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: primary ? Colors.transparent : AppTheme.border),
          boxShadow: primary ? AppTheme.accentShadow : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, color: primary ? AppTheme.bg : color, size: 20),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(
              color: primary ? AppTheme.bg : AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            )),
          ],
        ),
      ),
    );
  }

  // ── Recent Activity ───────────────────────────────────────
  Widget _recentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Recent Orders", subtitle: "Your latest activity"),
        StreamBuilder<QuerySnapshot>(
          // ✅ No orderBy — avoids composite index requirement.
          // We filter & sort client-side so no Firestore index is needed.
          stream: db.collection('orders')
              .where('salesmanId', isEqualTo: widget.uid)
              .snapshots(),
          builder: (_, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Error: ${snap.error}",
                    style: const TextStyle(color: AppTheme.red, fontSize: 12)),
              );
            }
            if (!snap.hasData) return const AppLoader();

            // Sort client-side by createdAt descending, take 5
            final docs = snap.data!.docs.toList()
              ..sort((a, b) {
                final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
                final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
                if (aTs == null && bTs == null) return 0;
                if (aTs == null) return 1;
                if (bTs == null) return -1;
                return bTs.compareTo(aTs);
              });
            final recent = docs.take(5).toList();

            if (recent.isEmpty) {
              return const AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: "No Orders Yet",
                subtitle: "Create your first order",
              );
            }

            return Column(
              children: recent.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final status = d['status'] ?? 'pending';
                final amt = (d['totalAmount'] ?? 0).toDouble();
                return AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.store_outlined,
                            color: AppTheme.textSecondary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['shopName'] ?? '—', style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                          const SizedBox(height: 3),
                          Text("₹${amt.toInt()}", style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      )),
                      StatusBadge.fromStatus(status),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _goAddShop(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg))),
      builder: (_) => AddShopSheet(uid: widget.uid),
    );
  }

  void _goCreateOrder(BuildContext context) async {
    final productSnap = await db.collection('products').get();
    // ✅ Use 'assignedSalesmanId' — matches the field set by AddShopSheet
    final shopSnap = await db.collection('shops')
        .where('assignedSalesmanId', isEqualTo: widget.uid).get();
    final products = productSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    final shops    = shopSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SalesmanCreateOrder(uid: widget.uid, shops: shops, products: products),
    ));
  }
}

class _KD {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  _KD(this.label, this.value, this.icon, this.color, this.bg);
}