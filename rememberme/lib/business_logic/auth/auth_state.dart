import 'package:equatable/equatable.dart';
import 'package:rememberme/data/models/auth/user_model.dart';

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

  // ========================================
  // FACTORY CONSTRUCTORS
  // ========================================

  /// Initial State - App gerade gestartet
  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.initial);
  }

  /// Loading State - Authentifizierung läuft
  factory AuthState.loading() {
    return const AuthState(status: AuthStatus.loading);
  }

  /// Authenticated State - User erfolgreich eingeloggt
  factory AuthState.authenticated(UserModel user) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
    );
  }

  /// Unauthenticated State - Kein User eingeloggt
  factory AuthState.unauthenticated() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Error State - Fehler bei Authentifizierung
  factory AuthState.error(String message) {
    return AuthState(
      status: AuthStatus.error,
      errorMessage: message,
    );
  }

  // ========================================
  // GETTERS
  // ========================================

  /// Ist ein User authentifiziert?
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  /// Läuft gerade eine Authentifizierung?
  bool get isLoading => status == AuthStatus.loading;

  /// Gibt es einen Fehler?
  bool get hasError => status == AuthStatus.error && errorMessage != null;

  /// Ist der User nicht authentifiziert?
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  /// Ist der Status initial?
  bool get isInitial => status == AuthStatus.initial;

  // ========================================
  // COPY WITH
  // ========================================

  /// Erstellt eine Kopie des States mit neuen Werten
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

  @override
  String toString() {
    return 'AuthState(status: $status, user: ${user?.name ?? 'null'}, error: ${errorMessage ?? 'null'})';
  }
}
