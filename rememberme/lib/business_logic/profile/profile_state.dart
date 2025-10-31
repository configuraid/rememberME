import 'package:equatable/equatable.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  updating,
  success,
  error,
}

class ProfileSettings {
  final String themeMode;
  final String languageCode;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool memorialUpdates;
  final bool groupInvites;
  final bool profilePublic;
  final bool showEmail;
  final bool allowSearchEngines;

  const ProfileSettings({
    this.themeMode = 'system',
    this.languageCode = 'de',
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.memorialUpdates = true,
    this.groupInvites = true,
    this.profilePublic = false,
    this.showEmail = false,
    this.allowSearchEngines = false,
  });

  ProfileSettings copyWith({
    String? themeMode,
    String? languageCode,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? memorialUpdates,
    bool? groupInvites,
    bool? profilePublic,
    bool? showEmail,
    bool? allowSearchEngines,
  }) {
    return ProfileSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      memorialUpdates: memorialUpdates ?? this.memorialUpdates,
      groupInvites: groupInvites ?? this.groupInvites,
      profilePublic: profilePublic ?? this.profilePublic,
      showEmail: showEmail ?? this.showEmail,
      allowSearchEngines: allowSearchEngines ?? this.allowSearchEngines,
    );
  }
}

class ProfileStatistics {
  final int totalMemorials;
  final int publishedMemorials;
  final int totalViews;
  final int totalCondolences;
  final int groupMemberships;
  final DateTime memberSince;

  const ProfileStatistics({
    this.totalMemorials = 0,
    this.publishedMemorials = 0,
    this.totalViews = 0,
    this.totalCondolences = 0,
    this.groupMemberships = 0,
    required this.memberSince,
  });
}

class ProfileState extends Equatable {
  final ProfileStatus status;
  final ProfileSettings settings;
  final ProfileStatistics? statistics;
  final String? errorMessage;
  final String? successMessage;
  final String? profileImageUrl;
  final String? name;
  final String? email;
  final String? phone;
  final String? bio;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.settings = const ProfileSettings(),
    this.statistics,
    this.errorMessage,
    this.successMessage,
    this.profileImageUrl,
    this.name,
    this.email,
    this.phone,
    this.bio,
  });

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
    String? name,
    String? email,
    String? phone,
    String? bio,
  }) {
    return ProfileState(
      status: ProfileStatus.loaded,
      settings: settings,
      statistics: statistics,
      profileImageUrl: profileImageUrl,
      name: name,
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

  bool get isLoading =>
      status == ProfileStatus.loading || status == ProfileStatus.updating;
  bool get hasError => status == ProfileStatus.error;
  bool get isSuccess => status == ProfileStatus.success;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileSettings? settings,
    ProfileStatistics? statistics,
    String? errorMessage,
    String? successMessage,
    String? profileImageUrl,
    String? name,
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
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      name: name ?? this.name,
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
        name,
        email,
        phone,
        bio,
      ];
}
