import 'package:equatable/equatable.dart';
import '../../data/models/memorial_model.dart';
import '../../data/models/memorial_access_model.dart';

export '../../data/models/memorial_model.dart' show MemorialStatus;

enum MemorialBlocStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  publishing,
  success,
  error,
}

class MemorialState extends Equatable {
  final MemorialBlocStatus status;
  final List<MemorialModel> memorials;
  final MemorialModel? selectedMemorial;
  final List<MemorialAccessModel> currentMemorialMembers;
  final String? errorMessage;
  final String? successMessage;
  final String? lastCreatedInviteUrl;

  const MemorialState({
    this.status = MemorialBlocStatus.initial,
    this.memorials = const [],
    this.selectedMemorial,
    this.currentMemorialMembers = const [],
    this.errorMessage,
    this.successMessage,
    this.lastCreatedInviteUrl,
  });

  // ========================================
  // FACTORY CONSTRUCTORS
  // ========================================

  factory MemorialState.initial() {
    return const MemorialState(status: MemorialBlocStatus.initial);
  }

  factory MemorialState.loading() {
    return const MemorialState(status: MemorialBlocStatus.loading);
  }

  factory MemorialState.loaded(List<MemorialModel> memorials) {
    return MemorialState(
      status: MemorialBlocStatus.loaded,
      memorials: memorials,
    );
  }

  factory MemorialState.success(
    String message, {
    List<MemorialModel>? memorials,
  }) {
    return MemorialState(
      status: MemorialBlocStatus.success,
      successMessage: message,
      memorials: memorials ?? [],
    );
  }

  factory MemorialState.error(String message) {
    return MemorialState(
      status: MemorialBlocStatus.error,
      errorMessage: message,
    );
  }

  // ========================================
  // GETTERS
  // ========================================

  bool get isLoading =>
      status == MemorialBlocStatus.loading ||
      status == MemorialBlocStatus.creating ||
      status == MemorialBlocStatus.updating ||
      status == MemorialBlocStatus.deleting ||
      status == MemorialBlocStatus.publishing;

  bool get hasError => status == MemorialBlocStatus.error;
  bool get isSuccess => status == MemorialBlocStatus.success;
  bool get hasMemorials => memorials.isNotEmpty;
  bool get hasSelectedMemorial => selectedMemorial != null;

  /// Anzahl der Memorials
  int get memorialCount => memorials.length;

  /// Eigene Memorials (wo User Owner ist)
  List<MemorialModel> getOwnedMemorials(String userId) {
    return memorials.where((m) => m.ownerId == userId).toList();
  }

  /// Shared Memorials (wo User eingeladen wurde)
  List<MemorialModel> getSharedMemorials(String userId) {
    return memorials.where((m) => m.ownerId != userId).toList();
  }

  // ========================================
  // COPY WITH
  // ========================================

  MemorialState copyWith({
    MemorialBlocStatus? status,
    List<MemorialModel>? memorials,
    MemorialModel? selectedMemorial,
    List<MemorialAccessModel>? currentMemorialMembers,
    String? errorMessage,
    String? successMessage,
    String? lastCreatedInviteUrl,
  }) {
    return MemorialState(
      status: status ?? this.status,
      memorials: memorials ?? this.memorials,
      selectedMemorial: selectedMemorial ?? this.selectedMemorial,
      currentMemorialMembers:
          currentMemorialMembers ?? this.currentMemorialMembers,
      errorMessage: errorMessage,
      successMessage: successMessage,
      lastCreatedInviteUrl: lastCreatedInviteUrl ?? this.lastCreatedInviteUrl,
    );
  }

  @override
  List<Object?> get props => [
        status,
        memorials,
        selectedMemorial,
        currentMemorialMembers,
        errorMessage,
        successMessage,
        lastCreatedInviteUrl,
      ];

  @override
  String toString() {
    return 'MemorialState(status: $status, memorials: ${memorials.length}, selected: ${selectedMemorial?.name ?? 'null'})';
  }
}
