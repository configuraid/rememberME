import 'package:equatable/equatable.dart';
import 'package:rememberme/data/models/auth/organization_member_model.dart';
import 'package:rememberme/data/models/auth/organization_model.dart';
import 'package:rememberme/data/models/auth/user_model.dart';

enum OrganizationStatus {
  initial,
  loading,
  success,
  error,
}

class OrganizationState extends Equatable {
  final OrganizationStatus status;
  final OrganizationModel? organization;
  final List<Map<String, dynamic>> membersWithData; // {member, user}
  final String? errorMessage;

  const OrganizationState({
    this.status = OrganizationStatus.initial,
    this.organization,
    this.membersWithData = const [],
    this.errorMessage,
  });

  // ========================================
  // FACTORY CONSTRUCTORS
  // ========================================

  /// Initial State
  factory OrganizationState.initial() {
    return const OrganizationState(status: OrganizationStatus.initial);
  }

  /// Loading State
  factory OrganizationState.loading() {
    return const OrganizationState(status: OrganizationStatus.loading);
  }

  /// Success State
  factory OrganizationState.success({
    required OrganizationModel organization,
    required List<Map<String, dynamic>> membersWithData,
  }) {
    return OrganizationState(
      status: OrganizationStatus.success,
      organization: organization,
      membersWithData: membersWithData,
    );
  }

  /// Error State
  factory OrganizationState.error(String message) {
    return OrganizationState(
      status: OrganizationStatus.error,
      errorMessage: message,
    );
  }

  // ========================================
  // GETTERS
  // ========================================

  /// Ist gerade am Laden?
  bool get isLoading => status == OrganizationStatus.loading;

  /// Hat Fehler?
  bool get hasError => status == OrganizationStatus.error;

  /// Erfolgreich geladen?
  bool get isSuccess => status == OrganizationStatus.success;

  /// Anzahl Mitglieder
  int get memberCount => membersWithData.length;

  /// Alle User extrahieren
  List<UserModel> get users {
    return membersWithData.map((data) => data['user'] as UserModel).toList();
  }

  /// Alle Member extrahieren
  List<OrganizationMemberModel> get members {
    return membersWithData
        .map((data) => data['member'] as OrganizationMemberModel)
        .toList();
  }

  // ========================================
  // COPY WITH
  // ========================================

  OrganizationState copyWith({
    OrganizationStatus? status,
    OrganizationModel? organization,
    List<Map<String, dynamic>>? membersWithData,
    String? errorMessage,
  }) {
    return OrganizationState(
      status: status ?? this.status,
      organization: organization ?? this.organization,
      membersWithData: membersWithData ?? this.membersWithData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        organization,
        membersWithData,
        errorMessage,
      ];

  @override
  String toString() {
    return 'OrganizationState(status: $status, organization: ${organization?.name ?? 'null'}, members: ${memberCount}, error: ${errorMessage ?? 'null'})';
  }
}
