import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

import '../session/session_manager.dart';

class TokenRefreshService {
  TokenRefreshService._();
  static final TokenRefreshService instance = TokenRefreshService._();

  static const _refreshInterval = Duration(minutes: 55);
  static const _retryDelay      = Duration(seconds: 30);
  static const _maxRetries      = 3;

  Timer? _timer;
  bool   _isRunning = false;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _scheduleRefresh();
    log('[TokenRefreshService] Started.', name: 'TokenRefreshService');
  }

  void stop() {
    _timer?.cancel();
    _timer     = null;
    _isRunning = false;
    log('[TokenRefreshService] Stopped.', name: 'TokenRefreshService');
  }

  Future<String?> getFreshToken() async {
    return _refresh(forceRefresh: true);
  }

  void _scheduleRefresh() {
    _timer?.cancel();
    _timer = Timer(_refreshInterval, _onTimerFired);
  }

  Future<void> _onTimerFired() async {
    await _refresh(forceRefresh: true);
    if (_isRunning) _scheduleRefresh();
  }

  Future<String?> _refresh({
    bool forceRefresh = false,
    int attempt = 1,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      log('[TokenRefreshService] No user. Skipping.',
          name: 'TokenRefreshService');
      return null;
    }

    if (!SessionManager.instance.isLoggedIn) {
      stop();
      return null;
    }

    try {
      final token = await user.getIdToken(forceRefresh);
      log('[TokenRefreshService] Refreshed (attempt $attempt).',
          name: 'TokenRefreshService');
      return token;
    } on FirebaseAuthException catch (e) {
      return _handleError(e, attempt);
    } catch (e) {
      log('[TokenRefreshService] Unexpected: $e',
          name: 'TokenRefreshService', level: 900);
      return _retryOrGiveUp(attempt);
    }
  }

  Future<String?> _handleError(FirebaseAuthException e, int attempt) async {
    log('[TokenRefreshService] ${e.code}: ${e.message}',
        name: 'TokenRefreshService', level: 900);

    switch (e.code) {
      case 'user-disabled':
      case 'user-not-found':
      case 'invalid-user-token':
      case 'user-token-expired':
        log('[TokenRefreshService] Unrecoverable. Signing out.',
            name: 'TokenRefreshService', level: 1000);
        stop();
        await SessionManager.instance.signOut();
        return null;
      default:
        return _retryOrGiveUp(attempt);
    }
  }

  Future<String?> _retryOrGiveUp(int attempt) async {
    if (attempt >= _maxRetries) {
      log('[TokenRefreshService] Max retries reached.',
          name: 'TokenRefreshService', level: 900);
      return null;
    }

    final delay = _retryDelay * (attempt * 2);
    log('[TokenRefreshService] Retry in $delay ($attempt/$_maxRetries).',
        name: 'TokenRefreshService');

    await Future.delayed(delay);
    return _refresh(forceRefresh: true, attempt: attempt + 1);
  }
}