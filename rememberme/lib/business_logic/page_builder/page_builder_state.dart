import 'package:equatable/equatable.dart';
import '../../../data/models/content_block_model.dart';
import '../../../data/models/memorial_page_model.dart';

enum PageBuilderStatus {
  initial,
  loading,
  loaded,
  editing,
  saving,
  saved,
  error,
}

class BlockTemplate {
  final String id;
  final String name;
  final String description;
  final ContentBlockType type;
  final Map<String, dynamic> defaultStyles;
  final String? thumbnailUrl;

  const BlockTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.defaultStyles = const {},
    this.thumbnailUrl,
  });
}

class PageBuilderState extends Equatable {
  final PageBuilderStatus status;
  final MemorialPageModel? memorial;
  final List<ContentBlockModel> blocks;
  final String? selectedBlockId;
  final List<BlockTemplate> availableTemplates;
  final bool isPreviewMode;
  final String? errorMessage;
  final String? successMessage;

  // Undo/Redo History
  final List<List<ContentBlockModel>> history;
  final int historyIndex;

  const PageBuilderState({
    this.status = PageBuilderStatus.initial,
    this.memorial,
    this.blocks = const [],
    this.selectedBlockId,
    this.availableTemplates = const [],
    this.isPreviewMode = false,
    this.errorMessage,
    this.successMessage,
    this.history = const [],
    this.historyIndex = -1,
  });

  factory PageBuilderState.initial() {
    return const PageBuilderState(status: PageBuilderStatus.initial);
  }

  factory PageBuilderState.loading() {
    return const PageBuilderState(status: PageBuilderStatus.loading);
  }

  factory PageBuilderState.loaded({
    required MemorialPageModel memorial,
    required List<ContentBlockModel> blocks,
    required List<BlockTemplate> templates,
  }) {
    return PageBuilderState(
      status: PageBuilderStatus.loaded,
      memorial: memorial,
      blocks: blocks,
      availableTemplates: templates,
      history: [blocks],
      historyIndex: 0,
    );
  }

  factory PageBuilderState.error(String message) {
    return PageBuilderState(
      status: PageBuilderStatus.error,
      errorMessage: message,
    );
  }

  bool get isLoading =>
      status == PageBuilderStatus.loading || status == PageBuilderStatus.saving;
  bool get hasError => status == PageBuilderStatus.error;
  bool get canUndo => historyIndex > 0;
  bool get canRedo => historyIndex < history.length - 1;

  ContentBlockModel? get selectedBlock {
    if (selectedBlockId == null) return null;
    try {
      return blocks.firstWhere((block) => block.id == selectedBlockId);
    } catch (e) {
      return null;
    }
  }

  PageBuilderState copyWith({
    PageBuilderStatus? status,
    MemorialPageModel? memorial,
    List<ContentBlockModel>? blocks,
    String? selectedBlockId,
    bool clearSelectedBlock = false,
    List<BlockTemplate>? availableTemplates,
    bool? isPreviewMode,
    String? errorMessage,
    String? successMessage,
    List<List<ContentBlockModel>>? history,
    int? historyIndex,
  }) {
    return PageBuilderState(
      status: status ?? this.status,
      memorial: memorial ?? this.memorial,
      blocks: blocks ?? this.blocks,
      selectedBlockId:
          clearSelectedBlock ? null : (selectedBlockId ?? this.selectedBlockId),
      availableTemplates: availableTemplates ?? this.availableTemplates,
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
      errorMessage: errorMessage,
      successMessage: successMessage,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
    );
  }

  @override
  List<Object?> get props => [
        status,
        memorial,
        blocks,
        selectedBlockId,
        availableTemplates,
        isPreviewMode,
        errorMessage,
        successMessage,
        history,
        historyIndex,
      ];
}
