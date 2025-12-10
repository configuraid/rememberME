import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class QrDecryptionService {
  static QrDecryptionService? _instance;
  static encrypt.Key? _encryptionKey;
  static bool _isInitialized = false;

  QrDecryptionService._();

  static QrDecryptionService get instance {
    _instance ??= QrDecryptionService._();
    return _instance!;
  }

  /// Prüft ob der Service initialisiert ist
  bool get isInitialized => _isInitialized;

  /// Initialisiert den Service und lädt den Encryption Key von Firebase
  ///
  /// Muss einmal beim App-Start aufgerufen werden!
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('encryption')
          .get();

      if (!doc.exists) {
        throw Exception('Encryption config not found in Firestore');
      }

      final keyBase64 = doc.data()?['qrEncryptionKey'] as String?;

      if (keyBase64 == null || keyBase64.isEmpty) {
        throw Exception('qrEncryptionKey field is missing or empty');
      }

      _encryptionKey = encrypt.Key.fromBase64(keyBase64);
      _isInitialized = true;

      print('✅ QrDecryptionService initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize QrDecryptionService: $e');
      rethrow;
    }
  }

  /// Entschlüsselt einen QR-Code Wert und gibt den authKey zurück
  ///
  /// Format des verschlüsselten Wertes: base64(iv):base64(encrypted)
  ///
  /// Returns: authKey als String oder null bei Fehler
  String? decrypt(String encryptedValue) {
    if (!_isInitialized || _encryptionKey == null) {
      print('❌ QrDecryptionService not initialized! Call initialize() first.');
      return null;
    }

    try {
      // Format prüfen
      final parts = encryptedValue.split(':');
      if (parts.length != 2) {
        print('❌ Invalid encrypted format: expected "iv:encrypted"');
        return null;
      }

      // IV und verschlüsselte Daten extrahieren
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

      // Entschlüsseln
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_encryptionKey!, mode: encrypt.AESMode.cbc),
      );

      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      print('✅ QR-Code successfully decrypted');
      return decrypted;
    } catch (e) {
      print('❌ Decryption error: $e');
      return null;
    }
  }

  /// Prüft ob ein QR-Code Wert gültig verschlüsselt ist
  bool isValidFormat(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return false;

    try {
      base64Decode(parts[0]);
      base64Decode(parts[1]);
      return true;
    } catch (e) {
      return false;
    }
  }
}
