import 'package:equatable/equatable.dart';
import 'package:rememberme/data/models/auth/organization_member_model.dart';

abstract class OrganizationEvent extends Equatable {
  const OrganizationEvent();

  @override
  List<Object?> get props => [];
}

// ========================================
// LOAD EVENTS
// ========================================

/// Organisation und Mitglieder laden
class OrganizationLoadRequested extends OrganizationEvent {
  final String organizationId;

  const OrganizationLoadRequested(this.organizationId);

  @override
  List<Object?> get props => [organizationId];
}

// ========================================
// MEMBER MANAGEMENT EVENTS
// ========================================

/// Mitglied hinzufügen
class OrganizationMemberAddRequested extends OrganizationEvent {
  final String organizationId;
  final String name;
  final String email;
  final MemberRole role;
  final String? pin;

  const OrganizationMemberAddRequested({
    required this.organizationId,
    required this.name,
    required this.email,
    required this.role,
    this.pin,
  });

  @override
  List<Object?> get props => [organizationId, name, email, role, pin];
}

/// Mitglied entfernen
class OrganizationMemberRemoveRequested extends OrganizationEvent {
  final String memberId;

  const OrganizationMemberRemoveRequested(this.memberId);

  @override
  List<Object?> get props => [memberId];
}

/// Mitglied-Rolle ändern
class OrganizationMemberRoleUpdateRequested extends OrganizationEvent {
  final String memberId;
  final MemberRole newRole;

  const OrganizationMemberRoleUpdateRequested(this.memberId, this.newRole);

  @override
  List<Object?> get props => [memberId, newRole];
}

/// Mitglied-PIN ändern
class OrganizationMemberPinUpdateRequested extends OrganizationEvent {
  final String memberId;
  final String? pin;

  const OrganizationMemberPinUpdateRequested(this.memberId, this.pin);

  @override
  List<Object?> get props => [memberId, pin];
}

// ========================================
// ORGANIZATION MANAGEMENT EVENTS
// ========================================

/// Organisation bearbeiten
class OrganizationUpdateRequested extends OrganizationEvent {
  final String organizationId;
  final String? name;
  final Map<String, dynamic>? settings;

  const OrganizationUpdateRequested({
    required this.organizationId,
    this.name,
    this.settings,
  });

  @override
  List<Object?> get props => [organizationId, name, settings];
}
