import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;

  ProfileBloc({required this.profileRepository})
      : super(ProfileState.initial()) {
    on<ProfileLoadRequested>(_onLoadProfile);
    on<ProfileUpdateRequested>(_onUpdateProfile);
    on<ProfileImageUpdateRequested>(_onUpdateProfileImage);
    on<ProfileSettingsLoadRequested>(_onLoadSettings);
    on<ProfileThemeChangeRequested>(_onChangeTheme);
    on<ProfileLanguageChangeRequested>(_onChangeLanguage);
    on<ProfileNotificationsUpdateRequested>(_onUpdateNotifications);
    on<ProfilePrivacyUpdateRequested>(_onUpdatePrivacy);
    on<ProfilePasswordChangeRequested>(_onChangePassword);
    on<ProfileDeleteAccountRequested>(_onDeleteAccount);
    on<ProfileStatisticsLoadRequested>(_onLoadStatistics);
  }

  Future<void> _onLoadProfile(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileState.loading());

    try {
      final settings = await profileRepository.getSettings(event.userId);
      final statistics = await profileRepository.getStatistics(event.userId);
      final profile = await profileRepository.getProfile(event.userId);

      emit(ProfileState.loaded(
        settings: settings,
        statistics: statistics,
        profileImageUrl: profile['imageUrl'],
        name: profile['name'],
        email: profile['email'],
        phone: profile['phone'],
        bio: profile['bio'],
      ));
    } catch (e) {
      emit(
          ProfileState.error('Fehler beim Laden des Profils: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProfile(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating));

    try {
      await profileRepository.updateProfile(
        userId: event.userId,
        name: event.name,
        email: event.email,
        phone: event.phone,
        bio: event.bio,
      );

      emit(state.copyWith(
        status: ProfileStatus.success,
        successMessage: 'Profil erfolgreich aktualisiert',
        name: event.name,
        email: event.email,
        phone: event.phone,
        bio: event.bio,
      ));
    } catch (e) {
      emit(ProfileState.error(
          'Fehler beim Aktualisieren des Profils: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProfileImage(
    ProfileImageUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating));

    try {
      final imageUrl = await profileRepository.updateProfileImage(
        userId: event.userId,
        imagePath: event.imagePath,
      );

      emit(state.copyWith(
        status: ProfileStatus.success,
        successMessage: 'Profilbild erfolgreich aktualisiert',
        profileImageUrl: imageUrl,
      ));
    } catch (e) {
      emit(ProfileState.error(
          'Fehler beim Aktualisieren des Profilbilds: ${e.toString()}'));
    }
  }

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
      emit(ProfileState.error(
          'Fehler beim Aktualisieren der Benachrichtigungen: ${e.toString()}'));
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
      emit(ProfileState.error(
          'Fehler beim Aktualisieren der Datenschutzeinstellungen: ${e.toString()}'));
    }
  }

  Future<void> _onChangePassword(
    ProfilePasswordChangeRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating));

    try {
      await profileRepository.changePassword(
        userId: event.userId,
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

      emit(state.copyWith(
        status: ProfileStatus.success,
        successMessage: 'Account erfolgreich gelöscht',
      ));
    } catch (e) {
      emit(ProfileState.error(
          'Fehler beim Löschen des Accounts: ${e.toString()}'));
    }
  }

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
