import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/app_theme.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> with TickerProviderStateMixin {
  final db = FirebaseFirestore.instance;
  int selectedFilter = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final List<String> filters = ["All", "Today", "Week", "Month", "Year"];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  bool _matchFilter(Timestamp? timestamp) {
    if (selectedFilter == 0) return true;
    if (timestamp == null) return false;
    final date = timestamp.toDate();
    final now = DateTime.now();
    switch (selectedFilter) {
      case 1:
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case 2:
        return date.isAfter(now.subtract(const Duration(days: 7)));
      case 3:
        return date.year == now.year && date.month == now.month;
      case 4:
        return date.year == now.year;
      default:
        return true;
    }
  }

  List<Map<String, dynamic>> _parseItems(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (raw is Map) return raw.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: RefreshIndicator(
            color: AppTheme.accent,
            backgroundColor: AppTheme.surface,
            onRefresh: () async {
              _fadeCtrl.reset();
              setState(() {});
              _fadeCtrl.forward();
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header()),
                SliverToBoxAdapter(child: _filters()),
                SliverToBoxAdapter(child: _kpiSection()),
                SliverToBoxAdapter(child: _salesChartSection()),
                SliverToBoxAdapter(child: _recentOrders()),
                SliverToBoxAdapter(child: _quickActions()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────
  Widget _header() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
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
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppTheme.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text("LIVE", style: TextStyle(
                      color: AppTheme.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                const Text("Dashboard", style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.1,
                )),
                const SizedBox(height: 4),
                const Text("Business Insights", style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                )),
              ],
            ),
          ),
          Row(
            children: [
              _iconBtn(Icons.dark_mode_outlined),
              const SizedBox(width: 8),
              _iconBtn(Icons.notifications_outlined),
            ],
          )
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.border),
      ),
      child: Icon(icon, color: AppTheme.textSecondary, size: 20),
    );
  }

  // ─── FILTERS ──────────────────────────────────────────────
  Widget _filters() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final sel = selectedFilter == i;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: sel ? AppTheme.accentGrad : null,
                color: sel ? null : AppTheme.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: sel ? Colors.transparent : AppTheme.border,
                ),
                boxShadow: sel ? AppTheme.accentShadow : null,
              ),
              child: Text(
                filters[i],
                style: TextStyle(
                  color: sel ? AppTheme.bg : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── KPI GRID ─────────────────────────────────────────────
  Widget _kpiSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 200, child: AppLoader());
        }

        final docs = snapshot.data!.docs;
        int total = 0, pending = 0, packed = 0, delivered = 0, undelivered = 0;
        double revenue = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (!_matchFilter(data['createdAt'])) continue;
          total++;
          final status = (data['status'] ?? '').toLowerCase();
          final payment = (data['paymentStatus'] ?? '').toLowerCase();
          final amount = data['totalAmount'];
          final double amt = amount is int ? amount.toDouble() : (amount ?? 0.0);
          if (status == 'pending') pending++;
          if (status == 'packed') packed++;
          if (status == 'delivered') delivered++;
          if (status == 'pending' || status == 'packed') undelivered++;
          if (payment == 'paid') revenue += amt;
        }

        final kpis = [
          _KpiData("Orders", "$total", Icons.shopping_bag_outlined, AppTheme.blue, AppTheme.blueSoft),
          _KpiData("Revenue", "₹${revenue.toInt()}", Icons.currency_rupee_rounded, AppTheme.accent, AppTheme.accentSoft),
          _KpiData("Pending", "$pending", Icons.hourglass_top_rounded, AppTheme.orange, AppTheme.orangeSoft),
          _KpiData("Packed", "$packed", Icons.inventory_2_outlined, AppTheme.purple, AppTheme.purpleSoft),
          _KpiData("Delivered", "$delivered", Icons.check_circle_outline, AppTheme.green, AppTheme.greenSoft),
          _KpiData("Undelivered", "$undelivered", Icons.cancel_outlined, AppTheme.red, AppTheme.redSoft),
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: kpis.map((k) => _kpiCard(k)).toList(),
          ),
        );
      },
    );
  }

  Widget _kpiCard(_KpiData k) {
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: k.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(k.icon, color: k.color, size: 16),
          ),
          const Spacer(),
          Text(k.value, style: TextStyle(
            color: k.color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          )),
          const SizedBox(height: 2),
          Text(k.label, style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          )),
        ],
      ),
    );
  }

  // ─── SALES CHART ──────────────────────────────────────────
  Widget _salesChartSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('orders').orderBy('createdAt').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 200, child: AppLoader());
        }

        final docs = snapshot.data!.docs;
        List<FlSpot> spots = [];
        int idx = 0;
        double maxY = 1;

        for (var doc in docs.take(10)) {
          final data = doc.data() as Map<String, dynamic>;
          if (!_matchFilter(data['createdAt'])) continue;
          final amount = data['totalAmount'];
          final double value = amount is int ? amount.toDouble() : (amount ?? 0.0);
          spots.add(FlSpot(idx.toDouble(), value));
          if (value > maxY) maxY = value;
          idx++;
        }

        if (spots.isEmpty) spots = [const FlSpot(0, 0), const FlSpot(1, 0)];

        return AppCard(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Sales Analytics", style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        )),
                        SizedBox(height: 2),
                        Text("Revenue over time", style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        )),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("LIVE", style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY * 1.3,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 3,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppTheme.border,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (group) => AppTheme.surface2,
                        tooltipBorder: const BorderSide(color: AppTheme.border),
                        getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                          "₹${s.y.toInt()}",
                          const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
                        )).toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        curveSmoothness: 0.4,
                        spots: spots,
                        dotData: const FlDotData(show: false),
                        color: AppTheme.accent,
                        barWidth: 2.5,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accent.withOpacity(0.25),
                              AppTheme.accent.withOpacity(0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── RECENT ORDERS ────────────────────────────────────────
  Widget _recentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "Recent Orders",
          subtitle: "Latest 5 transactions",
        ),
        StreamBuilder<QuerySnapshot>(
          stream: db.collection('orders')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const AppLoader();

            final docs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _matchFilter(data['createdAt']);
            }).toList();

            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: AppEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: "No Orders",
                  subtitle: "Orders will appear here",
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'pending';
                final items = _parseItems(data['items']);
                final products = items
                    .take(2)
                    .map((e) => "${e['productName'] ?? 'Item'} ×${e['qty'] ?? 0}")
                    .join(", ");
                final amount = (data['totalAmount'] ?? 0).toDouble();

                return AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.store_outlined, color: AppTheme.textSecondary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['shopName'] ?? 'Shop', style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            )),
                            const SizedBox(height: 3),
                            Text(products.isEmpty ? 'No items' : products,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("₹${amount.toInt()}", style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          )),
                          const SizedBox(height: 4),
                          StatusBadge.fromStatus(status),
                        ],
                      ),
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

  // ─── QUICK ACTIONS ────────────────────────────────────────
  Widget _quickActions() {
    final actions = [
      _ActionData(Icons.add_circle_outline, "New Order", AppTheme.accent),
      _ActionData(Icons.store_outlined, "Shops", AppTheme.blue),
      _ActionData(Icons.receipt_outlined, "Orders", AppTheme.purple),
      _ActionData(Icons.people_outline, "Users", AppTheme.green),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Quick Actions"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: actions.map((a) => _actionBtn(a)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn(_ActionData a) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: a.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: a.color.withOpacity(0.3)),
          ),
          child: Icon(a.icon, color: a.color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(a.label, style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        )),
      ],
    );
  }
}

class _KpiData {
  final String label, value;
  final IconData icon;
  final Color color, bgColor;
  _KpiData(this.label, this.value, this.icon, this.color, this.bgColor);
}

class _ActionData {
  final IconData icon;
  final String label;
  final Color color;
  _ActionData(this.icon, this.label, this.color);
}