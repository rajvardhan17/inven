import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final db = FirebaseFirestore.instance;

  Color _getColor(String type) {
    switch (type) {
      case "payment":
        return Colors.green;
      case "order_created":
        return Colors.blue;
      case "delivery":
        return Colors.orange;
      case "shop_added":
        return Colors.purple;
      case "user_added":
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case "payment":
        return Icons.payment;
      case "order_created":
        return Icons.shopping_cart;
      case "delivery":
        return Icons.local_shipping;
      case "shop_added":
        return Icons.store;
      case "user_added":
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(Timestamp ts) {
    final date = ts.toDate();
    return DateFormat('dd MMM, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0D0F14);
    const card = Color(0xFF161A23);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: card,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection("notifications")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];

              final type = data["type"] ?? "default";
              final title = data["title"] ?? "";
              final message = data["message"] ?? "";
              final time = data["timestamp"] as Timestamp?;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getColor(type).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getColor(type),
                      child: Icon(
                        _getIcon(type),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (time != null)
                            Text(
                              _formatTime(time),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}