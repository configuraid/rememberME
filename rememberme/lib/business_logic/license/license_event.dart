import 'package:equatable/equatable.dart';
import '../../data/models/license_model.dart';

abstract class LicenseEvent extends Equatable {
  const LicenseEvent();

  @override
  List<Object?> get props => [];
}

// Lizenz laden
class LicenseLoadRequested extends LicenseEvent {
  final String userId;

  const LicenseLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

// Lizenz upgraden
class LicenseUpgradeRequested extends LicenseEvent {
  final String userId;
  final LicenseType newType;

  const LicenseUpgradeRequested({
    required this.userId,
    required this.newType,
  });

  @override
  List<Object?> get props => [userId, newType];
}

// Speicher hinzufügen
class LicenseStorageAddRequested extends LicenseEvent {
  final String userId;
  final double sizeInMB;

  const LicenseStorageAddRequested({
    required this.userId,
    required this.sizeInMB,
  });

  @override
  List<Object?> get props => [userId, sizeInMB];
}

// Upgrade-Info laden
class LicenseUpgradeInfoRequested extends LicenseEvent {
  final String userId;

  const LicenseUpgradeInfoRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

// Speicher erweitern
class LicenseExpandStorageRequested extends LicenseEvent {
  final String userId;
  final double additionalGB;

  const LicenseExpandStorageRequested({
    required this.userId,
    required this.additionalGB,
  });

  @override
  List<Object?> get props => [userId, additionalGB];
}
