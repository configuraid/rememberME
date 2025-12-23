import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

// ========================================
// PROFILE LOAD
// ========================================

/// Profil laden
class ProfileLoadRequested extends ProfileEvent {
  final String userId;

  const ProfileLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

// ========================================
// PROFILE UPDATE
// ========================================

/// Profil aktualisieren
class ProfileUpdateRequested extends ProfileEvent {
  final String userId;
  final String? displayName;
  final String? email;
  final String? phone;
  final String? bio;

  const ProfileUpdateRequested({
    required this.userId,
    this.displayName,
    this.email,
    this.phone,
    this.bio,
  });

  @override
  List<Object?> get props => [userId, displayName, email, phone, bio];
}

/// Profilbild aktualisieren
class ProfileImageUpdateRequested extends ProfileEvent {
  final String userId;
  final String imagePath;

  const ProfileImageUpdateRequested({
    required this.userId,
    required this.imagePath,
  });

  @override
  List<Object?> get props => [userId, imagePath];
}

/// Profilbild löschen
class ProfileImageDeleteRequested extends ProfileEvent {
  final String userId;

  const ProfileImageDeleteRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

// ========================================
// SETTINGS
// ========================================

/// Einstellungen laden
class ProfileSettingsLoadRequested extends ProfileEvent {
  final String userId;

  const ProfileSettingsLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Theme ändern
class ProfileThemeChangeRequested extends ProfileEvent {
  final String userId;
  final String themeMode; // 'light', 'dark', 'system'

  const ProfileThemeChangeRequested({
    required this.userId,
    required this.themeMode,
  });

  @override
  List<Object?> get props => [userId, themeMode];
}

/// Sprache ändern
class ProfileLanguageChangeRequested extends ProfileEvent {
  final String userId;
  final String languageCode; // 'de', 'en'

  const ProfileLanguageChangeRequested({
    required this.userId,
    required this.languageCode,
  });

  @override
  List<Object?> get props => [userId, languageCode];
}

/// Benachrichtigungen aktualisieren
class ProfileNotificationsUpdateRequested extends ProfileEvent {
  final String userId;
  final bool? pushEnabled;
  final bool? emailEnabled;
  final bool? memorialUpdates;
  final bool? groupInvites;

  const ProfileNotificationsUpdateRequested({
    required this.userId,
    this.pushEnabled,
    this.emailEnabled,
    this.memorialUpdates,
    this.groupInvites,
  });

  @override
  List<Object?> get props =>
      [userId, pushEnabled, emailEnabled, memorialUpdates, groupInvites];
}

/// Datenschutzeinstellungen aktualisieren
class ProfilePrivacyUpdateRequested extends ProfileEvent {
  final String userId;
  final bool? profilePublic;
  final bool? showEmail;
  final bool? allowSearchEngines;

  const ProfilePrivacyUpdateRequested({
    required this.userId,
    this.profilePublic,
    this.showEmail,
    this.allowSearchEngines,
  });

  @override
  List<Object?> get props =>
      [userId, profilePublic, showEmail, allowSearchEngines];
}

// ========================================
// PASSWORD & ACCOUNT
// ========================================

/// Passwort ändern
class ProfilePasswordChangeRequested extends ProfileEvent {
  final String currentPassword;
  final String newPassword;

  const ProfilePasswordChangeRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

/// Account löschen
class ProfileDeleteAccountRequested extends ProfileEvent {
  final String userId;
  final String password;

  const ProfileDeleteAccountRequested({
    required this.userId,
    required this.password,
  });

  @override
  List<Object?> get props => [userId, password];
}

// ========================================
// STATISTICS
// ========================================

/// Statistiken laden
class ProfileStatisticsLoadRequested extends ProfileEvent {
  final String userId;

  const ProfileStatisticsLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}
