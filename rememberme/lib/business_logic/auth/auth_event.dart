import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// ========================================
// AUTH KEY / QR CODE LOGIN
// ========================================

/// Login mit Auth-Key (Organisation-Login)
class AuthLoginWithKeyRequested extends AuthEvent {
  final String authKey;

  const AuthLoginWithKeyRequested(this.authKey);

  @override
  List<Object?> get props => [authKey];
}

/// Login mit QR-Code (Organisation-Login)
class AuthLoginWithQRRequested extends AuthEvent {
  final String qrCode;

  const AuthLoginWithQRRequested(this.qrCode);

  @override
  List<Object?> get props => [qrCode];
}

// ========================================
// USER SELECTION & PROFILE CREATION
// ========================================

/// User Selection - Wähle existierenden User aus Organisation
class AuthUserSelectionRequested extends AuthEvent {
  final String organizationId;
  final String userId;
  final String? pin; // Optional PIN für geschützte Profile

  const AuthUserSelectionRequested({
    required this.organizationId,
    required this.userId,
    this.pin,
  });

  @override
  List<Object?> get props => [organizationId, userId, pin];
}

/// Neues Profil erstellen in Organisation
class AuthNewProfileCreationRequested extends AuthEvent {
  final String organizationId;
  final String name;
  final String email;
  final String? pin; // Optional PIN zum Schützen des Profils

  const AuthNewProfileCreationRequested({
    required this.organizationId,
    required this.name,
    required this.email,
    this.pin,
  });

  @override
  List<Object?> get props => [organizationId, name, email, pin];
}

// ========================================
// PROFILE MANAGEMENT
// ========================================

/// User-Profil aktualisieren
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

// ========================================
// AUTH STATUS & SESSION
// ========================================

/// Auth-Status prüfen (beim App-Start)
class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}

/// Token erneuern
class AuthTokenRefreshRequested extends AuthEvent {
  const AuthTokenRefreshRequested();
}

/// Logout
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
