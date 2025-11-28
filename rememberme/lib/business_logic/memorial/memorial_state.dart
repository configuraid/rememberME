import 'package:equatable/equatable.dart';
import '../../data/models/memorial_page_model.dart';

enum MemorialStatus {
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
  final MemorialStatus status;
  final List<MemorialPageModel> memorials;
  final MemorialPageModel? selectedMemorial;
  final String? errorMessage;
  final String? successMessage;

  const MemorialState({
    this.status = MemorialStatus.initial,
    this.memorials = const [],
    this.selectedMemorial,
    this.errorMessage,
    this.successMessage,
  });

  factory MemorialState.initial() {
    return const MemorialState(status: MemorialStatus.initial);
  }

  factory MemorialState.loading() {
    return const MemorialState(status: MemorialStatus.loading);
  }

  factory MemorialState.loaded(List<MemorialPageModel> memorials) {
    return MemorialState(
      status: MemorialStatus.loaded,
      memorials: memorials,
    );
  }

  factory MemorialState.success(String message,
      {List<MemorialPageModel>? memorials}) {
    return MemorialState(
      status: MemorialStatus.success,
      successMessage: message,
      memorials: memorials ?? [],
    );
  }

  factory MemorialState.error(String message) {
    return MemorialState(
      status: MemorialStatus.error,
      errorMessage: message,
    );
  }

  bool get isLoading =>
      status == MemorialStatus.loading ||
      status == MemorialStatus.creating ||
      status == MemorialStatus.updating ||
      status == MemorialStatus.deleting ||
      status == MemorialStatus.publishing;

  bool get hasError => status == MemorialStatus.error;
  bool get isSuccess => status == MemorialStatus.success;

  MemorialState copyWith({
    MemorialStatus? status,
    List<MemorialPageModel>? memorials,
    MemorialPageModel? selectedMemorial,
    String? errorMessage,
    String? successMessage,
  }) {
    return MemorialState(
      status: status ?? this.status,
      memorials: memorials ?? this.memorials,
      selectedMemorial: selectedMemorial ?? this.selectedMemorial,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        memorials,
        selectedMemorial,
        errorMessage,
        successMessage,
      ];
}
