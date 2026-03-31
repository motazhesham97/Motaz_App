sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({
    required this.hasAccount,
    this.errorMessage,
  });

  final bool hasAccount;
  final String? errorMessage;
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.email);

  final String email;
}
