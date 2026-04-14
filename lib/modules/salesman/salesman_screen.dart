import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/session/session_manager.dart';
import '../../core/session/session_model.dart';

class SalesmanScreen extends StatefulWidget {
  const SalesmanScreen({super.key});

  @override
  State<SalesmanScreen> createState() => _SalesmanScreenState();
}

class _SalesmanScreenState extends State<SalesmanScreen> {
  int _selectedIndex = 0;

  SessionModel get _session => SessionManager.instance.currentSession!;

  final _tabs = const ['Orders', 'Customers', 'Summary'];
  final _icons = const [
    Icons.receipt_long_outlined,
    Icons.people_outline,
    Icons.bar_chart_outlined,
  ];

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _OrdersTab(salesmanUid: _session.uid),
          _CustomersTab(salesmanUid: _session.uid),
          _SummaryTab(salesmanUid: _session.uid),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateOrderSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('New Order'),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Salesman Panel',
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

  void _showCreateOrderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateOrderSheet(salesmanUid: _session.uid),
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

class _OrdersTab extends StatelessWidget {
  final String salesmanUid;
  const _OrdersTab({required this.salesmanUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('salesmanUid', isEqualTo: salesmanUid)
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
            message: 'No orders yet.\nTap + to create one.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _OrderCard(data: data, docId: docs[i].id);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  const _OrderCard({required this.data, required this.docId});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return Colors.green;
      case 'pending':   return Colors.orange;
      case 'cancelled': return Colors.red;
      default:          return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status    = (data['status'] as String?) ?? 'pending';
    final customer  = (data['customerName'] as String?) ?? 'Unknown';
    final amount    = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade50,
          child: const Icon(Icons.shopping_bag_outlined,
              color: Colors.deepPurple),
        ),
        title: Text(customer,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          createdAt != null
              ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
              : '—',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      ),
    );
  }
}

// ─── Customers Tab ────────────────────────────────────────────────────────────

class _CustomersTab extends StatelessWidget {
  final String salesmanUid;
  const _CustomersTab({required this.salesmanUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('customers')
          .where('salesmanUid', isEqualTo: salesmanUid)
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _ErrorView(message: 'Failed to load customers.');
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const _EmptyView(
            icon: Icons.people_outline,
            message: 'No customers yet.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
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
                subtitle: Text((data['phone'] as String?) ?? '—',
                    style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_outlined,
                    color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Summary Tab ──────────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  final String salesmanUid;
  const _SummaryTab({required this.salesmanUid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('salesmanUid', isEqualTo: salesmanUid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs   = snapshot.data?.docs ?? [];
        final total  = docs.length;
        final amount = docs.fold<double>(0, (sum, d) {
          final data = d.data() as Map<String, dynamic>;
          return sum + ((data['amount'] as num?)?.toDouble() ?? 0);
        });
        final delivered = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return (data['status'] as String?) == 'delivered';
        }).length;
        final pending = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return (data['status'] as String?) == 'pending';
        }).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('My Performance',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _SummaryCard(
                  label: 'Total Orders',
                  value: '$total',
                  icon: Icons.receipt_long_outlined,
                  color: Colors.deepPurple),
              const SizedBox(height: 12),
              _SummaryCard(
                  label: 'Total Revenue',
                  value: '₹${amount.toStringAsFixed(2)}',
                  icon: Icons.currency_rupee_outlined,
                  color: Colors.green),
              const SizedBox(height: 12),
              _SummaryCard(
                  label: 'Delivered',
                  value: '$delivered',
                  icon: Icons.check_circle_outline,
                  color: Colors.teal),
              const SizedBox(height: 12),
              _SummaryCard(
                  label: 'Pending',
                  value: '$pending',
                  icon: Icons.hourglass_empty_outlined,
                  color: Colors.orange),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Create Order Sheet ───────────────────────────────────────────────────────

class _CreateOrderSheet extends StatefulWidget {
  final String salesmanUid;
  const _CreateOrderSheet({required this.salesmanUid});

  @override
  State<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<_CreateOrderSheet> {
  final _formKey         = GlobalKey<FormState>();
  final _customerCtrl    = TextEditingController();
  final _amountCtrl      = TextEditingController();
  final _notesCtrl       = TextEditingController();
  bool _isLoading        = false;

  @override
  void dispose() {
    _customerCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'salesmanUid' : widget.salesmanUid,
        'customerName': _customerCtrl.text.trim(),
        'amount'      : double.parse(_amountCtrl.text.trim()),
        'notes'       : _notesCtrl.text.trim(),
        'status'      : 'pending',
        'createdAt'   : FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create order.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('New Order',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _customerCtrl,
              decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person_outline)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee_outlined)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null)
                  return 'Enter valid amount';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.notes_outlined)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Create Order',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
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