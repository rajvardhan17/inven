import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/app_theme.dart';

// ─────────────────────────────────────────────────
// Pure-Dart helpers — no intl package needed
// ─────────────────────────────────────────────────

/// Indian number format: 1,23,45,678
String _fmtRupee(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  final rest = s.substring(0, s.length - 3);
  final buf = StringBuffer();
  for (int i = 0; i < rest.length; i++) {
    if (i != 0 && (rest.length - i) % 2 == 0) buf.write(',');
    buf.write(rest[i]);
  }
  return '${buf.toString()},$last3';
}

/// e.g. "04 Jan 2025, 3:07 PM"
String _fmtDate(DateTime d) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}, $h:$m $ampm';
}

// ─────────────────────────────────────────────────

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _selectedFilter = 0;
  String _search = '';

  final List<String> _filters = ['All', 'Today', 'Week', 'Month', 'Year'];

  // ───────── SAFE HELPERS ─────────
  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0;
  }

  Map<String, dynamic> _safeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  bool _matchFilter(Timestamp? ts) {
    if (_selectedFilter == 0) return true;
    if (ts == null) return false;
    final d = ts.toDate();
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 1:
        return d.year == now.year && d.month == now.month && d.day == now.day;
      case 2:
        return d.isAfter(now.subtract(const Duration(days: 7)));
      case 3:
        return d.year == now.year && d.month == now.month;
      case 4:
        return d.year == now.year;
      default:
        return true;
    }
  }

  bool _matchSearch(Map<String, dynamic> d) {
    if (_search.isEmpty) return true;
    final q = _search.toLowerCase();
    final shop = (d['shopName'] ?? '').toString().toLowerCase();
    final id = (d['orderId'] ?? '').toString().toLowerCase();
    return shop.contains(q) || id.contains(q);
  }

  String _statusNorm(dynamic s) => s?.toString().toLowerCase().trim() ?? '';
  bool _isCompleted(String s) => s == 'delivered' || s == 'completed';

  // ───────── BUILD ─────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterBar(),
            Expanded(child: _buildStream()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 16),
      decoration: const BoxDecoration(
        gradient: AppTheme.accentGrad,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.bg),
            onPressed: () => Navigator.pop(context),
          ),
          const Icon(Icons.history, color: AppTheme.bg, size: 22),
          const SizedBox(width: 8),
          const Text(
            'Order History',
            style: TextStyle(
              color: AppTheme.bg,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by shop or order ID...',
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          filled: true,
          fillColor: AppTheme.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: const BorderSide(color: AppTheme.orange),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final active = _selectedFilter == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppTheme.orange : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppTheme.orange : AppTheme.border,
                ),
              ),
              child: Text(
                _filters[i],
                style: TextStyle(
                  color: active ? AppTheme.bg : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.orange));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.red)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmpty('No orders found');
        }

        double totalRevenue = 0;
        final List<QueryDocumentSnapshot> filtered = [];

        for (final doc in snapshot.data!.docs) {
          final data = _safeMap(doc.data());
          final status = _statusNorm(data['status']);
          if (!_isCompleted(status)) continue;

          final ts = data['createdAt'];
          final timestamp = ts is Timestamp ? ts : null;
          if (!_matchFilter(timestamp)) continue;
          if (!_matchSearch(data)) continue;

          totalRevenue += _toDouble(data['totalAmount']);
          filtered.add(doc);
        }

        if (filtered.isEmpty) return _buildEmpty('No matching orders');

        return Column(
          children: [
            _buildSummaryCard(filtered.length, totalRevenue),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final data = _safeMap(filtered[i].data());
                  return _OrderTile(data: data, toDouble: _toDouble);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(int count, double revenue) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long,
                      color: AppTheme.blue, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$count',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        )),
                    const Text('Orders',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: AppTheme.border),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_fmtRupee(revenue.toInt())}',
                      style: const TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Text('Revenue',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.currency_rupee,
                      color: AppTheme.green, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(msg,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// ORDER TILE
// ─────────────────────────────────────────────────
class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final double Function(dynamic) toDouble;

  const _OrderTile({required this.data, required this.toDouble});

  String get _formattedDate {
    final ts = data['createdAt'];
    if (ts is! Timestamp) return '';
    return _fmtDate(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final shopName = data['shopName'] ?? 'Unknown Shop';
    final orderId = data['orderId'] ?? 'N/A';
    final amount = toDouble(data['totalAmount']);
    final items = data['items'];
    final hasItems = items is List && items.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 4, 12, 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.check_circle, color: AppTheme.green, size: 20),
          ),
          title: Text(
            shopName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              children: [
                const Icon(Icons.tag, size: 11, color: AppTheme.textSecondary),
                const SizedBox(width: 3),
                Text(orderId,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_fmtRupee(amount.toInt())}',
                style: const TextStyle(
                  color: AppTheme.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'COMPLETED',
                  style: TextStyle(
                      color: AppTheme.green,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          children: [
            const Divider(color: AppTheme.border, height: 16),

            if (_formattedDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 5),
                    Text(_formattedDate,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),

            if (hasItems) ...[
              const Text(
                'Items',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ...(items as List).map((item) {
                final m = item is Map<String, dynamic>
                    ? item
                    : (item is Map
                        ? Map<String, dynamic>.from(item)
                        : <String, dynamic>{});
                final name = m['name'] ?? m['productName'] ?? 'Item';
                final qty = m['qty'] ?? m['quantity'] ?? 1;
                final price = toDouble(m['price'] ?? m['unitPrice']);
                final qtyInt =
                    qty is int ? qty : (int.tryParse(qty.toString()) ?? 1);
                final lineTotal = price * qtyInt;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 8, top: 1),
                        decoration: const BoxDecoration(
                          color: AppTheme.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$name  ×$qty',
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 13),
                        ),
                      ),
                      Text(
                        '₹${_fmtRupee(lineTotal.toInt())}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(color: AppTheme.border, height: 16),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    )),
                Text(
                  '₹${_fmtRupee(amount.toInt())}',
                  style: const TextStyle(
                    color: AppTheme.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}