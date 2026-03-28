sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class Unauthenticated extends AuthState {
  final bool hasAccount;

  const Unauthenticated({required this.hasAccount});
}

class Authenticated extends AuthState {
  final String? email;

  const Authenticated({
    this.email,
  });
}
