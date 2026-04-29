import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inven/core/app_theme.dart';
import 'package:inven/models/invoice_model.dart';
import 'invoice_detail_screen.dart';

class InvoiceDashboardScreen extends StatelessWidget {
  const InvoiceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Invoices',
      actions: [
        IconButton(
          onPressed: () {}, // TODO: Implement search
          icon: const Icon(Icons.search, color: AppTheme.textSecondary),
        ),
        IconButton(
          onPressed: () {}, // TODO: Create new invoice directly
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.accent),
        ),
      ],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('payments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final invoices = snapshot.data!.docs.map((doc) => InvoiceModel.fromFirestore(doc)).toList();
          
          // Sort client-side (descending by date)
          invoices.sort((a, b) => b.date.compareTo(a.date));

          // Calculate summary stats
          double totalOutstanding = 0;
          double totalPending = 0;
          double totalOverdue = 0;

          for (var inv in invoices) {
            if (inv.status == InvoiceStatus.paid) continue;
            totalOutstanding += inv.balanceDue;
            if (inv.isOverdue) {
              totalOverdue += inv.balanceDue;
            } else {
              totalPending += inv.balanceDue;
            }
          }

          return RefreshIndicator(
            onRefresh: () async => {},
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SUMMARY CARDS ---
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _SummaryCard(
                          title: 'Total Outstanding',
                          amount: totalOutstanding,
                          color: AppTheme.accent,
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        const SizedBox(width: 12),
                        _SummaryCard(
                          title: 'Pending',
                          amount: totalPending,
                          color: AppTheme.orange,
                          icon: Icons.hourglass_empty,
                        ),
                        const SizedBox(width: 12),
                        _SummaryCard(
                          title: 'Overdue',
                          amount: totalOverdue,
                          color: AppTheme.red,
                          icon: Icons.warning_amber_rounded,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- LIST HEADER ---
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Invoices',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'View All',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // --- INVOICE LIST ---
                  if (invoices.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text('No invoices found', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: invoices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return _InvoiceListTile(invoice: invoice);
                      },
                    ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceListTile extends StatelessWidget {
  final InvoiceModel invoice;

  const _InvoiceListTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(invoice: invoice),
          ),
        );
      },
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.invoiceNo,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoice.customerName,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${invoice.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                StatusBadge.fromStatus(_getStatusString(invoice.status)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusString(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid: return 'paid';
      case InvoiceStatus.pending: return 'unpaid';
      case InvoiceStatus.overdue: return 'overdue';
      case InvoiceStatus.sent: return 'sent';
      default: return 'draft';
    }
  }
}
