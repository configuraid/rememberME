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
    with TickerProviderStateMixin {
  List<ContentBlock> _blocks = [];
  String? _selectedBlockId;
  bool _hasUnsavedChanges = false;

  // Scroll Controller für automatisches Scrollen
  final ScrollController _scrollController = ScrollController();

  // Animation für Wackel-Effekt
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

  void _showSuccessMessage(String message) {
    if (Platform.isIOS) {
      final brightness = MediaQuery.of(context).platformBrightness;
      final isDark = brightness == Brightness.dark;

      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CupertinoAlertDialog(
          content: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                AppStrings.ok,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success.withOpacity(0.2),
                        AppColors.success.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    if (Platform.isIOS) {
      final brightness = MediaQuery.of(context).platformBrightness;
      final isDark = brightness == Brightness.dark;

      final shouldPop = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            AppStrings.unsavedChanges,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            AppStrings.unsavedChangesMessage,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(
                AppStrings.discardChanges,
                style: TextStyle(
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
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? AppColors.error.withOpacity(0.3)
                    : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.15),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppStrings.unsavedChangesMessage,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? const Color(0xFFB0B0B0)
                              : AppColors.textSecondary,
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
                                  ? const Color(0xFF404040)
                                  : Colors.grey.shade300,
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
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppStrings.discardChanges,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
        appBar: AppBar(
          title: Text(widget.memorial.name),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
          foregroundColor: AppColors.textLight,
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
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Platform.isIOS
                              ? CupertinoIcons.circle_fill
                              : Icons.circle,
                          color: Colors.orange,
                          size: Platform.isIOS ? 6 : 8,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.notSaved,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (Platform.isIOS)
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minSize: 0,
                onPressed: _showPreview,
                child: Icon(
                  CupertinoIcons.eye,
                  color: AppColors.textLight,
                  size: 24,
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.visibility_rounded),
                  onPressed: _showPreview,
                  tooltip: AppStrings.preview,
                ),
              ),
            if (Platform.isIOS)
              CupertinoButton(
                padding: const EdgeInsets.only(right: 12),
                minSize: 0,
                onPressed: _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_alt,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success,
                      AppColors.success.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.check_rounded),
                  onPressed: _save,
                  tooltip: AppStrings.save,
                  color: Colors.white,
                ),
              ),
          ],
        ),
        body: _blocks.isEmpty
            ? _buildEmptyState(isDark)
            : _buildBlockList(isDark),
        floatingActionButton: Platform.isIOS
            ? Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: CupertinoButton.filled(
                  onPressed: _showAddBlockSheet,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.add, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.addBlock,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : FloatingActionButton.extended(
                onPressed: _showAddBlockSheet,
                icon: const Icon(Icons.add_rounded),
                label: Text(AppStrings.addBlock),
                backgroundColor:
                    isDark ? AppColors.primaryLight : AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
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
                          AppColors.primaryLight.withOpacity(0.2),
                          AppColors.primaryLight.withOpacity(0.1),
                        ]
                      : [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.08),
                        ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.primaryLight.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.article_outlined,
                size: 80,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              AppStrings.noContentYet,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.noContentMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? const Color(0xFFB0B0B0)
                        : AppColors.textSecondary,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Platform.isIOS
                ? CupertinoButton.filled(
                    onPressed: _showAddBlockSheet,
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.add, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          AppStrings.addBlock,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                AppColors.primaryLight,
                                AppColors.primaryLight.withOpacity(0.8),
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
                              ? AppColors.primaryLight.withOpacity(0.3)
                              : AppColors.primary.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _showAddBlockSheet,
                      icon: const Icon(Icons.add_rounded, size: 24),
                      label: Text(
                        AppStrings.addBlock,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
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

  Widget _buildBlockList(bool isDark) {
    return CustomScrollView(
      controller: _scrollController,
      physics: Platform.isIOS
          ? const BouncingScrollPhysics()
          : const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverReorderableList(
            itemCount: _blocks.length,
            onReorder: _reorderBlocks,
            proxyDecorator: _proxyDecorator,
            onReorderStart: (index) {
              if (Platform.isIOS) {
                HapticFeedback.mediumImpact();
              }
            },
            onReorderEnd: (index) {
              if (Platform.isIOS) {
                HapticFeedback.lightImpact();
              }
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
                    // ✅ KORRIGIERT: Verwende direkt den value der Animation
                    double offsetX = 0.0;
                    if (isShaking && _shakeAnimation != null) {
                      try {
                        offsetX = _shakeAnimation!.value;
                      } catch (e) {
                        // Falls ein Fehler auftritt, verwende 0
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
            end: 1.008,
          ).evaluate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ));

          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: 0.95,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              ),
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

      // ✅ SICHERE ANIMATION: Reset vor dem Start
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
        if (type == ContentBlockType.text || type == ContentBlockType.header) {
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
    if (Platform.isIOS) {
      final brightness = MediaQuery.of(context).platformBrightness;
      final isDark = brightness == Brightness.dark;

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            AppStrings.deleteBlockTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            AppStrings.deleteBlockMessage,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(
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
      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? AppColors.error.withOpacity(0.3)
                    : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.15),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppStrings.deleteBlockMessage,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? const Color(0xFFB0B0B0)
                              : AppColors.textSecondary,
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
                                  ? const Color(0xFF404040)
                                  : Colors.grey.shade300,
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
                        child: ElevatedButton(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppStrings.delete,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
      print('❌ Reorder failed: $e');
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PreviewScreen(
          memorial: widget.memorial,
          blocks: _blocks,
        ),
      ),
    );
  }

  void _save() {
    final updatedMemorial = widget.memorial.copyWith(
      contentBlocks: _blocks,
    );

    context.read<MemorialBloc>().add(
          MemorialUpdateRequested(memorial: updatedMemorial),
        );

    setState(() {
      _hasUnsavedChanges = false;
    });

    _showSuccessMessage(AppStrings.pageSaved);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }
}

class _PreviewScreen extends StatelessWidget {
  final MemorialPageModel memorial;
  final List<ContentBlock> blocks;

  const _PreviewScreen({
    required this.memorial,
    required this.blocks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text('${AppStrings.previewPrefix}${memorial.name}'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: blocks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Platform.isIOS
                        ? CupertinoIcons.eye_slash
                        : Icons.preview_rounded,
                    size: 64,
                    color:
                        isDark ? const Color(0xFF404040) : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.noBlocksAvailable,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? const Color(0xFF808080)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                return ContentBlockWidget(
                  block: blocks[index],
                  isSelected: false,
                  isPreview: true,
                  onTap: () {},
                  onEdit: () {},
                  onDuplicate: () {},
                  onDelete: () {},
                  onContentChanged: (_, __) {},
                );
              },
            ),
    );
  }
}
