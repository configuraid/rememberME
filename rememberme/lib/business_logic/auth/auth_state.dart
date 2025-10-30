import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  // Initial State
  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.initial);
  }

  // Loading State
  factory AuthState.loading() {
    return const AuthState(status: AuthStatus.loading);
  }

  // Authenticated State
  factory AuthState.authenticated(UserModel user) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
    );
  }

  // Unauthenticated State
  factory AuthState.unauthenticated() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  // Error State
  factory AuthState.error(String message) {
    return AuthState(
      status: AuthStatus.error,
      errorMessage: message,
    );
  }

  // Getter
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;

  // CopyWith
  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
