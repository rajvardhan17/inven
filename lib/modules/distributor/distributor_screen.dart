import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/session/session_manager.dart';
import '../../core/session/session_model.dart';

class DistributorScreen extends StatefulWidget {
  const DistributorScreen({super.key});

  @override
  State<DistributorScreen> createState() => _DistributorScreenState();
}

class _DistributorScreenState extends State<DistributorScreen> {
  int _selectedIndex = 0;

  SessionModel get _session => SessionManager.instance.currentSession!;

  final _tabs  = const ['Orders', 'Inventory', 'Salesmen'];
  final _icons = const [
    Icons.receipt_long_outlined,
    Icons.inventory_2_outlined,
    Icons.people_outline,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _DistributorOrdersTab(distributorUid: _session.uid),
          _InventoryTab(distributorUid: _session.uid),
          _SalesmenTab(distributorUid: _session.uid),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Distributor Panel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(_session.name,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0.5,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_outlined),
          tooltip: 'Sign out',
          onPressed: () async {
            final confirmed = await _confirmSignOut(context);
            if (confirmed == true) SessionManager.instance.signOut();
          },
        ),
      ],
    );
  }

  NavigationBar _buildNavBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      backgroundColor: Colors.white,
      destinations: List.generate(
        _tabs.length,
        (i) => NavigationDestination(
          icon: Icon(_icons[i]),
          label: _tabs[i],
        ),
      ),
    );
  }

  Future<bool?> _confirmSignOut(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

// ─── Orders Tab ───────────────────────────────────────────────────────────────

class _DistributorOrdersTab extends StatelessWidget {
  final String distributorUid;
  const _DistributorOrdersTab({required this.distributorUid});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return Colors.green;
      case 'pending':   return Colors.orange;
      case 'cancelled': return Colors.red;
      default:          return Colors.blueGrey;
    }
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(docId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('distributorUid', isEqualTo: distributorUid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _ErrorView(message: 'Failed to load orders.');
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const _EmptyView(
            icon: Icons.receipt_long_outlined,
            message: 'No orders assigned yet.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final data   = docs[i].data() as Map<String, dynamic>;
            final docId  = docs[i].id;
            final status = (data['status'] as String?) ?? 'pending';

            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (data['customerName'] as String?) ?? '—',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                color: _statusColor(status),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${((data['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    // Status update actions
                    if (status == 'pending')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _updateStatus(docId, 'delivered'),
                              icon: const Icon(Icons.check,
                                  size: 16, color: Colors.green),
                              label: const Text('Mark Delivered',
                                  style:
                                      TextStyle(color: Colors.green)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.green),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _updateStatus(docId, 'cancelled'),
                              icon: const Icon(Icons.close,
                                  size: 16, color: Colors.red),
                              label: const Text('Cancel',
                                  style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Inventory Tab ────────────────────────────────────────────────────────────

class _InventoryTab extends StatelessWidget {
  final String distributorUid;
  const _InventoryTab({required this.distributorUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('inventory')
          .where('distributorUid', isEqualTo: distributorUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _ErrorView(message: 'Failed to load inventory.');
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const _EmptyView(
            icon: Icons.inventory_2_outlined,
            message: 'No inventory items found.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final data     = docs[i].data() as Map<String, dynamic>;
            final stock    = (data['stock'] as num?)?.toInt() ?? 0;
            final isLow    = stock < 10;

            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isLow
                      ? Colors.red.shade50
                      : Colors.deepPurple.shade50,
                  child: Icon(Icons.inventory_2_outlined,
                      color: isLow ? Colors.red : Colors.deepPurple),
                ),
                title: Text((data['name'] as String?) ?? '—',
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    'SKU: ${(data['sku'] as String?) ?? '—'}',
                    style: const TextStyle(fontSize: 12)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$stock units',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isLow ? Colors.red : Colors.black)),
                    if (isLow)
                      const Text('Low stock',
                          style: TextStyle(
                              fontSize: 10, color: Colors.red)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Salesmen Tab ─────────────────────────────────────────────────────────────

class _SalesmenTab extends StatelessWidget {
  final String distributorUid;
  const _SalesmenTab({required this.distributorUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'salesman')
          .where('distributorUid', isEqualTo: distributorUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _ErrorView(message: 'Failed to load salesmen.');
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const _EmptyView(
            icon: Icons.people_outline,
            message: 'No salesmen assigned yet.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final data     = docs[i].data() as Map<String, dynamic>;
            final isActive = (data['isActive'] as bool?) ?? false;

            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade50,
                  child: Text(
                    ((data['name'] as String?) ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text((data['name'] as String?) ?? '—',
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text((data['email'] as String?) ?? '—',
                    style: const TextStyle(fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                        fontSize: 11,
                        color: isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}