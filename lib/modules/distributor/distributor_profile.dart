import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/app_theme.dart';

class DistributorProfileScreen extends StatelessWidget {
  final String uid;
  const DistributorProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text("Profile"),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (_, snap) {
          final data  = snap.data?.data() as Map<String, dynamic>? ?? {};
          final name  = data['name'] ?? 'Distributor';
          final email = data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '—';
          final phone = data['phone'] ?? '—';
          final zone  = data['zone'] ?? '—';
          final vehicle = data['vehicle'] ?? '—';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Stack(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.greenGrad,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(
                            color: AppTheme.green.withOpacity(0.4),
                            blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: Center(child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'D',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                        )),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 22, height: 22,
                          decoration: const BoxDecoration(color: AppTheme.green, shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.greenSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.green.withOpacity(0.3)),
                    ),
                    child: const Text("DISTRIBUTOR", style: TextStyle(
                      color: AppTheme.green, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ),
                ]),
              ),
              const SizedBox(height: 8),

              // Info
              AppCard(
                child: Column(children: [
                  _row(Icons.email_outlined, "Email", email),
                  const AccentDivider(),
                  _row(Icons.phone_outlined, "Phone", phone),
                  const AccentDivider(),
                  _row(Icons.map_outlined, "Zone", zone),
                  const AccentDivider(),
                  _row(Icons.local_shipping_outlined, "Vehicle", vehicle),
                ]),
              ),
              const SizedBox(height: 8),

              // Stats
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders')
                    .where('distributorId', isEqualTo: uid).snapshots(),
                builder: (_, snap) {
                  int assigned  = snap.data?.docs.length ?? 0;
                  int delivered = 0;
                  double rev    = 0;
                  for (var d in snap.data?.docs ?? []) {
                    final data = d.data() as Map<String, dynamic>;
                    if ((data['deliveryStatus'] ?? '') == 'delivered') delivered++;
                    if ((data['paymentStatus'] ?? '') == 'paid') {
                      rev += (data['totalAmount'] ?? 0).toDouble();
                    }
                  }
                  return AppCard(
                    child: Column(children: [
                      const Row(children: [
                        Icon(Icons.bar_chart_rounded, color: AppTheme.green, size: 16),
                        SizedBox(width: 8),
                        Text("Performance", style: TextStyle(
                          color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _stat("Assigned", "$assigned", AppTheme.blue)),
                        Container(width: 1, height: 40, color: AppTheme.border),
                        Expanded(child: _stat("Delivered", "$delivered", AppTheme.green)),
                        Container(width: 1, height: 40, color: AppTheme.border),
                        Expanded(child: _stat("Collected", "₹${rev.toInt()}", AppTheme.accent)),
                      ]),
                    ]),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Logout
              OutlinedButton.icon(
                onPressed: () async => await FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text("Logout"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.red,
                  side: const BorderSide(color: AppTheme.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: AppTheme.textMuted, size: 18),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      ])),
    ]);
  }

  Widget _stat(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(
        color: color, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text(label, textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
    ]);
  }
}