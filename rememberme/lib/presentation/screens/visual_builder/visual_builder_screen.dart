import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:rememberme/data/models/content_block_model.dart';
import 'package:rememberme/data/models/memorial_page_model.dart';
import 'package:rememberme/business_logic/memorial/memorial_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_event.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import '../../widgets/page_builder/content_block_widget.dart';
import '../../widgets/page_builder/add_block_bottom_sheet.dart';
import '../../widgets/page_builder/block_settings_bottom_sheet.dart';
import '../../widgets/preview/web_preview_mixin.dart';

class IntuitivePageBuilderScreen extends StatefulWidget {
  final MemorialPageModel memorial;

  const IntuitivePageBuilderScreen({
    super.key,
    required this.memorial,
  });

  @override
  State<IntuitivePageBuilderScreen> createState() =>
      _IntuitivePageBuilderScreenState();
}

class _IntuitivePageBuilderScreenState extends State<IntuitivePageBuilderScreen>
    with TickerProviderStateMixin, WebPreviewMixin {
  List<ContentBlock> _blocks = [];
  String? _selectedBlockId;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  final ScrollController _scrollController = ScrollController();

  String? _shakingBlockId;
  AnimationController? _shakeController;
  Animation<double>? _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _loadMemorialContent();
    _setupShakeAnimation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shakeController?.dispose();
    super.dispose();
  }

  void _setupShakeAnimation() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController!,
      curve: Curves.elasticInOut,
    ));

    _shakeController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _shakingBlockId = null;
          });
        }
      }
    });
  }

  void _loadMemorialContent() {
    _blocks = List.from(widget.memorial.contentBlocks);
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      final duration = Platform.isIOS
          ? const Duration(milliseconds: 400)
          : const Duration(milliseconds: 300);

      final curve = Platform.isIOS ? Curves.easeOut : Curves.easeInOut;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: duration,
        curve: curve,
      );
    }
  }

  // ============================================================
  // Native Toast Implementierung
  // ============================================================
  void _showSuccessToast(String message) {
    if (Platform.isIOS) {
      _showIOSToast(message);
    } else {
      _showAndroidSnackBar(message);
    }
  }

  void _showIOSToast(String message) {
    final overlay = Overlay.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _IOSBottomToast(
        message: message,
        isDark: isDark,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _showAndroidSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.textLight,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        elevation: 4,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      final shouldPop = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            AppStrings.unsavedChanges,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            AppStrings.unsavedChangesMessage,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(
                AppStrings.discardChanges,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    } else {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? AppColors.error.withOpacity(0.3)
                    : AppColors.greyLighter,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? AppColors.shadowDark : AppColors.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.error.withOpacity(0.2),
                        AppColors.error.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 56,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppStrings.unsavedChanges,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppStrings.unsavedChangesMessage,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.greyLight,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppStrings.cancel,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.textLight,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppStrings.discardChanges,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );

      return shouldPop ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSLayout(context);
    }
    return _buildAndroidLayout(context);
  }

  // ============================================================
  // iOS Native Layout
  // ============================================================
  Widget _buildIOSLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: CupertinoPageScaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        navigationBar: CupertinoNavigationBar(
          middle: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.memorial.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    fontFamily: '.SF Pro Text',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_hasUnsavedChanges) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          backgroundColor: isDark
              ? AppColors.backgroundDarkElevated.withOpacity(0.8)
              : AppColors.surface.withOpacity(0.94),
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.divider,
              width: 0.5,
            ),
          ),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
            child: Icon(
              CupertinoIcons.back,
              color: isDark ? AppColors.accent : AppColors.primary,
              size: 28,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: _showPreview,
                child: Icon(
                  CupertinoIcons.eye,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? CupertinoActivityIndicator(
                        color: isDark ? AppColors.accent : AppColors.primary,
                      )
                    : Text(
                        AppStrings.save,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _hasUnsavedChanges
                              ? (isDark ? AppColors.accent : AppColors.primary)
                              : AppColors.greyLight,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _blocks.isEmpty
                  ? _buildIOSEmptyState(isDark)
                  : _buildIOSBlockList(isDark),
              Positioned(
                right: 16,
                bottom: 16,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _showAddBlockSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.accent : AppColors.primary,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.accent : AppColors.primary)
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.add,
                          color:
                              isDark ? AppColors.primary : AppColors.background,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.addBlock,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.primary
                                : AppColors.background,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDarkElevated
                    : AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? AppColors.shadowDark : AppColors.shadow,
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                CupertinoIcons.doc_text,
                size: 64,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              AppStrings.noContentYet,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontFamily: '.SF Pro Display',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.noContentMessage,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.grey,
                height: 1.5,
                fontFamily: '.SF Pro Text',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            CupertinoButton(
              onPressed: _showAddBlockSheet,
              color: isDark ? AppColors.accent : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.add,
                    color: isDark ? AppColors.primary : AppColors.background,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppStrings.addBlock,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.primary : AppColors.background,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSBlockList(bool isDark) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverReorderableList(
            itemCount: _blocks.length,
            onReorder: _reorderBlocks,
            proxyDecorator: _proxyDecorator,
            onReorderStart: (index) {
              HapticFeedback.mediumImpact();
            },
            onReorderEnd: (index) {
              HapticFeedback.lightImpact();
            },
            itemBuilder: (context, index) {
              final block = _blocks[index];
              final isSelected = block.id == _selectedBlockId;
              final isShaking = block.id == _shakingBlockId;

              return ReorderableDelayedDragStartListener(
                key: ValueKey(block.id),
                index: index,
                child: AnimatedBuilder(
                  animation:
                      _shakeController ?? const AlwaysStoppedAnimation(0.0),
                  builder: (context, child) {
                    double offsetX = 0.0;
                    if (isShaking && _shakeAnimation != null) {
                      try {
                        offsetX = _shakeAnimation!.value;
                      } catch (e) {
                        offsetX = 0.0;
                      }
                    }

                    return Transform.translate(
                      offset: Offset(offsetX, 0),
                      child: child,
                    );
                  },
                  child: ContentBlockWidget(
                    block: block,
                    isSelected: isSelected,
                    onTap: () => _selectBlock(block.id),
                    onEdit: () => _showBlockSettings(block),
                    onDuplicate: () => _duplicateBlock(block),
                    onDelete: () => _deleteBlock(block.id),
                    onContentChanged: (key, value) =>
                        _updateBlockContent(block.id, key, value),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Android Layout
  // ============================================================
  Widget _buildAndroidLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          title: Text(
            widget.memorial.name,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: isDark
              ? AppColors.backgroundDarkElevated.withOpacity(0.8)
              : AppColors.surface.withOpacity(0.94),
          foregroundColor: isDark ? AppColors.textLight : AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          actions: [
            if (_hasUnsavedChanges)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.circle,
                          color: AppColors.warning,
                          size: 8,
                        ),
                        SizedBox(width: 6),
                        Text(
                          AppStrings.notSaved,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: Icon(
                Icons.visibility_rounded,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
              onPressed: _showPreview,
              tooltip: AppStrings.preview,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _isSaving
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? AppColors.accent : AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: _save,
                      child: Text(
                        AppStrings.save,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _hasUnsavedChanges
                              ? (isDark ? AppColors.accent : AppColors.primary)
                              : AppColors.greyLight,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        body: _blocks.isEmpty
            ? _buildAndroidEmptyState(isDark)
            : _buildAndroidBlockList(isDark),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddBlockSheet,
          icon: Icon(
            Icons.add_rounded,
            color: isDark ? AppColors.primary : AppColors.background,
          ),
          label: Text(
            AppStrings.addBlock,
            style: TextStyle(
              color: isDark ? AppColors.primary : AppColors.background,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: isDark ? AppColors.accent : AppColors.primary,
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildAndroidEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.accent.withOpacity(0.2),
                          AppColors.accent.withOpacity(0.1),
                        ]
                      : [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.08),
                        ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.accent.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.article_outlined,
                size: 80,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              AppStrings.noContentYet,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.noContentMessage,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.accent,
                          AppColors.accent.withOpacity(0.8),
                        ]
                      : [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.9),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? AppColors.accent.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _showAddBlockSheet,
                icon: Icon(
                  Icons.add_rounded,
                  size: 24,
                  color: isDark ? AppColors.primary : AppColors.background,
                ),
                label: Text(
                  AppStrings.addBlock,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.primary : AppColors.background,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor:
                      isDark ? AppColors.primary : AppColors.background,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidBlockList(bool isDark) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverReorderableList(
            itemCount: _blocks.length,
            onReorder: _reorderBlocks,
            proxyDecorator: _proxyDecorator,
            onReorderStart: (index) {
              HapticFeedback.mediumImpact();
            },
            onReorderEnd: (index) {
              HapticFeedback.lightImpact();
            },
            itemBuilder: (context, index) {
              final block = _blocks[index];
              final isSelected = block.id == _selectedBlockId;
              final isShaking = block.id == _shakingBlockId;

              return ReorderableDelayedDragStartListener(
                key: ValueKey(block.id),
                index: index,
                child: AnimatedBuilder(
                  animation:
                      _shakeController ?? const AlwaysStoppedAnimation(0.0),
                  builder: (context, child) {
                    double offsetX = 0.0;
                    if (isShaking && _shakeAnimation != null) {
                      try {
                        offsetX = _shakeAnimation!.value;
                      } catch (e) {
                        offsetX = 0.0;
                      }
                    }

                    return Transform.translate(
                      offset: Offset(offsetX, 0),
                      child: child,
                    );
                  },
                  child: ContentBlockWidget(
                    block: block,
                    isSelected: isSelected,
                    onTap: () => _selectBlock(block.id),
                    onEdit: () => _showBlockSettings(block),
                    onDuplicate: () => _duplicateBlock(block),
                    onDelete: () => _deleteBlock(block.id),
                    onContentChanged: (key, value) =>
                        _updateBlockContent(block.id, key, value),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    if (Platform.isIOS) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final double scale = Tween<double>(
            begin: 1.0,
            end: 1.02,
          ).evaluate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ));

          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: child,
      );
    } else {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final double scale = Tween<double>(
            begin: 1.0,
            end: 1.05,
          ).evaluate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ));

          return Transform.scale(
            scale: scale,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Opacity(
                opacity: 0.9,
                child: child,
              ),
            ),
          );
        },
        child: child,
      );
    }
  }

  void _selectBlock(String blockId) {
    setState(() {
      _selectedBlockId = _selectedBlockId == blockId ? null : blockId;
    });
  }

  void _showAddBlockSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBlockBottomSheet(
        onBlockTypeSelected: (type) {
          _addBlock(type);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _addBlock(ContentBlockType type) {
    setState(() {
      final newBlock = ContentBlock(type: type);
      _blocks.add(newBlock);
      _selectedBlockId = newBlock.id;
      _shakingBlockId = newBlock.id;
      _markAsChanged();
    });

    if (Platform.isIOS) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();

      if (mounted && _shakeController != null) {
        _shakeController!.reset();
        _shakeController!.forward();
      }

      if (Platform.isIOS) {
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.selectionClick();
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          HapticFeedback.selectionClick();
        });
      }

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted &&
            _blocks.isNotEmpty &&
            (type == ContentBlockType.text ||
                type == ContentBlockType.header)) {
          _showBlockSettings(_blocks.last);
        }
      });
    });
  }

  void _duplicateBlock(ContentBlock block) {
    setState(() {
      final duplicate = ContentBlock(
        type: block.type,
        content: Map<String, dynamic>.from(block.content),
      );
      final index = _blocks.indexWhere((b) => b.id == block.id);
      _blocks.insert(index + 1, duplicate);
      _selectedBlockId = duplicate.id;
      _shakingBlockId = duplicate.id;
      _markAsChanged();
    });

    if (Platform.isIOS) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _shakeController != null) {
        _shakeController!.reset();
        _shakeController!.forward();
      }

      if (Platform.isIOS) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) HapticFeedback.selectionClick();
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) HapticFeedback.selectionClick();
        });
      }
    });
  }

  void _deleteBlock(String blockId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            AppStrings.deleteBlockTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            AppStrings.deleteBlockMessage,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text(
                AppStrings.delete,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _blocks.removeWhere((b) => b.id == blockId);
                  if (_selectedBlockId == blockId) {
                    _selectedBlockId = null;
                  }
                  _markAsChanged();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? AppColors.error.withOpacity(0.3)
                    : AppColors.greyLighter,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? AppColors.shadowDark : AppColors.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.error.withOpacity(0.2),
                        AppColors.error.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    size: 56,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppStrings.deleteBlockTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppStrings.deleteBlockMessage,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.greyLight,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppStrings.cancel,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _blocks.removeWhere((b) => b.id == blockId);
                              if (_selectedBlockId == blockId) {
                                _selectedBlockId = null;
                              }
                              _markAsChanged();
                            });
                            Navigator.pop(ctx);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.textLight,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            AppStrings.delete,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _reorderBlocks(int oldIndex, int newIndex) {
    if (oldIndex >= _blocks.length || newIndex > _blocks.length) {
      if (Platform.isIOS) {
        HapticFeedback.heavyImpact();
      }
      return;
    }

    if (Platform.isIOS) {
      HapticFeedback.selectionClick();
    }

    try {
      setState(() {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }

        if (newIndex < 0 ||
            newIndex >= _blocks.length ||
            oldIndex < 0 ||
            oldIndex >= _blocks.length) {
          throw RangeError('Invalid index');
        }

        final block = _blocks.removeAt(oldIndex);
        _blocks.insert(newIndex, block);
        _markAsChanged();
      });
    } catch (e) {
      debugPrint('❌ Reorder failed: $e');
      if (Platform.isIOS) {
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _updateBlockContent(String blockId, String key, dynamic value) {
    setState(() {
      final index = _blocks.indexWhere((b) => b.id == blockId);
      if (index != -1) {
        _blocks[index] = _blocks[index].updateContent(key, value);
        _markAsChanged();
      }
    });
  }

  void _showBlockSettings(ContentBlock block) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlockSettingsBottomSheet(
        block: block,
        memorialId: widget.memorial.id,
        onUpdate: (key, value) => _updateBlockContent(block.id, key, value),
      ),
    );
  }

  void _showPreview() {
    debugPrint('🔘 _showPreview() called at ${DateTime.now()}');

    final currentMemorial = widget.memorial.copyWith(
      contentBlocks: _blocks,
    );

    showWebPreview(
      context: context,
      memorial: currentMemorial,
    );
  }

  void _save() {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final updatedMemorial = widget.memorial.copyWith(
      contentBlocks: _blocks,
    );

    context.read<MemorialBloc>().add(
          MemorialUpdateRequested(memorial: updatedMemorial),
        );

    setState(() {
      _hasUnsavedChanges = false;
    });

    _showSuccessToast(AppStrings.pageSaved);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });
  }
}

// ============================================================
// iOS Native Bottom Toast
// ============================================================
class _IOSBottomToast extends StatefulWidget {
  final String message;
  final bool isDark;
  final VoidCallback onDismiss;

  const _IOSBottomToast({
    required this.message,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  State<_IOSBottomToast> createState() => _IOSBottomToastState();
}

class _IOSBottomToastState extends State<_IOSBottomToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();

    HapticFeedback.lightImpact();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: bottomPadding + 100,
      left: 0,
      right: 0,
      child: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? AppColors.toastBackgroundDark.withOpacity(0.95)
                        : AppColors.toastBackgroundLight.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isDark
                            ? AppColors.shadowDark
                            : AppColors.shadow,
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: widget.isDark
                          ? AppColors.borderDark
                          : AppColors.greyLighter,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark_alt,
                          color: AppColors.textLight,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                            fontFamily: '.SF Pro Text',
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
