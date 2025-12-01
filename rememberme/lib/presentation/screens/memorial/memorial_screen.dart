import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_event.dart';
import 'package:rememberme/business_logic/memorial/memorial_state.dart';
import 'package:rememberme/presentation/widgets/memorial/paginatedContentPreview.dart';
import 'package:rememberme/presentation/widgets/preview/web_preview_mixin.dart';
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
          }
        }

        if (state.hasError && state.errorMessage != null) {
          _showErrorSnackBar(context, state.errorMessage!);
        }

        if (state.status == MemorialStatus.success &&
            state.successMessage != null) {
          _showSuccessSnackBar(context, state.successMessage!);
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

          final updatedMemorial = state.memorials.firstWhere(
            (m) => m.id == memorialData.id,
            orElse: () => memorialData,
          );

          if (Platform.isIOS) {
            return _buildIOSView(context, updatedMemorial);
          }
          return _buildAndroidView(context, updatedMemorial);
        },
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (Platform.isIOS) {
      final brightness = CupertinoTheme.brightnessOf(context);
      final isDark = brightness == Brightness.dark;

      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            AppStrings.errorTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.ok,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
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

  void _showSuccessSnackBar(BuildContext context, String message) {
    if (Platform.isIOS) {
      return;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
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
      final brightness = CupertinoTheme.brightnessOf(context);
      final iosDark = brightness == Brightness.dark;

      return CupertinoPageScaffold(
        backgroundColor:
            iosDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            AppStrings.myMemorialPage,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: iosDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(radius: 20),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : null,
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

  Widget _buildAndroidView(BuildContext context, MemorialPageModel memorial) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : null,
      appBar: AppBar(
        title: Text(AppStrings.myMemorialPage),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: SafeArea(
        child: RefreshIndicator(
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPrimaryButton(
                        context: context,
                        icon: Icons.edit_rounded,
                        label: AppStrings.editMemorialPage,
                        isDark: isDark,
                        onPressed: () =>
                            _navigateToPageBuilder(context, memorial),
                      ),
                      const SizedBox(height: 12),
                      _buildSecondaryButton(
                        context: context,
                        icon: Icons.visibility_outlined,
                        label: AppStrings.viewPreview,
                        isDark: isDark,
                        onPressed: () => _showPreview(context, memorial),
                      ),
                      const SizedBox(height: 24),
                      _buildContentPreview(context, memorial, isDark),
                      const SizedBox(height: 24),
                      _buildActionsSection(context, memorial, isDark),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSView(BuildContext context, MemorialPageModel memorial) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor:
          isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          AppStrings.myMemorialPage,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
            fontFamily: '.SF Pro Text',
          ),
        ),
        backgroundColor:
            isDark ? const Color(0xFF1C1C1E).withOpacity(0.8) : null,
      ),
      child: SafeArea(
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 17,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
            fontFamily: '.SF Pro Text',
          ),
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
                    _buildHeader(context, memorial, isDark),
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          CupertinoButton(
                            onPressed: () => _showPreview(context, memorial),
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : CupertinoColors.systemGrey6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.eye,
                                  size: 20,
                                  color: isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.viewPreview,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primary,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildContentPreview(context, memorial, isDark),
                          const SizedBox(height: 24),
                          _buildActionsSection(context, memorial, isDark),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF2A2A2A) : AppColors.primary,
          foregroundColor:
              isDark ? const Color(0xFFD0D0D0) : AppColors.textLight,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isDark
                ? const BorderSide(
                    color: Color(0xFF404040),
                    width: 1.5,
                  )
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? const Color(0xFFB0B0B0) : AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(
          color: isDark ? const Color(0xFF404040) : AppColors.primary,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, MemorialPageModel memorial, bool isDark) {
    final theme = Theme.of(context);
    final isIOS = Platform.isIOS;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF1E1E1E),
                  const Color(0xFF121212),
                ]
              : [
                  AppColors.primary.withOpacity(0.1),
                  Colors.transparent,
                ],
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : AppColors.accent.withOpacity(0.1),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF404040)
                        : AppColors.accent.withOpacity(0.4),
                    width: 3,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Icon(
                  isIOS ? CupertinoIcons.heart_fill : Icons.favorite_rounded,
                  size: 56,
                  color: isDark ? const Color(0xFF707070) : AppColors.accent,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: memorial.isPublic
                        ? Colors.green
                        : (isDark
                            ? const Color(0xFF404040)
                            : AppColors.primary),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF121212) : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    memorial.isPublic
                        ? (isIOS ? CupertinoIcons.globe : Icons.public_rounded)
                        : (isIOS
                            ? CupertinoIcons.lock_fill
                            : Icons.lock_rounded),
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            memorial.name,
            style: isIOS
                ? TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? CupertinoColors.white : CupertinoColors.black,
                    letterSpacing: -0.5,
                    fontFamily: '.SF Pro Display',
                  )
                : theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    letterSpacing: 0.15,
                  ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isIOS
                      ? CupertinoIcons.calendar
                      : Icons.calendar_today_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF909090) : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  memorial.lifespan,
                  style: isIOS
                      ? TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? const Color(0xFFD0D0D0)
                              : CupertinoColors.black,
                          fontWeight: FontWeight.w600,
                          fontFamily: '.SF Pro Text',
                        )
                      : theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? const Color(0xFFD0D0D0)
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.25,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview(
      BuildContext context, MemorialPageModel memorial, bool isDark) {
    final theme = Theme.of(context);
    final isIOS = Platform.isIOS;

    if (memorial.contentBlocks.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF404040)
                      : AppColors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isIOS
                    ? CupertinoIcons.photo
                    : Icons.add_photo_alternate_outlined,
                size: 56,
                color: isDark ? const Color(0xFF909090) : AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.noContentYetMemorial,
              style: isIOS
                  ? TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      fontFamily: '.SF Pro Display',
                    )
                  : theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                      letterSpacing: 0.15,
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.addContentHint,
              style: isIOS
                  ? TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.systemGrey,
                      height: 1.5,
                      fontFamily: '.SF Pro Text',
                    )
                  : theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? const Color(0xFF909090)
                          : AppColors.textSecondary,
                      height: 1.5,
                    ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (memorial.contentBlocks.length > 10) {
      return PaginatedContentPreview(
        memorial: memorial,
        isDark: isDark,
        theme: theme,
        isIOS: isIOS,
        getBlockIcon: _getBlockIcon,
        getBlockTypeName: _getBlockTypeName,
      );
    }

    // Standard-Ansicht für 10 oder weniger Elemente
    return _buildStandardContentGrid(context, memorial, isDark, theme, isIOS);
  }

  Widget _buildStandardContentGrid(
    BuildContext context,
    MemorialPageModel memorial,
    bool isDark,
    ThemeData theme,
    bool isIOS,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentHeader(memorial, isDark, theme, isIOS),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: memorial.contentBlocks.length,
            itemBuilder: (context, index) {
              final block = memorial.contentBlocks[index];
              return _buildContentBlockItem(
                block: block,
                index: index,
                isDark: isDark,
                theme: theme,
                isIOS: isIOS,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentHeader(
    MemorialPageModel memorial,
    bool isDark,
    ThemeData theme,
    bool isIOS,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF404040)
                      : AppColors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isIOS ? CupertinoIcons.square_grid_2x2 : Icons.widgets_rounded,
                size: 20,
                color: isDark ? const Color(0xFF909090) : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppStrings.contents,
              style: isIOS
                  ? TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      fontFamily: '.SF Pro Display',
                    )
                  : theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                      letterSpacing: 0.15,
                    ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A2A2A)
                : AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF404040)
                  : AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${memorial.contentBlocks.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFB0B0B0) : AppColors.primary,
              fontFamily: isIOS ? '.SF Pro Text' : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentBlockItem({
    required ContentBlock block,
    required int index,
    required bool isDark,
    required ThemeData theme,
    required bool isIOS,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF383838) : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF383838)
                  : AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFB0B0B0) : AppColors.primary,
                  decoration: TextDecoration.none,
                  fontFamily: isIOS ? '.SF Pro Text' : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            _getBlockIcon(block.type, isIOS),
            size: 16,
            color: isDark ? const Color(0xFF909090) : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _getBlockTypeName(block.type),
              style: isIOS
                  ? TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFD0D0D0)
                          : CupertinoColors.black,
                      fontFamily: '.SF Pro Text',
                    )
                  : theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFFD0D0D0)
                          : AppColors.textPrimary,
                    ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(
      BuildContext context, MemorialPageModel memorial, bool isDark) {
    final theme = Theme.of(context);
    final isIOS = Platform.isIOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF404040)
                        : AppColors.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isIOS ? CupertinoIcons.settings : Icons.settings_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF909090) : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.moreOptions,
                style: isIOS
                    ? TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                        fontFamily: '.SF Pro Display',
                      )
                    : theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                        letterSpacing: 0.15,
                      ),
              ),
            ],
          ),
        ),

        // Visibility Toggle
        _buildVisibilityToggleTile(context, memorial, isDark),
        const SizedBox(height: 12),

        // Delete Action
        _buildActionTile(
          context,
          isIOS ? CupertinoIcons.trash : Icons.delete_outline_rounded,
          AppStrings.deleteMemorial,
          AppStrings.deleteMemorialPage,
          () => _showDeleteDialog(context, memorial.id),
          isDark: isDark,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildVisibilityToggleTile(
      BuildContext context, MemorialPageModel memorial, bool isDark) {
    final theme = Theme.of(context);
    final isIOS = Platform.isIOS;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: memorial.isPublic
                  ? Colors.green.withOpacity(0.12)
                  : (isDark
                      ? const Color(0xFF2A2A2A)
                      : AppColors.primary.withOpacity(0.08)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: memorial.isPublic
                    ? Colors.green.withOpacity(0.3)
                    : (isDark
                        ? const Color(0xFF404040)
                        : AppColors.primary.withOpacity(0.2)),
                width: 1.5,
              ),
            ),
            child: Icon(
              memorial.isPublic
                  ? (isIOS ? CupertinoIcons.globe : Icons.public_rounded)
                  : (isIOS ? CupertinoIcons.lock_fill : Icons.lock_rounded),
              color: memorial.isPublic
                  ? Colors.green
                  : (isDark ? const Color(0xFF909090) : AppColors.primary),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sichtbarkeit',
                  style: isIOS
                      ? TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          fontFamily: '.SF Pro Text',
                        )
                      : theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                          letterSpacing: 0.15,
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  memorial.isPublic
                      ? 'Öffentlich – Jeder kann die Seite sehen'
                      : 'Privat – Nur eingeladene Personen',
                  style: isIOS
                      ? TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.systemGrey,
                          height: 1.4,
                          fontFamily: '.SF Pro Text',
                        )
                      : theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? const Color(0xFF909090)
                              : AppColors.textSecondary,
                          height: 1.4,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          isIOS
              ? CupertinoSwitch(
                  value: memorial.isPublic,
                  onChanged: (value) {
                    context.read<MemorialBloc>().add(
                          MemorialVisibilityToggleRequested(
                            memorialId: memorial.id,
                            isPublic: value,
                          ),
                        );
                  },
                  activeTrackColor: CupertinoColors.systemGreen,
                )
              : Switch(
                  value: memorial.isPublic,
                  onChanged: (value) {
                    context.read<MemorialBloc>().add(
                          MemorialVisibilityToggleRequested(
                            memorialId: memorial.id,
                            isPublic: value,
                          ),
                        );
                  },
                  activeColor: Colors.green,
                  activeTrackColor: Colors.green.withOpacity(0.3),
                  inactiveThumbColor:
                      isDark ? const Color(0xFF606060) : Colors.grey.shade400,
                  inactiveTrackColor:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
                ),
        ],
      ),
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
    final isIOS = Platform.isIOS;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: isDestructive
            ? AppColors.error.withOpacity(0.1)
            : (isDark
                ? Colors.white.withOpacity(0.05)
                : AppColors.primary.withOpacity(0.08)),
        highlightColor: isDestructive
            ? AppColors.error.withOpacity(0.05)
            : (isDark
                ? Colors.white.withOpacity(0.03)
                : AppColors.primary.withOpacity(0.04)),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive
                  ? AppColors.error.withOpacity(0.3)
                  : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppColors.error.withOpacity(0.12)
                      : (isDark
                          ? const Color(0xFF2A2A2A)
                          : AppColors.primary.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDestructive
                        ? AppColors.error.withOpacity(0.3)
                        : (isDark
                            ? const Color(0xFF404040)
                            : AppColors.primary.withOpacity(0.2)),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? AppColors.error
                      : (isDark ? const Color(0xFF909090) : AppColors.primary),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: isIOS
                          ? TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isDestructive
                                  ? AppColors.error
                                  : (isDark
                                      ? CupertinoColors.white
                                      : CupertinoColors.black),
                              fontFamily: '.SF Pro Text',
                            )
                          : theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDestructive
                                  ? AppColors.error
                                  : (isDark
                                      ? AppColors.textLight
                                      : AppColors.textPrimary),
                              letterSpacing: 0.15,
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: isIOS
                          ? TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.systemGrey,
                              height: 1.4,
                              fontFamily: '.SF Pro Text',
                            )
                          : theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? const Color(0xFF909090)
                                  : AppColors.textSecondary,
                              height: 1.4,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isIOS
                      ? CupertinoIcons.chevron_right
                      : Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color:
                      isDark ? const Color(0xFF707070) : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getBlockIcon(ContentBlockType type, bool isIOS) {
    if (isIOS) {
      switch (type) {
        case ContentBlockType.text:
          return CupertinoIcons.textformat;
        case ContentBlockType.video:
          return CupertinoIcons.videocam;
        case ContentBlockType.gallery:
          return CupertinoIcons.photo_on_rectangle;
        case ContentBlockType.image:
          return CupertinoIcons.photo;
        case ContentBlockType.quote:
          return CupertinoIcons.quote_bubble;
        default:
          return CupertinoIcons.doc;
      }
    } else {
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
    // Navigator vorher capturen, bevor async-Calls passieren
    final navigator = Navigator.of(context);

    showWebPreviewStandalone(
      context: context,
      memorial: memorial,
    );
  }

  void _showDeleteDialog(BuildContext context, String memorialId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      final brightness = CupertinoTheme.brightnessOf(context);
      final iosDark = brightness == Brightness.dark;

      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            AppStrings.confirmDeleteTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: iosDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            AppStrings.confirmDelete,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 17,
                  color: iosDark
                      ? CupertinoColors.systemBlue
                      : CupertinoColors.systemBlue,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                context
                    .read<MemorialBloc>()
                    .add(MemorialDeleteRequested(memorialId: memorialId));
                Navigator.of(ctx).pop();
              },
              isDestructiveAction: true,
              child: Text(
                AppStrings.delete,
                style: const TextStyle(
                  fontSize: 17,
                  fontFamily: '.SF Pro Text',
                ),
              ),
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
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.error.withOpacity(0.3),
                width: 1.5,
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
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.error.withOpacity(0.15),
                        AppColors.error.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.error,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          AppStrings.confirmDeleteTitle,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.textLight
                                        : AppColors.textPrimary,
                                    letterSpacing: 0.15,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    AppStrings.confirmDelete,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: isDark
                              ? const Color(0xFFB0B0B0)
                              : AppColors.textSecondary,
                          letterSpacing: 0.25,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<MemorialBloc>().add(
                                MemorialDeleteRequested(
                                    memorialId: memorialId));
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.textLight,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppStrings.delete,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
