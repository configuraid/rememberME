import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth Bloc
///
/// Email/Password Authentifizierung
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthState.initial()) {
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLoginRequested>(_onLogin);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthUpdateProfileRequested>(_onUpdateProfile);
    on<AuthStatusChecked>(_onCheckAuthStatus);
    on<AuthDeleteAccountRequested>(_onDeleteAccount);

    // Beim App-Start Auth-Status prüfen
    add(const AuthStatusChecked());
  }

  // ========================================
  // REGISTER
  // ========================================

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('📝 AuthBloc - Registrierung: ${event.email}');
    emit(AuthState.loading());

    try {
      final user = await authRepository.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );

      print('✅ AuthBloc - Registrierung erfolgreich: ${user.displayName}');
      emit(AuthState.authenticated(user));
    } catch (e) {
      print('❌ AuthBloc - Registrierung fehlgeschlagen: $e');
      emit(AuthState.error(_mapFirebaseError(e.toString())));
    }
  }

  // ========================================
  // LOGIN
  // ========================================

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔐 AuthBloc - Login: ${event.email}');
    emit(AuthState.loading());

    try {
      final user = await authRepository.login(
        email: event.email,
        password: event.password,
      );

      print('✅ AuthBloc - Login erfolgreich: ${user.displayName}');
      emit(AuthState.authenticated(user));
    } catch (e) {
      print('❌ AuthBloc - Login fehlgeschlagen: $e');
      emit(AuthState.error(_mapFirebaseError(e.toString())));
    }
  }

  // ========================================
  // LOGOUT
  // ========================================

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('👋 AuthBloc - Logout');
    emit(AuthState.loading());

    try {
      await authRepository.logout();
      print('✅ AuthBloc - Logout erfolgreich');
      emit(AuthState.unauthenticated());
    } catch (e) {
      print('❌ AuthBloc - Logout fehlgeschlagen: $e');
      emit(AuthState.error('Fehler beim Abmelden'));
    }
  }

  // ========================================
  // PASSWORD RESET
  // ========================================

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔑 AuthBloc - Password Reset: ${event.email}');

    try {
      await authRepository.sendPasswordResetEmail(event.email);
      print('✅ AuthBloc - Password Reset Email gesendet');

      emit(state.copyWith(
        successMessage: 'E-Mail zum Zurücksetzen wurde gesendet',
      ));
    } catch (e) {
      print('❌ AuthBloc - Password Reset fehlgeschlagen: $e');
      emit(state.copyWith(
        errorMessage: _mapFirebaseError(e.toString()),
      ));
    }
  }

  // ========================================
  // UPDATE PROFILE
  // ========================================

  Future<void> _onUpdateProfile(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.user == null) {
      emit(AuthState.error('Kein Benutzer angemeldet'));
      return;
    }

    print('📝 AuthBloc - Update Profile');

    try {
      final updatedUser = await authRepository.updateProfile(
        userId: state.user!.id,
        displayName: event.displayName,
        avatarUrl: event.avatarUrl,
      );

      print('✅ AuthBloc - Profil aktualisiert');
      emit(AuthState.authenticated(updatedUser));
    } catch (e) {
      print('❌ AuthBloc - Profil Update fehlgeschlagen: $e');
      emit(state.copyWith(
        errorMessage: 'Fehler beim Aktualisieren des Profils',
      ));
    }
  }

  // ========================================
  // CHECK AUTH STATUS
  // ========================================

  Future<void> _onCheckAuthStatus(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    print('🔍 AuthBloc - Prüfe Auth-Status');
    emit(AuthState.loading());

    try {
      final user = await authRepository.getCurrentUser();

      if (user != null) {
        print('✅ AuthBloc - User eingeloggt: ${user.displayName}');
        emit(AuthState.authenticated(user));
      } else {
        print('ℹ️ AuthBloc - Kein User eingeloggt');
        emit(AuthState.unauthenticated());
      }
    } catch (e) {
      print('❌ AuthBloc - Auth-Status Check fehlgeschlagen: $e');
      emit(AuthState.unauthenticated());
    }
  }

  // ========================================
  // DELETE ACCOUNT
  // ========================================

  Future<void> _onDeleteAccount(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🗑️ AuthBloc - Account löschen');
    emit(AuthState.loading());

    try {
      await authRepository.deleteAccount();
      print('✅ AuthBloc - Account gelöscht');
      emit(AuthState.unauthenticated());
    } catch (e) {
      print('❌ AuthBloc - Account löschen fehlgeschlagen: $e');
      emit(AuthState.error(_mapFirebaseError(e.toString())));
    }
  }

  // ========================================
  // HELPER
  // ========================================

  String _mapFirebaseError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Diese E-Mail-Adresse wird bereits verwendet';
    }
    if (error.contains('invalid-email')) {
      return 'Ungültige E-Mail-Adresse';
    }
    if (error.contains('weak-password')) {
      return 'Das Passwort ist zu schwach (min. 6 Zeichen)';
    }
    if (error.contains('user-not-found')) {
      return 'Kein Benutzer mit dieser E-Mail gefunden';
    }
    if (error.contains('wrong-password')) {
      return 'Falsches Passwort';
    }
    if (error.contains('invalid-credential')) {
      return 'E-Mail oder Passwort ist falsch';
    }
    if (error.contains('too-many-requests')) {
      return 'Zu viele Versuche. Bitte später erneut versuchen';
    }
    if (error.contains('network-request-failed')) {
      return 'Keine Internetverbindung';
    }
    if (error.contains('requires-recent-login')) {
      return 'Bitte erneut einloggen um diese Aktion durchzuführen';
    }
    return 'Ein Fehler ist aufgetreten. Bitte erneut versuchen';
  }
}
