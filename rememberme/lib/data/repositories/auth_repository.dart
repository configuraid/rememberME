import '../models/user_model.dart';

class AuthRepository {
  // Mock-Daten für Entwicklung
  // Später durch Firebase Authentication ersetzen

  final List<UserModel> _mockUsers = [
    UserModel(
      id: 'user-1',
      name: 'Max Mustermann',
      email: 'max@example.com',
      authKey: 'DEMO-AUTH-KEY-12345',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now(),
      role: UserRole.owner,
    ),
    UserModel(
      id: 'user-2',
      name: 'Anna Schmidt',
      email: 'anna@example.com',
      authKey: 'TEST-KEY-67890',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      lastLoginAt: DateTime.now().subtract(const Duration(days: 2)),
      role: UserRole.owner,
    ),
  ];

  UserModel? _currentUser;

  // Getter für aktuellen User
  UserModel? get currentUser => _currentUser;

  // Login mit Auth-Key
  Future<UserModel?> loginWithAuthKey(String authKey) async {
    // Simuliere Netzwerk-Delay
    await Future.delayed(const Duration(seconds: 1));

    try {
      final user = _mockUsers.firstWhere(
        (user) => user.authKey == authKey,
        orElse: () => throw Exception('Ungültiger Auth-Key'),
      );

      _currentUser = user.copyWith(lastLoginAt: DateTime.now());
      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  // Login mit QR-Code
  Future<UserModel?> loginWithQRCode(String qrCode) async {
    // QR-Code enthält den Auth-Key
    return loginWithAuthKey(qrCode);
  }

  // Logout
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  // Prüfen ob User eingeloggt ist
  bool get isLoggedIn => _currentUser != null;

  // User-Profil aktualisieren
  Future<UserModel> updateUserProfile({
    String? name,
    String? email,
    String? profileImageUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_currentUser == null) {
      throw Exception('Kein User eingeloggt');
    }

    _currentUser = _currentUser!.copyWith(
      name: name,
      email: email,
      profileImageUrl: profileImageUrl,
    );

    return _currentUser!;
  }

  // User nach ID abrufen
  Future<UserModel?> getUserById(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      return _mockUsers.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  // Authentifizierungs-Token erneuern (später für Firebase)
  Future<void> refreshAuthToken() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Implementierung folgt mit Firebase
  }

  // Passwort zurücksetzen (später für Firebase)
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    // Implementierung folgt mit Firebase
  }

  // Neuen Auth-Key generieren
  String generateAuthKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return 'KEY-${random.toString()}-${chars[random % chars.length]}';
  }

  // QR-Code Daten generieren
  String generateQRCodeData() {
    return generateAuthKey();
  }
}
