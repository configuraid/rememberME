import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/data/repositories/auth/auth_repository.dart';
import 'package:rememberme/data/repositories/auth/organization_repository.dart';
import 'organization_event.dart';
import 'organization_state.dart';

class OrganizationBloc extends Bloc<OrganizationEvent, OrganizationState> {
  final OrganizationRepository organizationRepository;
  final AuthRepository authRepository;

  OrganizationBloc({
    required this.organizationRepository,
    required this.authRepository,
  }) : super(OrganizationState.initial()) {
    on<OrganizationLoadRequested>(_onLoadOrganization);
    on<OrganizationMemberAddRequested>(_onAddMember);
    on<OrganizationMemberRemoveRequested>(_onRemoveMember);
    on<OrganizationMemberRoleUpdateRequested>(_onUpdateMemberRole);
    on<OrganizationMemberPinUpdateRequested>(_onUpdateMemberPin);
    on<OrganizationUpdateRequested>(_onUpdateOrganization);
  }

  // ========================================
  // LOAD ORGANIZATION
  // ========================================

  /// Organisation und alle Mitglieder laden
  Future<void> _onLoadOrganization(
    OrganizationLoadRequested event,
    Emitter<OrganizationState> emit,
  ) async {
    print('📚 OrganizationBloc - Lade Organisation: ${event.organizationId}');
    emit(OrganizationState.loading());

    try {
      // 1. Organisation laden
      final organization = await organizationRepository
          .getOrganizationById(event.organizationId);

      if (organization == null) {
        print('❌ OrganizationBloc - Organisation nicht gefunden');
        emit(OrganizationState.error('Organisation nicht gefunden'));
        return;
      }

      // 2. Alle Mitglieder mit User-Daten laden
      final membersWithData = await organizationRepository
          .getMembersWithUserData(event.organizationId);

      emit(OrganizationState.success(
        organization: organization,
        membersWithData: membersWithData,
      ));

      print('✅ OrganizationBloc - Organisation geladen: ${organization.name}');
      print(
          '✅ OrganizationBloc - ${membersWithData.length} Mitglieder geladen');
    } catch (e) {
      print('❌ OrganizationBloc - Fehler beim Laden: $e');
      emit(OrganizationState.error('Fehler beim Laden: ${e.toString()}'));
    }
  }

  // ========================================
  // MEMBER MANAGEMENT
  // ========================================

  /// Neues Mitglied hinzufügen
  Future<void> _onAddMember(
    OrganizationMemberAddRequested event,
    Emitter<OrganizationState> emit,
  ) async {
    if (state.organization == null) {
      emit(OrganizationState.error('Keine Organisation geladen'));
      return;
    }

    try {
      print('➕ OrganizationBloc - Füge neues Mitglied hinzu: ${event.name}');
      print('👔 Rolle: ${event.role}');

      // 1. Erstelle neuen User (✅ Mit role Parameter)
      final newUser = await authRepository.createNewProfile(
        organizationId: event.organizationId,
        name: event.name,
        email: event.email,
        pin: event.pin,
        role: event.role, // ✅ Role wird übergeben
      );

      if (newUser == null) {
        print('❌ OrganizationBloc - Fehler beim Erstellen des Users');
        emit(state.copyWith(
          status: OrganizationStatus.error,
          errorMessage: 'Fehler beim Erstellen des Users',
        ));
        return;
      }

      // 2. Reload Organisation
      add(OrganizationLoadRequested(event.organizationId));

      print('✅ OrganizationBloc - Mitglied hinzugefügt: ${newUser.name}');
    } catch (e) {
      print('❌ OrganizationBloc - Fehler beim Hinzufügen: $e');
      emit(state.copyWith(
        status: OrganizationStatus.error,
        errorMessage: 'Fehler: ${e.toString()}',
      ));
    }
  }

  /// Mitglied entfernen
  Future<void> _onRemoveMember(
    OrganizationMemberRemoveRequested event,
    Emitter<OrganizationState> emit,
  ) async {
    if (state.organization == null) {
      emit(OrganizationState.error('Keine Organisation geladen'));
      return;
    }

    try {
      print('🗑️ OrganizationBloc - Entferne Mitglied: ${event.memberId}');

      await organizationRepository.removeMember(event.memberId);

      // Reload Organisation
      add(OrganizationLoadRequested(state.organization!.id));

      print('✅ OrganizationBloc - Mitglied entfernt');
    } catch (e) {
      print('❌ OrganizationBloc - Fehler beim Entfernen: $e');
      emit(state.copyWith(
        status: OrganizationStatus.error,
        errorMessage: 'Fehler: ${e.toString()}',
      ));
    }
  }

  /// Mitglied-Rolle ändern
  Future<void> _onUpdateMemberRole(
    OrganizationMemberRoleUpdateRequested event,
    Emitter<OrganizationState> emit,
  ) async {
    if (state.organization == null) {
      emit(OrganizationState.error('Keine Organisation geladen'));
      return;
    }

    try {
      print('🔄 OrganizationBloc - Ändere Rolle: ${event.memberId}');

      await organizationRepository.updateMemberRole(
        event.memberId,
        event.newRole,
      );

      // Reload Organisation
      add(OrganizationLoadRequested(state.organization!.id));

      print('✅ OrganizationBloc - Rolle aktualisiert');
    } catch (e) {
      print('❌ OrganizationBloc - Fehler beim Ändern der Rolle: $e');
      emit(state.copyWith(
        status: OrganizationStatus.error,
        errorMessage: 'Fehler: ${e.toString()}',
      ));
    }
  }

  /// Mitglied-PIN ändern
  Future<void> _onUpdateMemberPin(
    OrganizationMemberPinUpdateRequested event,
    Emitter<OrganizationState> emit,
  ) async {
    if (state.organization == null) {
      emit(OrganizationState.error('Keine Organisation geladen'));
      return;
    }

    try {
      print('🔒 OrganizationBloc - Ändere PIN: ${event.memberId}');

      await organizationRepository.updateMemberPin(
        event.memberId,
        event.pin,
      );

      // Reload Organisation
      add(OrganizationLoadRequested(state.organization!.id));

      print('✅ OrganizationBloc - PIN aktualisiert');
    } catch (e) {
      print('❌ OrganizationBloc - Fehler beim Ändern der PIN: $e');
      emit(state.copyWith(
        status: OrganizationStatus.error,
        errorMessage: 'Fehler: ${e.toString()}',
      ));
    }
  }

  // ========================================
  // ORGANIZATION MANAGEMENT
  // ========================================

  /// Organisation bearbeiten
  Future<void> _onUpdateOrganization(
    OrganizationUpdateRequested event,
    Emitter<OrganizationState> emit,
  ) async {
    if (state.organization == null) {
      emit(OrganizationState.error('Keine Organisation geladen'));
      return;
    }

    try {
      print(
          '🔄 OrganizationBloc - Aktualisiere Organisation: ${event.organizationId}');

      final updatedOrg = state.organization!.copyWith(
        name: event.name,
        settings: event.settings,
      );

      await organizationRepository.updateOrganization(updatedOrg);

      // Reload Organisation
      add(OrganizationLoadRequested(event.organizationId));

      print('✅ OrganizationBloc - Organisation aktualisiert');
    } catch (e) {
      print('❌ OrganizationBloc - Fehler beim Aktualisieren: $e');
      emit(state.copyWith(
        status: OrganizationStatus.error,
        errorMessage: 'Fehler: ${e.toString()}',
      ));
    }
  }
}
