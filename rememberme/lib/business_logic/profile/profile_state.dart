import 'package:equatable/equatable.dart';
import '../../data/repositories/profile_repository.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  updating,
  success,
  error,
  deleted,
}

class ProfileState extends Equatable {
  final ProfileStatus status;
  final ProfileSettings settings;
  final ProfileStatistics? statistics;
  final String? errorMessage;
  final String? successMessage;
  final String? profileImageUrl;
  final String? displayName;
  final String? email;
  final String? phone;
  final String? bio;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.settings = const ProfileSettings(
      themeMode: 'system',
      languageCode: 'de',
      pushNotifications: true,
      emailNotifications: true,
      memorialUpdates: true,
      groupInvites: true,
      profilePublic: false,
      showEmail: false,
      allowSearchEngines: false,
    ),
    this.statistics,
    this.errorMessage,
    this.successMessage,
    this.profileImageUrl,
    this.displayName,
    this.email,
    this.phone,
    this.bio,
  });

  // ========================================
  // FACTORY CONSTRUCTORS
  // ========================================

  factory ProfileState.initial() {
    return const ProfileState(status: ProfileStatus.initial);
  }

  factory ProfileState.loading() {
    return const ProfileState(status: ProfileStatus.loading);
  }

  factory ProfileState.loaded({
    required ProfileSettings settings,
    ProfileStatistics? statistics,
    String? profileImageUrl,
    String? displayName,
    String? email,
    String? phone,
    String? bio,
  }) {
    return ProfileState(
      status: ProfileStatus.loaded,
      settings: settings,
      statistics: statistics,
      profileImageUrl: profileImageUrl,
      displayName: displayName,
      email: email,
      phone: phone,
      bio: bio,
    );
  }

  factory ProfileState.success(String message) {
    return ProfileState(
      status: ProfileStatus.success,
      successMessage: message,
    );
  }

  factory ProfileState.error(String message) {
    return ProfileState(
      status: ProfileStatus.error,
      errorMessage: message,
    );
  }

  factory ProfileState.deleted() {
    return const ProfileState(
      status: ProfileStatus.deleted,
      successMessage: 'Account erfolgreich gelöscht',
    );
  }

  // ========================================
  // GETTERS
  // ========================================

  bool get isLoading =>
      status == ProfileStatus.loading || status == ProfileStatus.updating;
  bool get hasError => status == ProfileStatus.error;
  bool get isSuccess => status == ProfileStatus.success;
  bool get isDeleted => status == ProfileStatus.deleted;
  bool get hasProfileImage =>
      profileImageUrl != null && profileImageUrl!.isNotEmpty;

  /// Initialen für Avatar-Fallback
  String get initials {
    if (displayName == null || displayName!.isEmpty) return '?';
    final parts = displayName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName![0].toUpperCase();
  }

  // ========================================
  // COPY WITH
  // ========================================

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileSettings? settings,
    ProfileStatistics? statistics,
    String? errorMessage,
    String? successMessage,
    String? profileImageUrl,
    bool clearProfileImage = false,
    String? displayName,
    String? email,
    String? phone,
    String? bio,
  }) {
    return ProfileState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      statistics: statistics ?? this.statistics,
      errorMessage: errorMessage,
      successMessage: successMessage,
      profileImageUrl:
          clearProfileImage ? null : (profileImageUrl ?? this.profileImageUrl),
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
    );
  }

  @override
  List<Object?> get props => [
        status,
        settings,
        statistics,
        errorMessage,
        successMessage,
        profileImageUrl,
        displayName,
        email,
        phone,
        bio,
      ];

  @override
  String toString() {
    return 'ProfileState(status: $status, displayName: $displayName)';
  }
}
