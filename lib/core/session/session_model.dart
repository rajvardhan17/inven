import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, salesman, distributor, user, unknown }

extension UserRoleX on UserRole {
  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':       return UserRole.admin;
      case 'salesman':    return UserRole.salesman;
      case 'distributor': return UserRole.distributor;
      case 'user':        return UserRole.user;
      default:            return UserRole.unknown;
    }
  }

  bool get isAdmin => this == UserRole.admin;
}

class SessionModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  const SessionModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory SessionModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return SessionModel(
      uid:       uid,
      name:      (data['name']      as String?)    ?? '',
      email:     (data['email']     as String?)    ?? '',
      phone:     (data['phone']     as String?)    ?? '',
      role:      UserRoleX.fromString(data['role'] as String?),
      isActive:  (data['isActive']  as bool?)      ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  SessionModel copyWith({bool? isActive}) => SessionModel(
    uid:       uid,
    name:      name,
    email:     email,
    phone:     phone,
    role:      role,
    isActive:  isActive ?? this.isActive,
    createdAt: createdAt,
  );
}