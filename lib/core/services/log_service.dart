import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LOG SERVICE
//  Write structured logs to Firestore 'logs' collection.
//  Never throws — safe to call anywhere without try/catch.
// ─────────────────────────────────────────────────────────────────────────────

class LogService {
  LogService._(); // static only

  static final _db = FirebaseFirestore.instance;

  // ── Core writer ───────────────────────────────────────────

  static Future<void> log({
    required String type,    // payment | order | error | auth | system
    required String action,  // short verb: "created", "updated", "paid", etc.
    required String message, // human-readable description
    String? userId,
    String? module,          // e.g. "orders", "payments", "inventory"
    Map<String, dynamic>? meta,
  }) async {
    try {
      final uid = userId ??
          FirebaseAuth.instance.currentUser?.uid ??
          'system';

      await _db.collection('logs').add({
        'type':      type,
        'action':    action,
        'message':   message,
        'module':    module ?? type,
        'userId':    uid,
        'meta':      meta ?? {},
        // ✅ Use 'timestamp' not 'createdAt' so logs screen
        //    can .orderBy('timestamp') without a composite index
        //    (single-field indexes are auto-created by Firestore).
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Never propagate — logging must never crash the app
      debugPrint('LogService error: $e');
    }
  }

  // ── Typed helpers ─────────────────────────────────────────

  static Future<void> payment(
    String message, {
    String? userId,
    Map<String, dynamic>? meta,
  }) =>
      log(
        type:    'payment',
        action:  meta?['action'] ?? 'payment',
        message: message,
        module:  'payments',
        userId:  userId,
        meta:    meta,
      );

  static Future<void> order(
    String message, {
    String? action = 'updated',
    String? userId,
    Map<String, dynamic>? meta,
  }) =>
      log(
        type:    'order',
        action:  action!,
        message: message,
        module:  'orders',
        userId:  userId,
        meta:    meta,
      );

  static Future<void> error(
    String message, {
    String? userId,
    Map<String, dynamic>? meta,
  }) =>
      log(
        type:    'error',
        action:  'error',
        message: message,
        module:  meta?['module'] ?? 'system',
        userId:  userId,
        meta:    meta,
      );

  static Future<void> auth(
    String message, {
    String? userId,
    Map<String, dynamic>? meta,
  }) =>
      log(
        type:    'auth',
        action:  meta?['action'] ?? 'auth',
        message: message,
        module:  'auth',
        userId:  userId,
        meta:    meta,
      );

  static Future<void> system(
    String message, {
    String? action = 'system',
    Map<String, dynamic>? meta,
  }) =>
      log(
        type:    'system',
        action:  action!,
        message: message,
        module:  'system',
        meta:    meta,
      );
}