import 'notification_service.dart';

class AutoNotificationEngine {

  // ─────────────────────────────
  // ORDER EVENTS
  // ─────────────────────────────

  static Future<void> onOrderCreated({
    required String orderId,
    required String shopName,
    required double amount,
  }) async {
    await NotificationService.createNotification(
      type: "order_created",
      title: "New Order Received",
      message: "Order #$orderId placed by $shopName",
      roleTarget: ["admin"],
      priority: "high",
      meta: {
        "orderId": orderId,
        "amount": amount,
      },
    );
  }

  static Future<void> onOrderDelivered({
    required String orderId,
    required String shopName,
  }) async {
    await NotificationService.createNotification(
      type: "order_delivered",
      title: "Order Delivered",
      message: "Order #$orderId delivered to $shopName",
      roleTarget: ["admin"],
    );
  }

  static Future<void> onOrderFailed({
    required String orderId,
  }) async {
    await NotificationService.createNotification(
      type: "order_failed",
      title: "Order Failed",
      message: "Order #$orderId failed",
      roleTarget: ["admin"],
      priority: "high",
    );
  }

  // ─────────────────────────────
  // PAYMENT EVENTS
  // ─────────────────────────────

  static Future<void> onPaymentSuccess({
    required String orderId,
    required double amount,
  }) async {
    await NotificationService.createNotification(
      type: "payment_success",
      title: "Payment Received",
      message: "₹$amount received for Order #$orderId",
      roleTarget: ["admin"],
    );
  }

  static Future<void> onPaymentFailed({
    required String orderId,
  }) async {
    await NotificationService.createNotification(
      type: "payment_failed",
      title: "Payment Failed",
      message: "Payment failed for Order #$orderId",
      roleTarget: ["admin"],
      priority: "high",
    );
  }

  // ─────────────────────────────
  // USER EVENTS
  // ─────────────────────────────

  static Future<void> onUserRegistered({
    required String userName,
  }) async {
    await NotificationService.createNotification(
      type: "new_user",
      title: "New User Joined",
      message: "$userName registered in system",
      roleTarget: ["admin"],
    );
  }

  // ─────────────────────────────
  // PROMOTION EVENTS
  // ─────────────────────────────

  static Future<void> onUserPromoted({
    required String userName,
    required String newRole,
  }) async {
    await NotificationService.createNotification(
      type: "promotion",
      title: "User Promoted",
      message: "$userName promoted to $newRole",
      roleTarget: ["admin"],
    );
  }
}