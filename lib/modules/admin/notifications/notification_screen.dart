import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getNotifications() {
    return db
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String id) async {
    await db.collection('notifications').doc(id).update({
      'isRead': true,
    });
  }

  IconData getIcon(String type) {
    switch (type) {
      case "order_created":
        return Icons.shopping_cart_outlined;
      case "payment_success":
        return Icons.check_circle_outline;
      case "payment_failed":
        return Icons.cancel_outlined;
      case "order_delivered":
        return Icons.local_shipping_outlined;
      case "order_failed":
        return Icons.error_outline;
      case "new_user":
        return Icons.person_add_alt_1_outlined;
      case "promotion":
        return Icons.upgrade_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color getColor(String type) {
    switch (type) {
      case "payment_success":
      case "order_delivered":
        return AppTheme.green;
      case "payment_failed":
      case "order_failed":
        return AppTheme.red;
      case "new_user":
        return AppTheme.blue;
      case "promotion":
        return AppTheme.purple;
      case "order_created":
        return AppTheme.orange;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,

      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: getNotifications(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;

              final id = doc.id;
              final type = (data['type'] ?? '').toString();
              final title = (data['title'] ?? 'No Title').toString();
              final message = (data['message'] ?? '').toString();
              final isRead = data['isRead'] ?? false;

              final color = getColor(type);

              return Dismissible(
                key: Key(id),

                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.check, color: AppTheme.green),
                ),

                onDismissed: (_) => markAsRead(id),

                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isRead
                          ? AppTheme.border
                          : color.withOpacity(0.4),
                    ),
                    boxShadow: AppTheme.cardShadow,
                  ),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ICON CHIP
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          getIcon(type),
                          color: color,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // CONTENT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              title,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              message,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // STATUS
                      Column(
                        children: [
                          Icon(
                            isRead
                                ? Icons.done_all
                                : Icons.fiber_new,
                            size: 18,
                            color: isRead
                                ? AppTheme.green
                                : AppTheme.accent,
                          ),

                          const SizedBox(height: 8),

                          GestureDetector(
                            onTap: () => markAsRead(id),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}