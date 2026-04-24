import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static Future<void> createNotification({
    required String type,
    required String title,
    required String message,
    required List<String> roleTarget,
    String? uid,
    Map<String, dynamic>? meta,
    String priority = "low",
  }) async {
    await db.collection('notifications').add({
      "type": type,
      "title": title,
      "message": message,
      "roleTarget": roleTarget,
      "uid": uid,
      "createdAt": Timestamp.now(),
      "isRead": false,
      "priority": priority,
      "meta": meta ?? {},
    });
  }
}