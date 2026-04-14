import 'package:flutter/material.dart';

import 'session_manager.dart';
import 'session_model.dart';
import '../../modules/auth/login_screen.dart';

/// Wrap any screen to enforce authentication + optional RBAC.
///
/// ```dart
/// SessionGuard(
///   requiredRole: UserRole.admin,
///   child: const AdminDashboard(),
/// )
/// ```
class SessionGuard extends StatelessWidget {
  final Widget child;
  final UserRole? requiredRole;
  final Widget? unauthorizedScreen;

  const SessionGuard({
    super.key,
    required this.child,
    this.requiredRole,
    this.unauthorizedScreen,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SessionModel?>(
      stream: SessionManager.instance.sessionStream,
      initialData: SessionManager.instance.currentSession,
      builder: (context, snapshot) {
        final session = snapshot.data;

        if (session == null) return const LoginScreen();

        if (requiredRole != null && session.role != requiredRole) {
          return unauthorizedScreen ?? _UnauthorizedScreen(role: session.role);
        }

        return child;
      },
    );
  }
}

class _UnauthorizedScreen extends StatelessWidget {
  final UserRole role;
  const _UnauthorizedScreen({required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Access Denied',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Your role (${role.name}) cannot access this page.',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => SessionManager.instance.signOut(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}