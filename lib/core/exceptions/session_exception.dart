enum SessionFailureReason {
  userNotFound,
  accountDisabled,
  networkError,
  firestoreError,
  unknown,
}

class SessionException implements Exception {
  final String message;
  final SessionFailureReason reason;

  const SessionException(
    this.message, {
    this.reason = SessionFailureReason.unknown,
  });

  @override
  String toString() => 'SessionException($reason): $message';
}