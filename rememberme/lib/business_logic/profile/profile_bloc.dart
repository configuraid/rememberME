import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// Profile Bloc
///
/// Verwaltet User-Profil, Settings und Statistiken.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;

  ProfileBloc({required this.profileRepository})
      : super(ProfileState.initial()) {
    on<ProfileLoadRequested>(_onLoadProfile);
    on<ProfileUpdateRequested>(_onUpdateProfile);
    on<ProfileImageUpdateRequested>(_onUpdateProfileImage);
    on<ProfileImageDeleteRequested>(_onDeleteProfileImage);
    on<ProfileSettingsLoadRequested>(_onLoadSettings);
    on<ProfileThemeChangeRequested>(_onChangeTheme);
    on<ProfileLanguageChangeRequested>(_onChangeLanguage);
    on<ProfileNotificationsUpdateRequested>(_onUpdateNotifications);
    on<ProfilePrivacyUpdateRequested>(_onUpdatePrivacy);
    on<ProfilePasswordChangeRequested>(_onChangePassword);
    on<ProfileDeleteAccountRequested>(_onDeleteAccount);
    on<ProfileStatisticsLoadRequested>(_onLoadStatistics);
  }

  // ========================================
  // LOAD PROFILE
  // ========================================

  Future<void> _onLoadProfile(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileState.loading());

    try {
      print('👤 ProfileBloc - Lade Profil: ${event.userId}');

      final settings = await profileRepository.getSettings(event.userId);
      final statistics = await profileRepository.getStatistics(event.userId);
      final profile = await profileRepository.getProfile(event.userId);

      print('✅ ProfileBloc - Profil geladen');
      emit(ProfileState.loaded(
        settings: settings,
        statistics: statistics,
        profileImageUrl: profile['avatarUrl'] as String?,
        displayName: profile['displayName'] as String?,
        email: profile['email'] as String?,
        phone: profile['phone'] as String?,
        bio: profile['bio'] as String?,
      ));
    } catch (e) {
      print('❌ ProfileBloc - Fehler: $e');
      emit(
          ProfileState.error('Fehler beim Laden des Profils: ${e.toString()}'));
    }
  }

  // ========================================
  // UPDATE PROFILE
  // ========================================

  Future<void> _onUpdateProfile(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating));

    try {
      print('📝 ProfileBloc - Aktualisiere Profil');

      await profileRepository.updateProfile(
        userId: event.userId,
        displayName: event.displayName,
        email: event.email,
        phone: event.phone,
        bio: event.bio,
      );

      print('✅ ProfileBloc - Profil aktualisiert');
      emit(state.copyWith(
        status: ProfileStatus.success,
        successMessage: 'Profil erfolgreich aktualisiert',
        displayName: event.displayName,
        email: event.email,
        phone: event.phone,
        bio: event.bio,
      ));
    } catch (e) {
      print('❌ ProfileBloc - Fehler: $e');
      emit(ProfileState.error('Fehler beim Aktualisieren: ${e.toString()}'));
    }
  }

  // ========================================
  // PROFILE IMAGE
  // ========================================

  Future<void> _onUpdateProfileImage(
    ProfileImageUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating));

    try {
      print('📷 ProfileBloc - Aktualisiere Profilbild');

      final imageUrl = await profileRepository.updateProfileImage(
        userId: event.userId,
        imagePath: event.imagePath,
      );

      print('✅ ProfileBloc - Profilbild aktualisiert');
      emit(state.copyWith(
        status: ProfileStatus.success,
        successMessage: 'Profilbild erfolgreich aktualisiert',
        profileImageUrl: imageUrl,
      ));
    } catch (e) {
      print('❌ ProfileBloc - Fehler: $e');
      emit(ProfileState.error(
          'Fehler beim Aktualisieren des Profilbilds: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteProfileImage(
    ProfileImageDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating));

    try {
      await profileRepository.deleteProfileImage(event.userId);

      emit(state.copyWith(
        status: ProfileStatus.success,
        successMessage: 'Profilbild gelöscht',
        clearProfileImage: true,
      ));
    } catch (e) {
      emit(ProfileState.error('Fehler: ${e.toString()}'));
    }
  }

  // ========================================
  // SETTINGS
  // ========================================

  Future<void> _onLoadSettings(
    ProfileSettingsLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final settings = await profileRepository.getSettings(event.userId);
      emit(state.copyWith(settings: settings));
    } catch (e) {
      emit(ProfileState.error(
          'Fehler beim Laden der Einstellungen: ${e.toString()}'));
    }
  }

  Future<void> _onChangeTheme(
    ProfileThemeChangeRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await profileRepository.updateTheme(event.userId, event.themeMode);

      final updatedSettings =
          state.settings.copyWith(themeMode: event.themeMode);

      emit(state.copyWith(
        settings: updatedSettings,
        status: ProfileStatus.success,
        successMessage: 'Theme erfolgreich geändert',
      ));
    } catch (e) {
      emit(
          ProfileState.error('Fehler beim Ändern des Themes: ${e.toString()}'));
    }
  }

  Future<void> _onChangeLanguage(
    ProfileLanguageChangeRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await profileRepository.updateLanguage(event.userId, event.languageCode);

      final updatedSettings =
          state.settings.copyWith(languageCode: event.languageCode);

      emit(state.copyWith(
        settings: updatedSettings,
        status: ProfileStatus.success,
        successMessage: 'Sprache erfolgreich geändert',
      ));
    } catch (e) {
      emit(ProfileState.error(
          'Fehler beim Ändern der Sprache: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateNotifications(
    ProfileNotificationsUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await profileRepository.updateNotificationSettings(
        userId: event.userId,
        pushEnabled: event.pushEnabled,
        emailEnabled: event.emailEnabled,
        memorialUpdates: event.memorialUpdates,
        groupInvites: event.groupInvites,
      );

      final updatedSettings = state.settings.copyWith(
        pushNotifications: event.pushEnabled,
        emailNotifications: event.emailEnabled,
        memorialUpdates: event.memorialUpdates,
        groupInvites: event.groupInvites,
      );

      emit(state.copyWith(
        settings: updatedSettings,
        status: ProfileStatus.success,
        successMessage: 'Benachrichtigungseinstellungen aktualisiert',
      ));
    } catch (e) {
      emit(ProfileState.error('Fehler: ${e.toString()}'));
    }
  }

  Future<void> _onUpdatePrivacy(
    ProfilePrivacyUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await profileRepository.updatePrivacySettings(
        userId: event.userId,
        profilePublic: event.profilePublic,
        showEmail: event.showEmail,
        allowSearchEngines: event.allowSearchEngines,
      );

      final updatedSettings = state.settings.copyWith(
        profilePublic: event.profilePublic,
        showEmail: event.showEmail,
        allowSearchEngines: event.allowSearchEngines,
      );

      emit(state.copyWith(
        settings: updatedSettings,
        status: ProfileStatus.success,
        successMessage: 'Datenschutzeinstellungen aktualisiert',
      ));
    } catch (e) {
      emit(ProfileState.error('Fehler: ${e.toString()}'));
    }
  }

  // ========================================
  // PASSWORD
  // ========================================

  Future<void> _onChangePassword(
    ProfilePasswordChangeRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating));

    try {
      await profileRepository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      emit(state.copyWith(
        status: ProfileStatus.success,
        successMessage: 'Passwort erfolgreich geändert',
      ));
    } catch (e) {
      emit(ProfileState.error(
          'Fehler beim Ändern des Passworts: ${e.toString()}'));
    }
  }

  // ========================================
  // DELETE ACCOUNT
  // ========================================

  Future<void> _onDeleteAccount(
    ProfileDeleteAccountRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating));

    try {
      await profileRepository.deleteAccount(
        userId: event.userId,
        password: event.password,
      );

      emit(ProfileState.deleted());
    } catch (e) {
      emit(ProfileState.error(
          'Fehler beim Löschen des Accounts: ${e.toString()}'));
    }
  }

  // ========================================
  // STATISTICS
  // ========================================

  Future<void> _onLoadStatistics(
    ProfileStatisticsLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final statistics = await profileRepository.getStatistics(event.userId);
      emit(state.copyWith(statistics: statistics));
    } catch (e) {
      emit(ProfileState.error(
          'Fehler beim Laden der Statistiken: ${e.toString()}'));
    }
  }
}
