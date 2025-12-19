import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_event.dart';
import 'package:rememberme/business_logic/memorial/memorial_state.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            AppStrings.errorTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              isDefaultAction: true,
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
          content: Text(
            message,
            style: const TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.error,
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
          content: Text(
            message,
            style: const TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildLoadingScreen(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            AppStrings.myMemorialPage,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          backgroundColor: isDark
              ? AppColors.backgroundDarkElevated.withOpacity(0.8)
              : AppColors.surface.withOpacity(0.94),
        ),
        child: Center(
          child: CupertinoActivityIndicator(
            radius: 20,
            color: isDark ? AppColors.grey : null,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.myMemorialPage,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
        foregroundColor: isDark ? AppColors.textLight : AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? AppColors.accent : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidView(BuildContext context, MemorialPageModel memorial) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.myMemorialPage,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
        foregroundColor: isDark ? AppColors.textLight : AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<MemorialBloc>().add(
                  MemorialDetailLoadRequested(memorialId: memorial.id),
                );
          },
          color: isDark ? AppColors.accent : AppColors.primary,
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
                      _buildPrimaryButton(
                        context: context,
                        icon: Icons.visibility_outlined,
                        label: AppStrings.viewPreview,
                        isDark: isDark,
                        onPressed: () => _showPreview(context, memorial),
                      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          AppStrings.myMemorialPage,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
            fontFamily: '.SF Pro Text',
          ),
        ),
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
      ),
      child: SafeArea(
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 17,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
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
                          // Edit Button - filled style
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
                          // Preview Button - NOW ALSO filled style (same as edit button)
                          CupertinoButton.filled(
                            onPressed: () => _showPreview(context, memorial),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(CupertinoIcons.eye, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.viewPreview,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.accent : AppColors.primary,
          foregroundColor: isDark ? AppColors.primary : AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? AppColors.primary : AppColors.background,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.primary : AppColors.background,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, MemorialPageModel memorial, bool isDark) {
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
                  AppColors.backgroundDark,
                  AppColors.backgroundDark,
                ]
              : [
                  AppColors.primary.withOpacity(0.08),
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
                  color: AppColors.accent.withOpacity(0.1),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.4),
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
                  color: AppColors.accent,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: memorial.isPublic
                        ? AppColors.accent
                        : (isDark
                            ? AppColors.borderDarkSubtle
                            : AppColors.primary),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.accent.withOpacity(0.4)
                          : AppColors.surface,
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
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            memorial.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              letterSpacing: -0.5,
              fontFamily: isIOS ? '.SF Pro Display' : null,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    isDark ? AppColors.borderDarkSubtle : AppColors.greyLight,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? AppColors.shadowDark : AppColors.shadow,
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
                  color: isDark ? AppColors.grey : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  memorial.lifespan,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFamily: isIOS ? '.SF Pro Text' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(
      BuildContext context, MemorialPageModel memorial, bool isDark) {
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
                      ? AppColors.toastBackgroundDark
                      : AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDarkSubtle
                        : AppColors.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isIOS ? CupertinoIcons.settings : Icons.settings_rounded,
                  size: 18,
                  color: isDark ? AppColors.grey : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.moreOptions,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  fontFamily: isIOS ? '.SF Pro Display' : null,
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
    final isIOS = Platform.isIOS;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadow,
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
                  ? AppColors.accent.withOpacity(0.4)
                  : (isDark
                      ? AppColors.toastBackgroundDark
                      : AppColors.primary.withOpacity(0.08)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: memorial.isPublic
                    ? AppColors.accent
                    : (isDark
                        ? AppColors.borderDarkSubtle
                        : AppColors.primary.withOpacity(0.2)),
                width: 1.5,
              ),
            ),
            child: Icon(
              memorial.isPublic
                  ? (isIOS ? CupertinoIcons.globe : Icons.public_rounded)
                  : (isIOS ? CupertinoIcons.lock_fill : Icons.lock_rounded),
              color: memorial.isPublic
                  ? AppColors.accent
                  : (isDark ? AppColors.grey : AppColors.primary),
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
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    fontFamily: isIOS ? '.SF Pro Text' : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  memorial.isPublic
                      ? 'Öffentlich – Jeder kann die Seite sehen'
                      : 'Privat – Nur eingeladene Personen',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.grey,
                    height: 1.4,
                    fontFamily: isIOS ? '.SF Pro Text' : null,
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
                  activeTrackColor: AppColors.accent,
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
                  activeColor: AppColors.accent,
                  activeTrackColor: AppColors.accent.withOpacity(0.3),
                  inactiveThumbColor:
                      isDark ? AppColors.greyDark : AppColors.grey,
                  inactiveTrackColor: isDark
                      ? AppColors.toastBackgroundDark
                      : AppColors.greyLight,
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
    final isIOS = Platform.isIOS;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: isDestructive
            ? AppColors.error.withOpacity(0.1)
            : (isDark
                ? AppColors.textLight.withOpacity(0.05)
                : AppColors.primary.withOpacity(0.08)),
        highlightColor: isDestructive
            ? AppColors.error.withOpacity(0.05)
            : (isDark
                ? AppColors.textLight.withOpacity(0.03)
                : AppColors.primary.withOpacity(0.04)),
        child: Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive
                  ? AppColors.error.withOpacity(0.3)
                  : (isDark ? AppColors.borderDark : AppColors.greyLighter),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? AppColors.shadowDark : AppColors.shadow,
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
                          ? AppColors.toastBackgroundDark
                          : AppColors.primary.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDestructive
                        ? AppColors.error.withOpacity(0.3)
                        : (isDark
                            ? AppColors.borderDarkSubtle
                            : AppColors.primary.withOpacity(0.2)),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? AppColors.error
                      : (isDark ? AppColors.grey : AppColors.primary),
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
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDestructive
                            ? AppColors.error
                            : (isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary),
                        fontFamily: isIOS ? '.SF Pro Text' : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.grey,
                        height: 1.4,
                        fontFamily: isIOS ? '.SF Pro Text' : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.error.withOpacity(0.3)
                      : AppColors.greyLighter,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isIOS
                      ? CupertinoIcons.chevron_right
                      : Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? AppColors.error : AppColors.greyDark,
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
    showWebPreviewStandalone(
      context: context,
      memorial: memorial,
    );
  }

  void _showDeleteDialog(BuildContext context, String memorialId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            AppStrings.confirmDeleteTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            AppStrings.confirmDelete,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
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
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
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
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.error.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? AppColors.shadowDark
                      : AppColors.shadow.withOpacity(0.4),
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
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
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
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.grey,
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
                                  ? AppColors.borderDarkSubtle
                                  : AppColors.greyLight,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppStrings.cancel,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            context.read<MemorialBloc>().add(
                                MemorialDeleteRequested(
                                    memorialId: memorialId));
                            Navigator.of(ctx).pop();
                          },
                          style: FilledButton.styleFrom(
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
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
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
