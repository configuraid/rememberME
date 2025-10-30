import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Login mit Auth-Key
class AuthLoginWithKeyRequested extends AuthEvent {
  final String authKey;

  const AuthLoginWithKeyRequested(this.authKey);

  @override
  List<Object?> get props => [authKey];
}

// Login mit QR-Code
class AuthLoginWithQRRequested extends AuthEvent {
  final String qrCode;

  const AuthLoginWithQRRequested(this.qrCode);

  @override
  List<Object?> get props => [qrCode];
}

// Logout
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

// User-Profil aktualisieren
class AuthUpdateProfileRequested extends AuthEvent {
  final String? name;
  final String? email;
  final String? profileImageUrl;

  const AuthUpdateProfileRequested({
    this.name,
    this.email,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [name, email, profileImageUrl];
}

// Auth-Status prüfen
class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}

// Token erneuern
class AuthTokenRefreshRequested extends AuthEvent {
  const AuthTokenRefreshRequested();
}
