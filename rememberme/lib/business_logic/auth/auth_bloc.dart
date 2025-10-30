import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthState.initial()) {
    // Login mit Auth-Key
    on<AuthLoginWithKeyRequested>(_onLoginWithKey);

    // Login mit QR-Code
    on<AuthLoginWithQRRequested>(_onLoginWithQR);

    // Logout
    on<AuthLogoutRequested>(_onLogout);

    // Profil aktualisieren
    on<AuthUpdateProfileRequested>(_onUpdateProfile);

    // Auth-Status prüfen
    on<AuthStatusChecked>(_onCheckAuthStatus);

    // Token erneuern
    on<AuthTokenRefreshRequested>(_onRefreshToken);
  }

  // Login mit Auth-Key Handler
  Future<void> _onLoginWithKey(
    AuthLoginWithKeyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    try {
      final user = await authRepository.loginWithAuthKey(event.authKey);

      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(AuthState.error(
            'Ungültiger Auth-Key. Bitte versuchen Sie es erneut.'));
      }
    } catch (e) {
      emit(AuthState.error('Fehler beim Anmelden: ${e.toString()}'));
    }
  }

  // Login mit QR-Code Handler
  Future<void> _onLoginWithQR(
    AuthLoginWithQRRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    try {
      final user = await authRepository.loginWithQRCode(event.qrCode);

      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(AuthState.error(
            'Ungültiger QR-Code. Bitte versuchen Sie es erneut.'));
      }
    } catch (e) {
      emit(AuthState.error('Fehler beim Anmelden: ${e.toString()}'));
    }
  }

  // Logout Handler
  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthState.loading());

    try {
      await authRepository.logout();
      emit(AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error('Fehler beim Abmelden: ${e.toString()}'));
    }
  }

  // Profil aktualisieren Handler
  Future<void> _onUpdateProfile(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.user == null) {
      emit(AuthState.error('Kein User eingeloggt'));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final updatedUser = await authRepository.updateUserProfile(
        name: event.name,
        email: event.email,
        profileImageUrl: event.profileImageUrl,
      );

      emit(AuthState.authenticated(updatedUser));
    } catch (e) {
      emit(AuthState.error(
          'Fehler beim Aktualisieren des Profils: ${e.toString()}'));
    }
  }

  // Auth-Status prüfen Handler
  Future<void> _onCheckAuthStatus(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isLoggedIn = authRepository.isLoggedIn;

      if (isLoggedIn && authRepository.currentUser != null) {
        emit(AuthState.authenticated(authRepository.currentUser!));
      } else {
        emit(AuthState.unauthenticated());
      }
    } catch (e) {
      emit(AuthState.error('Fehler beim Prüfen des Auth-Status'));
    }
  }

  // Token erneuern Handler
  Future<void> _onRefreshToken(
    AuthTokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authRepository.refreshAuthToken();

      if (authRepository.currentUser != null) {
        emit(AuthState.authenticated(authRepository.currentUser!));
      }
    } catch (e) {
      emit(AuthState.error('Fehler beim Erneuern des Tokens'));
    }
  }
}
