import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final db = FirebaseFirestore.instance;

  int selectedFilter = -1;

  final List<String> filters = ["All", "Today", "Week", "Month", "Year"];

  // 🔥 FILTER LOGIC
  bool _matchFilter(Timestamp? timestamp) {
    if (selectedFilter == -1 || selectedFilter == 0) return true;
    if (timestamp == null) return false;

    final date = timestamp.toDate();
    final now = DateTime.now();

    switch (selectedFilter) {
      case 1:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

      case 2:
        final weekAgo = now.subtract(const Duration(days: 7));
        return date.isAfter(weekAgo);

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

    if (raw is List) {
      return raw.whereType<Map>().map((e) {
        return Map<String, dynamic>.from(e);
      }).toList();
    }

    if (raw is Map) {
      return raw.values.whereType<Map>().map((e) {
        return Map<String, dynamic>.from(e);
      }).toList();
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            children: [
              _header(),
              _filters(),

              // ⭐ NEW: SALES CHART ADDED (ERP ANALYTICS)
              _salesChartSection(),

              _overview(),
              _recentOrders(),
              _quickActions(),
            ],
          ),
        ),
      ),
    );
  }

  // 🔷 HEADER
  Widget _header() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5F5CFF), Color(0xFF8F94FB)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Dashboard",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text("Business Insights",
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
          Row(
            children: [
              _iconBtn(Icons.dark_mode),
              const SizedBox(width: 8),
              _iconBtn(Icons.notifications),
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
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  // 🔷 FILTERS
  Widget _filters() {
    return SizedBox(
      height: 55,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (_, index) {
          final isSelected = selectedFilter == index;

          return GestureDetector(
            onTap: () => setState(() => selectedFilter = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF5F5CFF), Color(0xFF8F94FB)])
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? Colors.deepPurple.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ⭐ NEW ERP SALES CHART SECTION
  Widget _salesChartSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('orders').orderBy('createdAt').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data!.docs;

        List<FlSpot> spots = [];
        int index = 0;

        for (var doc in docs.take(7)) {
          final data = doc.data() as Map<String, dynamic>;

          if (!_matchFilter(data['createdAt'])) continue;

          final amount = data['totalAmount'];
          final double value =
              amount is int ? amount.toDouble() : (amount ?? 0.0);

          spots.add(FlSpot(index.toDouble(), value));
          index++;
        }

        return Container(
          height: 250,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sales Analytics",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        spots: spots,
                        dotData: FlDotData(show: false),
                        color: Colors.deepPurple,
                        barWidth: 3,
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

  // 🔷 OVERVIEW KPI
  Widget _overview() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs;

        int total = 0;
        int pending = 0;
        int packed = 0;
        int delivered = 0;
        int undelivered = 0;
        double revenue = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;

          if (!_matchFilter(data['createdAt'])) continue;

          total++;

          final status = (data['status'] ?? '').toLowerCase();
          final payment = (data['paymentStatus'] ?? '').toLowerCase();

          final amount = data['totalAmount'];
          final double safeAmount =
              amount is int ? amount.toDouble() : (amount ?? 0.0);

          if (status == 'pending') pending++;
          if (status == 'packed') packed++;
          if (status == 'delivered') delivered++;
          if (status == 'pending' || status == 'packed') undelivered++;

          if (payment == 'paid') revenue += safeAmount;
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _kpi("Orders", "$total", Icons.shopping_cart,
                  [Color(0xFF36D1DC), Color(0xFF5B86E5)]),
              _kpi("Revenue", "₹${revenue.toInt()}",
                  Icons.currency_rupee,
                  [Color(0xFF11998E), Color(0xFF38EF7D)]),
              _kpi("Pending", "$pending", Icons.timelapse,
                  [Color(0xFFFF8008), Color(0xFFFFC837)]),
              _kpi("Packed", "$packed", Icons.inventory,
                  [Color(0xFF654EA3), Color(0xFFEAafc8)]),
              _kpi("Delivered", "$delivered", Icons.check_circle,
                  [Color(0xFF56ab2f), Color(0xFFA8E063)]),
              _kpi("Undelivered", "$undelivered", Icons.cancel,
                  [Color(0xFFCB356B), Color(0xFFBD3F32)]),
            ],
          ),
        );
      },
    );
  }

  Widget _kpi(String title, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // 🔷 RECENT ORDERS
  Widget _recentOrders() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Recent Orders",
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("Live", style: TextStyle(color: Colors.green)),
            ],
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: db
                .collection('orders')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _matchFilter(data['createdAt']);
              }).toList();

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? "pending";
                  final items = _parseItems(data['items']);

                  String products = items
                      .take(2)
                      .map((e) =>
                          "${e['productName'] ?? 'Item'} x${e['qty'] ?? 0}")
                      .join(", ");

                  return ListTile(
                    title: Text(data['shopName'] ?? "Shop"),
                    subtitle: Text(products),
                    trailing: _status(status),
                  );
                }).toList(),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _status(String status) {
    final color = _getColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }

  Color _getColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'packed':
        return Colors.purple;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  // 🔷 QUICK ACTIONS
  Widget _quickActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _action(Icons.add, "Add"),
          _action(Icons.store, "Shops"),
          _action(Icons.receipt, "Orders"),
          _action(Icons.people, "Users"),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF5F5CFF), Color(0xFF8F94FB)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}