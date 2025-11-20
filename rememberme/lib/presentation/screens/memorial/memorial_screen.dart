import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_event.dart';
import 'package:rememberme/business_logic/memorial/memorial_state.dart';
import '../../../data/models/memorial_page_model.dart' hide MemorialStatus;
import '../../../data/models/content_block_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import 'memorial_create_screen.dart';

class MemorialDetailScreen extends StatelessWidget {
  final MemorialPageModel? memorial;

  const MemorialDetailScreen({super.key, this.memorial});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MemorialBloc, MemorialState>(
      listener: (context, state) {
        if (state.status == MemorialStatus.success) {
          if (state.memorials.isEmpty) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            Navigator.of(context).pop();
          }
        }

        if (state.hasError && state.errorMessage != null) {
          _showErrorSnackBar(context, state.errorMessage!);
        }
      },
      child: BlocBuilder<MemorialBloc, MemorialState>(
        builder: (context, state) {
          if (memorial == null && state.memorials.isEmpty) {
            if (state.status == MemorialStatus.initial) {
              final authState = context.read<AuthBloc>().state;
              final user = authState.user;

              if (user != null && user.primaryOrganizationId != null) {
                context.read<MemorialBloc>().add(
                      MemorialLoadRequested(
                        organizationId: user.primaryOrganizationId!,
                      ),
                    );
              }
            }

            if (state.isLoading && state.status == MemorialStatus.loading) {
              return _buildLoadingScreen(context);
            }

            return const MemorialCreateScreen();
          }

          final memorialData = memorial ??
              state.selectedMemorial ??
              (ModalRoute.of(context)?.settings.arguments
                  as MemorialPageModel?);

          if (memorialData == null) {
            return const MemorialCreateScreen();
          }

          if (Platform.isIOS) {
            return _buildIOSView(context, memorialData);
          }
          return _buildAndroidView(context, memorialData);
        },
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(AppStrings.errorTitle),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.ok),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildLoadingScreen(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(AppStrings.myMemorialPage),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(radius: 20),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.myMemorialPage),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ===== ANDROID (Material Design) =====
  Widget _buildAndroidView(BuildContext context, MemorialPageModel memorial) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.myMemorialPage),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<MemorialBloc>().add(
                MemorialDetailLoadRequested(memorialId: memorial.id),
              );
        },
        color: isDark ? AppColors.primaryLight : AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context, memorial, isDark),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          _navigateToPageBuilder(context, memorial),
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      label: Text(
                        AppStrings.editMemorialPage,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                        foregroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showPreview(context, memorial),
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                      label: Text(
                        AppStrings.viewPreview,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildContentPreview(context, memorial, isDark),
                    const SizedBox(height: 28),
                    _buildActionsSection(context, memorial, isDark),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== iOS (Cupertino Design) =====
  Widget _buildIOSView(BuildContext context, MemorialPageModel memorial) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.myMemorialPage),
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                context.read<MemorialBloc>().add(
                      MemorialDetailLoadRequested(memorialId: memorial.id),
                    );
              },
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeader(context, memorial, false),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CupertinoButton.filled(
                          onPressed: () =>
                              _navigateToPageBuilder(context, memorial),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.pencil, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.editMemorialPage,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoButton(
                          onPressed: () => _showPreview(context, memorial),
                          color:
                              CupertinoColors.systemGrey6.resolveFrom(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.eye,
                                size: 20,
                                color:
                                    CupertinoColors.label.resolveFrom(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.viewPreview,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: CupertinoColors.label
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildContentPreview(context, memorial, false),
                        const SizedBox(height: 24),
                        _buildActionsSection(context, memorial, false),
                        const SizedBox(height: 24),
                      ],
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

  Widget _buildHeader(
      BuildContext context, MemorialPageModel memorial, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  AppColors.primaryLight.withOpacity(0.15),
                  Colors.transparent,
                ]
              : [
                  AppColors.primary.withOpacity(0.1),
                  Colors.transparent,
                ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.accent.withOpacity(0.3),
                        AppColors.primaryLight.withOpacity(0.2),
                      ]
                    : [
                        AppColors.accent.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.1),
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? AppColors.accent.withOpacity(0.4)
                    : AppColors.accent.withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 48,
              color:
                  isDark ? AppColors.accent.withOpacity(0.9) : AppColors.accent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            memorial.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
              ),
            ),
            child: Text(
              memorial.lifespan,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview(
      BuildContext context, MemorialPageModel memorial, bool isDark) {
    final theme = Theme.of(context);

    if (memorial.contentBlocks.isEmpty) {
      return Card(
        elevation: isDark ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryLight.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 56,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.noContentYetMemorial,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.addContentHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? const Color(0xFFB0B0B0)
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.contents,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryLight.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${memorial.contentBlocks.length} ${memorial.contentBlocks.length == 1 ? AppStrings.block : AppStrings.blocks}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Grid Layout mit FittedBox für automatische Skalierung
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5, // Etwas mehr Höhe für bessere Lesbarkeit
              ),
              itemCount: memorial.contentBlocks.length,
              itemBuilder: (context, index) {
                final block = memorial.contentBlocks[index];

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF404040)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nummer-Badge
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primaryLight.withOpacity(0.2)
                                : AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Icon
                        Icon(
                          _getBlockIcon(block.type),
                          size: 18,
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        // Text
                        Text(
                          _getBlockTypeName(block.type),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(
      BuildContext context, MemorialPageModel memorial, bool isDark) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.moreOptions,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          context,
          Icons.delete_outline_rounded,
          AppStrings.deleteMemorial,
          AppStrings.deleteMemorialPage,
          () => _showDeleteDialog(context, memorial.id),
          isDark: isDark,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    required bool isDark,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.textLight : AppColors.textPrimary);

    final cardContent = Card(
      elevation: isDark ? 1 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDestructive
              ? AppColors.error.withOpacity(0.3)
              : (isDark ? const Color(0xFF404040) : Colors.grey.shade300),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.error.withOpacity(0.1)
                    : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? const Color(0xFFB0B0B0)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Platform.isIOS
                  ? CupertinoIcons.chevron_right
                  : Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF707070) : Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );

    if (Platform.isIOS) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: cardContent,
    );
  }

  IconData _getBlockIcon(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.text:
        return Icons.text_fields_rounded;
      case ContentBlockType.video:
        return Icons.videocam_outlined;
      case ContentBlockType.gallery:
        return Icons.photo_library_outlined;
      case ContentBlockType.image:
        return Icons.image_outlined;
      case ContentBlockType.quote:
        return Icons.format_quote_rounded;
      default:
        return Icons.article_outlined;
    }
  }

  String _getBlockTypeName(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.text:
        return AppStrings.blockTypeText;
      case ContentBlockType.video:
        return AppStrings.blockTypeVideo;
      case ContentBlockType.gallery:
        return AppStrings.blockTypeGallery;
      case ContentBlockType.image:
        return AppStrings.blockTypeImage;
      case ContentBlockType.quote:
        return AppStrings.blockTypeQuote;
      default:
        return type.toString().split('.').last;
    }
  }

  void _navigateToPageBuilder(
      BuildContext context, MemorialPageModel memorial) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.pageBuilder,
      arguments: memorial,
    );
  }

  void _showPreview(BuildContext context, MemorialPageModel memorial) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => CupertinoAlertDialog(
          content: Text(AppStrings.previewLoading),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.ok),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.previewLoading),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _publishMemorial(BuildContext context, MemorialPageModel memorial) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(AppStrings.publishMemorial),
          content: Text(AppStrings.publishMemorialMessage),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.cancel),
            ),
            CupertinoDialogAction(
              onPressed: () {
                context
                    .read<MemorialBloc>()
                    .add(MemorialPublishRequested(memorialId: memorial.id));
                Navigator.of(ctx).pop();
              },
              isDefaultAction: true,
              child: Text(AppStrings.publishMemorial),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(AppStrings.publishMemorial),
          content: Text(AppStrings.publishMemorialMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () {
                context
                    .read<MemorialBloc>()
                    .add(MemorialPublishRequested(memorialId: memorial.id));
                Navigator.of(ctx).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.primaryLight : AppColors.success,
              ),
              child: Text(AppStrings.publishMemorial),
            ),
          ],
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, String memorialId) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(AppStrings.confirmDeleteTitle),
          content: Text(AppStrings.confirmDelete),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.cancel),
            ),
            CupertinoDialogAction(
              onPressed: () {
                context
                    .read<MemorialBloc>()
                    .add(MemorialDeleteRequested(memorialId: memorialId));
                Navigator.of(ctx).pop();
              },
              isDestructiveAction: true,
              child: Text(AppStrings.delete),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
              ),
              const SizedBox(width: 12),
              Text(AppStrings.confirmDeleteTitle),
            ],
          ),
          content: Text(AppStrings.confirmDelete),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: () {
                context
                    .read<MemorialBloc>()
                    .add(MemorialDeleteRequested(memorialId: memorialId));
                Navigator.of(ctx).pop();
              },
              child: Text(AppStrings.delete),
            ),
          ],
        ),
      );
    }
  }
}
