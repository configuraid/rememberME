import '../models/license_model.dart';

class LicenseRepository {
  // Mock-Daten für Entwicklung
  final Map<String, LicenseModel> _mockLicenses = {};

  LicenseRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Basis-Lizenz für User 1
    _mockLicenses['user-1'] = LicenseModel.basic(
      id: 'license-1',
      userId: 'user-1',
    ).copyWith(
      storageUsed: 0.15, // 150 MB genutzt
    );

    // Lifetime-Lizenz für User 2
    _mockLicenses['user-2'] = LicenseModel.lifetime(
      id: 'license-2',
      userId: 'user-2',
    ).copyWith(
      storageUsed: 1.2, // 1.2 GB genutzt
    );
  }

  // Lizenz eines Users abrufen
  Future<LicenseModel?> getLicenseByUserId(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockLicenses[userId];
  }

  // Lizenz upgraden
  Future<LicenseModel> upgradeLicense(
    String userId,
    LicenseType newType,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    final currentLicense = _mockLicenses[userId];
    if (currentLicense == null) {
      throw Exception('Keine Lizenz gefunden');
    }

    LicenseModel upgradedLicense;

    if (newType == LicenseType.lifetime) {
      upgradedLicense = LicenseModel.lifetime(
        id: currentLicense.id,
        userId: userId,
      ).copyWith(
        storageUsed: currentLicense.storageUsed,
        purchaseDate: currentLicense.purchaseDate,
      );
    } else {
      throw Exception('Downgrade nicht möglich');
    }

    _mockLicenses[userId] = upgradedLicense;
    return upgradedLicense;
  }

  // Speicher-Nutzung aktualisieren
  Future<LicenseModel> updateStorageUsed(
    String userId,
    double storageUsed,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final license = _mockLicenses[userId];
    if (license == null) {
      throw Exception('Keine Lizenz gefunden');
    }

    final updatedLicense = license.copyWith(storageUsed: storageUsed);
    _mockLicenses[userId] = updatedLicense;
    return updatedLicense;
  }

  // Speicher hinzufügen (Upload simulieren)
  Future<LicenseModel> addStorage(
    String userId,
    double sizeInMB,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final license = _mockLicenses[userId];
    if (license == null) {
      throw Exception('Keine Lizenz gefunden');
    }

    final sizeInGB = sizeInMB / 1024;
    final newStorageUsed = license.storageUsed + sizeInGB;

    if (newStorageUsed > license.storageLimit) {
      throw Exception('Speicher-Limit überschritten');
    }

    return updateStorageUsed(userId, newStorageUsed);
  }

  // Prüfen ob Content-Block verfügbar ist
  Future<bool> isContentBlockAvailable(
    String userId,
    String blockType,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final license = _mockLicenses[userId];
    if (license == null) return false;

    return license.hasContentBlock(blockType);
  }

  // Lizenz-Details für Upgrade-Anzeige
  Future<Map<String, dynamic>> getLicenseUpgradeInfo(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final currentLicense = _mockLicenses[userId];
    if (currentLicense == null) {
      throw Exception('Keine Lizenz gefunden');
    }

    if (currentLicense.type == LicenseType.lifetime) {
      return {
        'canUpgrade': false,
        'message': 'Sie haben bereits die Lifetime-Lizenz',
      };
    }

    // Lifetime-Lizenz Vorschau
    final lifetimeLicense = LicenseModel.lifetime(
      id: 'preview',
      userId: userId,
    );

    return {
      'canUpgrade': true,
      'currentType': currentLicense.type,
      'upgradeType': LicenseType.lifetime,
      'currentFeatures': {
        'storageLimit': '${currentLicense.storageLimit} GB',
        'maxImages': currentLicense.maxImages,
        'maxVideos': currentLicense.maxVideos,
        'maxMemorials': currentLicense.maxMemorials,
        'contentBlocks': currentLicense.availableContentBlocks.length,
      },
      'upgradeFeatures': {
        'storageLimit': '${lifetimeLicense.storageLimit} GB',
        'maxImages': 'Unbegrenzt',
        'maxVideos': 'Unbegrenzt',
        'maxMemorials': 'Unbegrenzt',
        'contentBlocks': lifetimeLicense.availableContentBlocks.length,
      },
      'price': '€399',
    };
  }

  // Neue Lizenz erstellen (bei Registrierung)
  Future<LicenseModel> createLicense(
    String userId,
    LicenseType type,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final licenseId = 'license-${DateTime.now().millisecondsSinceEpoch}';

    LicenseModel newLicense;
    if (type == LicenseType.basic) {
      newLicense = LicenseModel.basic(id: licenseId, userId: userId);
    } else {
      newLicense = LicenseModel.lifetime(id: licenseId, userId: userId);
    }

    _mockLicenses[userId] = newLicense;
    return newLicense;
  }

  // Lizenz verlängern (falls zeitbegrenzt)
  Future<LicenseModel> renewLicense(String userId, int years) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final license = _mockLicenses[userId];
    if (license == null) {
      throw Exception('Keine Lizenz gefunden');
    }

    final newExpiryDate =
        (license.expiryDate ?? DateTime.now()).add(Duration(days: 365 * years));

    final renewedLicense = license.copyWith(expiryDate: newExpiryDate);
    _mockLicenses[userId] = renewedLicense;
    return renewedLicense;
  }

  // Speicher-Limit erweitern
  Future<LicenseModel> expandStorage(String userId, double additionalGB) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final license = _mockLicenses[userId];
    if (license == null) {
      throw Exception('Keine Lizenz gefunden');
    }

    final newStorageLimit = license.storageLimit + additionalGB;
    final expandedLicense = license.copyWith(storageLimit: newStorageLimit);

    _mockLicenses[userId] = expandedLicense;
    return expandedLicense;
  }
}
