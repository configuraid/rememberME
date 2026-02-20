import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage Keys
  static const _keyEmail = 'biometric_email';
  static const _keyPassword = 'biometric_password';
  static const _keyEnabled = 'biometric_enabled';

  // ========================================
  // CAPABILITY CHECK
  // ========================================

  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported && canCheck;
    } catch (e) {
      debugPrint('❌ BiometricService - isDeviceSupported error: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('❌ BiometricService - getAvailableBiometrics error: $e');
      return [];
    }
  }

  Future<bool> hasFaceId() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  Future<bool> hasFingerprint() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint);
  }

  // ========================================
  // BIOMETRIC AUTHENTICATION
  // ========================================

  Future<bool> authenticate({
    String reason = 'Bitte bestätige deine Identität',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint('❌ BiometricService - authenticate error: $e');
      return false;
    }
  }

  // ========================================
  // CREDENTIAL MANAGEMENT
  // ========================================

  /// Speichert Credentials UND aktiviert Biometrie.
  /// Verwendet bei erstmaliger Einrichtung (nach Registrierung).
  Future<bool> saveCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _secureStorage.write(key: _keyEmail, value: email);
      await _secureStorage.write(key: _keyPassword, value: password);
      await _secureStorage.write(key: _keyEnabled, value: 'true');
      debugPrint('✅ BiometricService - Credentials gespeichert + aktiviert');
      return true;
    } catch (e) {
      debugPrint('❌ BiometricService - saveCredentials error: $e');
      return false;
    }
  }

  /// Speichert/aktualisiert Credentials OHNE den enabled-Status zu ändern.
  /// Muss bei JEDEM erfolgreichen E-Mail/Passwort-Login aufgerufen werden,
  /// damit Credentials immer aktuell im Keychain liegen.
  Future<void> storeCredentialsQuietly({
    required String email,
    required String password,
  }) async {
    try {
      await _secureStorage.write(key: _keyEmail, value: email);
      await _secureStorage.write(key: _keyPassword, value: password);
      debugPrint(
          '✅ BiometricService - Credentials still aktualisiert (enabled unverändert)');
    } catch (e) {
      debugPrint('❌ BiometricService - storeCredentialsQuietly error: $e');
    }
  }

  /// Prüft ob Credentials im Keychain vorhanden sind
  /// (unabhängig vom enabled-Flag).
  Future<bool> hasStoredCredentials() async {
    try {
      final email = await _secureStorage.read(key: _keyEmail);
      final password = await _secureStorage.read(key: _keyPassword);
      return email != null && password != null;
    } catch (e) {
      debugPrint('❌ BiometricService - hasStoredCredentials error: $e');
      return false;
    }
  }

  /// Liest gespeicherte Credentials (nach erfolgreicher Biometrie!)
  Future<({String email, String password})?> getCredentials() async {
    try {
      final email = await _secureStorage.read(key: _keyEmail);
      final password = await _secureStorage.read(key: _keyPassword);

      if (email != null && password != null) {
        return (email: email, password: password);
      }
      return null;
    } catch (e) {
      debugPrint('❌ BiometricService - getCredentials error: $e');
      return null;
    }
  }

  /// Löscht ALLES — Credentials UND enabled-Flag.
  /// NUR bei Account-Löschung verwenden!
  Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: _keyEmail);
      await _secureStorage.delete(key: _keyPassword);
      await _secureStorage.write(key: _keyEnabled, value: 'false');
      debugPrint('✅ BiometricService - Alles gelöscht (Account-Löschung)');
    } catch (e) {
      debugPrint('❌ BiometricService - clearCredentials error: $e');
    }
  }

  // ========================================
  // STATUS & TOGGLE
  // ========================================

  /// Prüft ob biometrischer Login aktiviert UND funktionsfähig ist
  Future<bool> isBiometricLoginEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _keyEnabled);
      if (enabled != 'true') return false;

      final email = await _secureStorage.read(key: _keyEmail);
      final password = await _secureStorage.read(key: _keyPassword);
      return email != null && password != null;
    } catch (e) {
      debugPrint('❌ BiometricService - isBiometricLoginEnabled error: $e');
      return false;
    }
  }

  /// Aktiviert biometrischen Login (setzt nur das enabled-Flag).
  /// Voraussetzung: Credentials sind bereits im Keychain.
  Future<void> enableBiometricLogin() async {
    try {
      await _secureStorage.write(key: _keyEnabled, value: 'true');
      debugPrint('✅ BiometricService - Biometric Login aktiviert');
    } catch (e) {
      debugPrint('❌ BiometricService - enableBiometricLogin error: $e');
    }
  }

  /// Deaktiviert biometrischen Login.
  /// Setzt NUR das enabled-Flag — Credentials bleiben im Keychain,
  /// damit Re-Aktivierung sofort ohne erneutes Einloggen möglich ist.
  Future<void> disableBiometricLogin() async {
    try {
      await _secureStorage.write(key: _keyEnabled, value: 'false');
      // ⚠️ Credentials NICHT löschen!
      // Ermöglicht sofortige Re-Aktivierung über Toggle.
      debugPrint(
          '✅ BiometricService - Biometric Login deaktiviert (Credentials behalten)');
    } catch (e) {
      debugPrint('❌ BiometricService - disableBiometricLogin error: $e');
    }
  }

  // ========================================
  // CONVENIENCE: Full Biometric Login Flow
  // ========================================

  Future<({String email, String password})?> attemptBiometricLogin() async {
    final enabled = await isBiometricLoginEnabled();
    if (!enabled) return null;

    final supported = await isDeviceSupported();
    if (!supported) return null;

    final authenticated = await authenticate(
      reason: 'Mit Face ID anmelden',
    );
    if (!authenticated) return null;

    return await getCredentials();
  }

  Future<String> getBiometricTypeName() async {
    if (await hasFaceId()) return 'Face ID';
    if (await hasFingerprint()) return 'Fingerabdruck';
    return 'Biometrie';
  }
}
