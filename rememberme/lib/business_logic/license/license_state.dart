import 'package:equatable/equatable.dart';
import '../../data/models/license_model.dart';

enum LicenseStatus {
  initial,
  loading,
  loaded,
  upgrading,
  success,
  error,
}

class LicenseState extends Equatable {
  final LicenseStatus status;
  final LicenseModel? license;
  final Map<String, dynamic>? upgradeInfo;
  final String? errorMessage;
  final String? successMessage;

  const LicenseState({
    this.status = LicenseStatus.initial,
    this.license,
    this.upgradeInfo,
    this.errorMessage,
    this.successMessage,
  });

  // Initial State
  factory LicenseState.initial() {
    return const LicenseState(status: LicenseStatus.initial);
  }

  // Loading State
  factory LicenseState.loading() {
    return const LicenseState(status: LicenseStatus.loading);
  }

  // Loaded State
  factory LicenseState.loaded(LicenseModel license) {
    return LicenseState(
      status: LicenseStatus.loaded,
      license: license,
    );
  }

  // Success State
  factory LicenseState.success(String message, {LicenseModel? license}) {
    return LicenseState(
      status: LicenseStatus.success,
      successMessage: message,
      license: license,
    );
  }

  // Error State
  factory LicenseState.error(String message) {
    return LicenseState(
      status: LicenseStatus.error,
      errorMessage: message,
    );
  }

  // Getter
  bool get isLoading =>
      status == LicenseStatus.loading || status == LicenseStatus.upgrading;
  bool get hasError => status == LicenseStatus.error;
  bool get isSuccess => status == LicenseStatus.success;
  bool get hasLicense => license != null;

  // CopyWith
  LicenseState copyWith({
    LicenseStatus? status,
    LicenseModel? license,
    Map<String, dynamic>? upgradeInfo,
    String? errorMessage,
    String? successMessage,
  }) {
    return LicenseState(
      status: status ?? this.status,
      license: license ?? this.license,
      upgradeInfo: upgradeInfo ?? this.upgradeInfo,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        license,
        upgradeInfo,
        errorMessage,
        successMessage,
      ];
}
