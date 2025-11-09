import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthState.initial()) {
    // Auth Key / QR Code Login
    on<AuthLoginWithKeyRequested>(_onLoginWithKey);
    on<AuthLoginWithQRRequested>(_onLoginWithQR);

    // User Selection & Profile Creation
    on<AuthUserSelectionRequested>(_onUserSelection);
    on<AuthNewProfileCreationRequested>(_onNewProfileCreation);

    // Profile Management
    on<AuthUpdateProfileRequested>(_onUpdateProfile);

    // Auth Status & Session
    on<AuthStatusChecked>(_onCheckAuthStatus);
    on<AuthTokenRefreshRequested>(_onRefreshToken);
    on<AuthLogoutRequested>(_onLogout);

    // Auth-Status beim App-Start prüfen
    add(const AuthStatusChecked());
  }

  // ========================================
  // AUTH KEY / QR CODE LOGIN
  // ========================================

  /// Login mit Auth-Key Handler
  /// Authentifiziert Organisation, gibt aber KEINEN User zurück
  /// User muss danach im UserSelectionScreen ausgewählt werden
  Future<void> _onLoginWithKey(
    AuthLoginWithKeyRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔐 AuthBloc - Login mit Auth-Key: ${event.authKey}');
    emit(AuthState.loading());

    try {
      // Organisation authentifizieren (gibt Organisation zurück, KEINEN User!)
      final organization = await authRepository.loginWithAuthKey(event.authKey);

      if (organization != null) {
        print('✅ AuthBloc - Organisation gefunden: ${organization.name}');
        // Wir emittieren NICHT authenticated hier!
        // Der LoginScreen navigiert zum UserSelectionScreen
        emit(AuthState.unauthenticated());
      } else {
        print('❌ AuthBloc - Ungültiger Auth-Key');
        emit(AuthState.error(
            'Ungültiger Auth-Key. Bitte versuchen Sie es erneut.'));
      }
    } catch (e) {
      print('❌ AuthBloc - Fehler beim Login: $e');
      emit(AuthState.error('Fehler beim Anmelden: ${e.toString()}'));
    }
  }

  /// Login mit QR-Code Handler
  /// Authentifiziert Organisation, gibt aber KEINEN User zurück
  /// User muss danach im UserSelectionScreen ausgewählt werden
  Future<void> _onLoginWithQR(
    AuthLoginWithQRRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('📷 AuthBloc - Login mit QR-Code');
    emit(AuthState.loading());

    try {
      // Organisation authentifizieren (gibt Organisation zurück, KEINEN User!)
      final organization = await authRepository.loginWithQRCode(event.qrCode);

      if (organization != null) {
        print('✅ AuthBloc - Organisation gefunden: ${organization.name}');
        // Wir emittieren NICHT authenticated hier!
        // Der LoginScreen navigiert zum UserSelectionScreen
        emit(AuthState.unauthenticated());
      } else {
        print('❌ AuthBloc - Ungültiger QR-Code');
        emit(AuthState.error(
            'Ungültiger QR-Code. Bitte versuchen Sie es erneut.'));
      }
    } catch (e) {
      print('❌ AuthBloc - Fehler beim QR-Login: $e');
      emit(AuthState.error('Fehler beim Anmelden: ${e.toString()}'));
    }
  }

  // ========================================
  // USER SELECTION & PROFILE CREATION
  // ========================================

  /// User Selection Handler
  /// Wählt existierenden User aus Organisation aus
  Future<void> _onUserSelection(
    AuthUserSelectionRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('👤 AuthBloc - User Selection: ${event.userId}');
    print('📍 Organisation: ${event.organizationId}');
    if (event.pin != null) print('🔒 Mit PIN-Schutz');

    emit(AuthState.loading());

    try {
      // User auswählen und authentifizieren
      final user = await authRepository.selectUser(
        organizationId: event.organizationId,
        userId: event.userId,
        pin: event.pin,
      );

      if (user != null) {
        print('✅ AuthBloc - User erfolgreich ausgewählt: ${user.name}');
        emit(AuthState.authenticated(user));
      } else {
        print('❌ AuthBloc - User nicht gefunden oder falsche PIN');
        emit(AuthState.error(
            'Benutzer konnte nicht gefunden werden oder PIN ist falsch.'));
      }
    } catch (e) {
      print('❌ AuthBloc - Fehler bei User Selection: $e');

      // Spezifische Fehlermeldungen
      if (e.toString().contains('PIN')) {
        emit(AuthState.error('Falsche PIN. Bitte versuchen Sie es erneut.'));
      } else {
        emit(AuthState.error('Fehler beim Anmelden: ${e.toString()}'));
      }
    }
  }

  /// Neues Profil erstellen Handler
  /// Erstellt neuen User in Organisation
  Future<void> _onNewProfileCreation(
    AuthNewProfileCreationRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('➕ AuthBloc - Neues Profil erstellen: ${event.name}');
    print('📍 Organisation: ${event.organizationId}');
    print('📧 E-Mail: ${event.email}');
    if (event.pin != null) print('🔒 Mit PIN-Schutz');

    emit(AuthState.loading());

    try {
      // Neues Profil erstellen
      final user = await authRepository.createNewProfile(
        organizationId: event.organizationId,
        name: event.name,
        email: event.email,
        pin: event.pin,
      );

      if (user != null) {
        print('✅ AuthBloc - Profil erfolgreich erstellt: ${user.name}');
        emit(AuthState.authenticated(user));
      } else {
        print('❌ AuthBloc - Profil konnte nicht erstellt werden');
        emit(AuthState.error('Profil konnte nicht erstellt werden.'));
      }
    } catch (e) {
      print('❌ AuthBloc - Fehler bei Profil-Erstellung: $e');
      emit(AuthState.error(
          'Fehler beim Erstellen des Profils: ${e.toString()}'));
    }
  }

  // ========================================
  // PROFILE MANAGEMENT
  // ========================================

  /// Profil aktualisieren Handler
  Future<void> _onUpdateProfile(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.user == null) {
      print('❌ AuthBloc - Update Profil: Kein User eingeloggt');
      emit(AuthState.error('Kein Benutzer eingeloggt'));
      return;
    }

    print('📝 AuthBloc - Update Profil: ${state.user!.name}');
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final updatedUser = await authRepository.updateUserProfile(
        userId: state.user!.id,
        name: event.name,
        email: event.email,
        profileImageUrl: event.profileImageUrl,
      );

      print('✅ AuthBloc - Profil erfolgreich aktualisiert');
      emit(AuthState.authenticated(updatedUser));
    } catch (e) {
      print('❌ AuthBloc - Fehler beim Update: $e');
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Fehler beim Aktualisieren des Profils: ${e.toString()}',
      ));
    }
  }

  // ========================================
  // AUTH STATUS & SESSION
  // ========================================

  /// Auth-Status prüfen Handler
  /// Wird beim App-Start aufgerufen
  Future<void> _onCheckAuthStatus(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    print('🔍 AuthBloc - Prüfe Auth-Status...');
    emit(AuthState.loading());

    try {
      final user = await authRepository.checkAuthStatus();

      if (user != null) {
        print('✅ AuthBloc - User ist eingeloggt: ${user.name}');
        emit(AuthState.authenticated(user));
      } else {
        print('ℹ️ AuthBloc - Kein User eingeloggt');
        emit(AuthState.unauthenticated());
      }
    } catch (e) {
      print('❌ AuthBloc - Fehler beim Status-Check: $e');
      emit(AuthState.unauthenticated());
    }
  }

  /// Token erneuern Handler
  Future<void> _onRefreshToken(
    AuthTokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔄 AuthBloc - Token erneuern...');

    try {
      await authRepository.refreshAuthToken();

      if (authRepository.currentUser != null) {
        print('✅ AuthBloc - Token erfolgreich erneuert');
        emit(AuthState.authenticated(authRepository.currentUser!));
      }
    } catch (e) {
      print('❌ AuthBloc - Fehler beim Token-Refresh: $e');
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Fehler beim Erneuern des Tokens: ${e.toString()}',
      ));
    }
  }

  /// Logout Handler
  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('👋 AuthBloc - Logout...');
    emit(AuthState.loading());

    try {
      await authRepository.logout();
      print('✅ AuthBloc - Logout erfolgreich');
      emit(AuthState.unauthenticated());
    } catch (e) {
      print('❌ AuthBloc - Fehler beim Logout: $e');
      emit(AuthState.error('Fehler beim Abmelden: ${e.toString()}'));
    }
  }
}
