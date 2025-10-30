import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/license_repository.dart';
import 'license_event.dart';
import 'license_state.dart';

class LicenseBloc extends Bloc<LicenseEvent, LicenseState> {
  final LicenseRepository licenseRepository;

  LicenseBloc({required this.licenseRepository})
      : super(LicenseState.initial()) {
    // Lizenz laden
    on<LicenseLoadRequested>(_onLoadLicense);

    // Lizenz upgraden
    on<LicenseUpgradeRequested>(_onUpgradeLicense);

    // Speicher hinzufügen
    on<LicenseStorageAddRequested>(_onAddStorage);

    // Upgrade-Info laden
    on<LicenseUpgradeInfoRequested>(_onLoadUpgradeInfo);

    // Speicher erweitern
    on<LicenseExpandStorageRequested>(_onExpandStorage);
  }

  // Lizenz laden Handler
  Future<void> _onLoadLicense(
    LicenseLoadRequested event,
    Emitter<LicenseState> emit,
  ) async {
    emit(LicenseState.loading());

    try {
      final license = await licenseRepository.getLicenseByUserId(event.userId);

      if (license != null) {
        emit(LicenseState.loaded(license));
      } else {
        emit(LicenseState.error('Keine Lizenz gefunden'));
      }
    } catch (e) {
      emit(LicenseState.error('Fehler beim Laden der Lizenz: ${e.toString()}'));
    }
  }

  // Lizenz upgraden Handler
  Future<void> _onUpgradeLicense(
    LicenseUpgradeRequested event,
    Emitter<LicenseState> emit,
  ) async {
    emit(state.copyWith(status: LicenseStatus.upgrading));

    try {
      final upgradedLicense = await licenseRepository.upgradeLicense(
        event.userId,
        event.newType,
      );

      emit(LicenseState.success(
        'Lizenz erfolgreich auf ${event.newType.toString().split('.').last} aktualisiert',
        license: upgradedLicense,
      ));
    } catch (e) {
      emit(LicenseState.error(
          'Fehler beim Upgraden der Lizenz: ${e.toString()}'));
    }
  }

  // Speicher hinzufügen Handler
  Future<void> _onAddStorage(
    LicenseStorageAddRequested event,
    Emitter<LicenseState> emit,
  ) async {
    emit(state.copyWith(status: LicenseStatus.loading));

    try {
      final updatedLicense = await licenseRepository.addStorage(
        event.userId,
        event.sizeInMB,
      );

      emit(LicenseState.success(
        'Speicher erfolgreich aktualisiert',
        license: updatedLicense,
      ));
    } catch (e) {
      if (e.toString().contains('Speicher-Limit überschritten')) {
        emit(LicenseState.error(
            'Speicher-Limit überschritten. Bitte upgraden Sie Ihre Lizenz.'));
      } else {
        emit(LicenseState.error(
            'Fehler beim Hinzufügen von Speicher: ${e.toString()}'));
      }
    }
  }

  // Upgrade-Info laden Handler
  Future<void> _onLoadUpgradeInfo(
    LicenseUpgradeInfoRequested event,
    Emitter<LicenseState> emit,
  ) async {
    emit(state.copyWith(status: LicenseStatus.loading));

    try {
      final upgradeInfo =
          await licenseRepository.getLicenseUpgradeInfo(event.userId);

      emit(state.copyWith(
        status: LicenseStatus.loaded,
        upgradeInfo: upgradeInfo,
      ));
    } catch (e) {
      emit(LicenseState.error(
          'Fehler beim Laden der Upgrade-Informationen: ${e.toString()}'));
    }
  }

  // Speicher erweitern Handler
  Future<void> _onExpandStorage(
    LicenseExpandStorageRequested event,
    Emitter<LicenseState> emit,
  ) async {
    emit(state.copyWith(status: LicenseStatus.upgrading));

    try {
      final expandedLicense = await licenseRepository.expandStorage(
        event.userId,
        event.additionalGB,
      );

      emit(LicenseState.success(
        'Speicher erfolgreich um ${event.additionalGB} GB erweitert',
        license: expandedLicense,
      ));
    } catch (e) {
      emit(LicenseState.error(
          'Fehler beim Erweitern des Speichers: ${e.toString()}'));
    }
  }
}
