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

  bool _hasEmitted = false;
  final _sessionController = StreamController<SessionModel?>.broadcast();

  // ✅ Replays last value to every new subscriber — fixes stuck splash.
  Stream<SessionModel?> get sessionStream async* {
    if (_hasEmitted) yield _session;
    yield* _sessionController.stream;
  }

  StreamSubscription<User?>?            _authSub;
  StreamSubscription<DocumentSnapshot>? _profileSub;
  StreamSubscription<QuerySnapshot>?    _profileQuerySub;

  // ── Init ────────────────────────────────────────────────────────────────────

  void init() {
    _authSub = _auth.authStateChanges().listen(_onAuthStateChanged);
    log('[SessionManager] Initialised.', name: 'SessionManager');
  }

  // ── Auth state ──────────────────────────────────────────────────────────────

  Future<void> _onAuthStateChanged(User? user) async {
    _cancelProfileSubs();

    if (user == null) {
      _clearSession();
      return;
    }

    // Check if doc exists at uid path (correct structure).
    final directDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (directDoc.exists) {
      // ✅ Correct path — listen by uid.
      _profileSub = _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen(
            (snap) => _onProfileSnapshot(user.uid, snap),
            onError: (_) => _clearSession(),
          );
    } else {
      // ✅ Legacy path — doc saved with auto-generated ID, query by email.
      _profileQuerySub = _firestore
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .snapshots()
          .listen(
            (snap) {
              if (snap.docs.isEmpty) {
                signOut();
                return;
              }
              _onProfileSnapshot(snap.docs.first.id, snap.docs.first);
            },
            onError: (_) => _clearSession(),
          );
    }
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

  // ── Load session (called after login / register) ──────────────────────────

  Future<SessionModel> loadSession(String uid) async {
    try {
      // Try uid path first.
      var doc = await _firestore.collection('users').doc(uid).get();

      // ✅ Fallback: query by email for legacy auto-generated doc IDs.
      if (!doc.exists) {
        final user = _auth.currentUser;
        if (user == null) {
          throw const SessionException(
            'Not authenticated.',
            reason: SessionFailureReason.userNotFound,
          );
        }

        final query = await _firestore
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          throw const SessionException(
            'User profile not found.',
            reason: SessionFailureReason.userNotFound,
          );
        }

        final data    = query.docs.first.data();
        final session = SessionModel.fromFirestore(query.docs.first.id, data);

        if (!session.isActive) {
          throw const SessionException(
            'Account is disabled. Contact admin.',
            reason: SessionFailureReason.accountDisabled,
          );
        }

        _session = session;
        _emit(_session);
        return session;
      }

      // Normal path.
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
    _cancelProfileSubs();
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

  void _cancelProfileSubs() {
    _profileSub?.cancel();
    _profileSub = null;
    _profileQuerySub?.cancel();
    _profileQuerySub = null;
  }

  // ── Dispose ──────────────────────────────────────────────────────────────────

  void dispose() {
    _authSub?.cancel();
    _cancelProfileSubs();
    _sessionController.close();
  }
}