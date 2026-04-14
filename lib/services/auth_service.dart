// lib/services/auth_service.dart

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  const AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserRole> resolveRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) return UserRole.unknown;

    final data = doc.data()!;
    if (data['isActive'] == false) {
      await _auth.signOut();
      return UserRole.unknown;
    }

    return UserRoleX.fromString(data['role'] as String?);
  }
}