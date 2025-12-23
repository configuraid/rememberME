import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// ========================================
// REGISTER & LOGIN
// ========================================

/// Registrierung mit Email/Password
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Login mit Email/Password
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Logout
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

// ========================================
// PASSWORD RESET
// ========================================

/// Passwort zurücksetzen
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}

// ========================================
// PROFILE MANAGEMENT
// ========================================

/// Profil aktualisieren
class AuthUpdateProfileRequested extends AuthEvent {
  final String? displayName;
  final String? avatarUrl;

  const AuthUpdateProfileRequested({
    this.displayName,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [displayName, avatarUrl];
}

// ========================================
// AUTH STATUS
// ========================================

/// Auth-Status prüfen (beim App-Start)
class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}

// ========================================
// ACCOUNT
// ========================================

/// Account löschen
class AuthDeleteAccountRequested extends AuthEvent {
  const AuthDeleteAccountRequested();
}
