import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'session_model.dart';
import '../exceptions/session_exception.dart';
import '../services/token_refresh_service.dart';

class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  final FirebaseAuth      _auth      = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SessionModel? _session;
  SessionModel? get currentSession => _session;
  bool get isLoggedIn => _session != null && _session!.isActive;

  // ✅ Use a BehaviorSubject-like pattern with a seeded value.
  // StreamController.broadcast() loses events for late subscribers.
  // Instead we keep _lastEmitted and replay it to new subscribers.
  final _sessionController = StreamController<SessionModel?>.broadcast();
  bool _hasEmitted = false;

  Stream<SessionModel?> get sessionStream async* {
    // ✅ Replay the last known value to any new subscriber immediately.
    if (_hasEmitted) yield _session;
    yield* _sessionController.stream;
  }

  StreamSubscription<User?>?            _authSub;
  StreamSubscription<DocumentSnapshot>? _profileSub;

  // ── Init ────────────────────────────────────────────────────────────────────

  void init() {
    _authSub = _auth.authStateChanges().listen(_onAuthStateChanged);
    log('[SessionManager] Initialised.', name: 'SessionManager');
  }

  // ── Auth state ──────────────────────────────────────────────────────────────

  Future<void> _onAuthStateChanged(User? user) async {
    _profileSub?.cancel();
    _profileSub = null;

    if (user == null) {
      _clearSession();
      return;
    }

    _profileSub = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snap) => _onProfileSnapshot(user.uid, snap),
          onError: (_) => _clearSession(),
        );
  }

  void _onProfileSnapshot(String uid, DocumentSnapshot snap) {
    if (!snap.exists) {
      signOut();
      return;
    }

    final data    = snap.data() as Map<String, dynamic>;
    final session = SessionModel.fromFirestore(uid, data);

    if (!session.isActive) {
      signOut(reason: SessionFailureReason.accountDisabled);
      return;
    }

    _session = session;
    _emit(_session);
    log('[SessionManager] Session updated: ${session.role.name}',
        name: 'SessionManager');
  }

  // ── Load session ─────────────────────────────────────────────────────────

  Future<SessionModel> loadSession(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        throw const SessionException(
          'User profile not found.',
          reason: SessionFailureReason.userNotFound,
        );
      }

      final session = SessionModel.fromFirestore(uid, doc.data()!);

      if (!session.isActive) {
        throw const SessionException(
          'Account is disabled. Contact admin.',
          reason: SessionFailureReason.accountDisabled,
        );
      }

      _session = session;
      _emit(_session);
      return session;
    } on SessionException {
      rethrow;
    } catch (e) {
      throw SessionException(
        'Failed to load profile.',
        reason: e is FirebaseException
            ? SessionFailureReason.firestoreError
            : SessionFailureReason.unknown,
      );
    }
  }

  // ── Sign out ────────────────────────────────────────────────────────────────

  Future<void> signOut({SessionFailureReason? reason}) async {
    TokenRefreshService.instance.stop();
    _profileSub?.cancel();
    _profileSub = null;
    _clearSession();
    await _auth.signOut();
    log('[SessionManager] Signed out. Reason: $reason',
        name: 'SessionManager');
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _clearSession() {
    _session = null;
    _emit(null);
  }

  void _emit(SessionModel? value) {
    _hasEmitted = true;
    if (!_sessionController.isClosed) {
      _sessionController.add(value);
    }
  }

  // ── Dispose ──────────────────────────────────────────────────────────────────

  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    _sessionController.close();
  }
}