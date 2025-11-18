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
        print('📊 MemorialDetailScreen - State geändert: ${state.status}');
        print('📊 Anzahl Memorials: ${state.memorials.length}');

        if (state.status == MemorialStatus.success) {
          if (state.memorials.isEmpty) {
            print('✅ Letztes Memorial gelöscht - navigiere zurück zum Root');
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            print(
                '✅ Memorial gelöscht, aber noch ${state.memorials.length} vorhanden');
            Navigator.of(context).pop();
          }
        }

        if (state.hasError && state.errorMessage != null) {
          print('❌ Fehler: ${state.errorMessage}');
          _showErrorSnackBar(context, state.errorMessage!);
        }
      },
      child: BlocBuilder<MemorialBloc, MemorialState>(
        builder: (context, state) {
          print('🏗️ MemorialDetailScreen wird gebaut...');
          print('🏗️ Memorial Parameter: ${memorial?.name ?? "null"}');
          print('🏗️ State Memorials: ${state.memorials.length}');
          print('🏗️ State Status: ${state.status}');

          if (memorial == null && state.memorials.isEmpty) {
            print('🎨 Kein Memorial vorhanden - zeige Create Screen');

            if (state.status == MemorialStatus.initial) {
              print('🔄 Status ist initial - lade Memorials');
              final authState = context.read<AuthBloc>().state;
              final user = authState.user;

              if (user != null && user.primaryOrganizationId != null) {
                print('📚 Lade Memorials für User: ${user.name}');
                print('🏢 Organisation: ${user.primaryOrganizationId}');

                context.read<MemorialBloc>().add(
                      MemorialLoadRequested(
                        organizationId: user.primaryOrganizationId!,
                      ),
                    );
              }
            }

            if (state.isLoading && state.status == MemorialStatus.loading) {
              print('⏳ Lade Memorials...');
              return _buildLoadingScreen(context);
            }

            print('✨ Zeige MemorialCreateScreen');
            return const MemorialCreateScreen();
          }

          final memorialData = memorial ??
              state.selectedMemorial ??
              (ModalRoute.of(context)?.settings.arguments
                  as MemorialPageModel?);

          if (memorialData == null) {
            print('⚠️ Keine Memorial-Daten gefunden - zeige Create Screen');
            return const MemorialCreateScreen();
          }

          print('📄 Zeige Detail-Screen für: ${memorialData.name}');

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
          title: const Text('Fehler'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
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
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Meine Gedenkseite'),
        ),
        child: Center(
          child: CupertinoActivityIndicator(radius: 20),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Gedenkseite'),
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
        title: const Text('Meine Gedenkseite'),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          print('🔄 Pull-to-Refresh: Lade Memorial neu');
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
                      label: const Text(
                        'Gedenkseite bearbeiten',
                        style: TextStyle(
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
                      label: const Text(
                        'Vorschau ansehen',
                        style: TextStyle(
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
        middle: const Text('Meine Gedenkseite'),
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                print('🔄 Pull-to-Refresh: Lade Memorial neu');
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
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.pencil, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Gedenkseite bearbeiten',
                                style: TextStyle(fontSize: 16),
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
                                'Vorschau ansehen',
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryLight.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 48,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Noch keine Inhalte',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Füge Texte, Bilder oder Videos hinzu',
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
                  'Inhalte',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryLight.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${memorial.contentBlocks.length} ${memorial.contentBlocks.length == 1 ? "Block" : "Blöcke"}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: memorial.contentBlocks.asMap().entries.map((entry) {
                final index = entry.key;
                final block = entry.value;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF404040)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primaryLight.withOpacity(0.2)
                              : AppColors.primary.withOpacity(0.15),
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
                      Icon(
                        _getBlockIcon(block.type),
                        size: 18,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getBlockTypeName(block.type),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
          'Weitere Optionen',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          context,
          Icons.delete_outline_rounded,
          'Löschen',
          'Gedenkseite entfernen',
          () => _showDeleteDialog(context, memorial.id),
          isDark: isDark,
          isDestructive: true,
        ),
      ],
    );
  }

  // ✅ FIXED: Platform-Check für InkWell vs GestureDetector
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

    // ✅ FIX: Verwende GestureDetector für iOS, InkWell für Android
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
        return 'Text';
      case ContentBlockType.video:
        return 'Video';
      case ContentBlockType.gallery:
        return 'Galerie';
      case ContentBlockType.image:
        return 'Bild';
      case ContentBlockType.quote:
        return 'Zitat';
      default:
        return type.toString().split('.').last;
    }
  }

  void _navigateToPageBuilder(
      BuildContext context, MemorialPageModel memorial) {
    print('📝 Navigiere zum PageBuilder für: ${memorial.name}');
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.pageBuilder,
      arguments: memorial,
    );
  }

  void _showPreview(BuildContext context, MemorialPageModel memorial) {
    print('👁️ Zeige Vorschau für: ${memorial.name}');

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => CupertinoAlertDialog(
          content: const Text('Vorschau wird geladen...'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vorschau wird geladen...'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _publishMemorial(BuildContext context, MemorialPageModel memorial) {
    print('🌐 Veröffentlichungs-Dialog für: ${memorial.name}');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Veröffentlichen'),
          content: const Text(
            'Möchtest du deine Gedenkseite jetzt veröffentlichen? Sie wird dann für andere sichtbar.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                context
                    .read<MemorialBloc>()
                    .add(MemorialPublishRequested(memorialId: memorial.id));
                Navigator.of(ctx).pop();
              },
              isDefaultAction: true,
              child: const Text('Veröffentlichen'),
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
          title: const Text('Veröffentlichen'),
          content: const Text(
            'Möchtest du deine Gedenkseite jetzt veröffentlichen? Sie wird dann für andere sichtbar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
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
              child: const Text('Veröffentlichen'),
            ),
          ],
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, String memorialId) {
    print('🗑️ Delete Dialog geöffnet für Memorial-ID: $memorialId');

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Löschen bestätigen'),
          content: const Text(AppStrings.confirmDelete),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                context
                    .read<MemorialBloc>()
                    .add(MemorialDeleteRequested(memorialId: memorialId));
                Navigator.of(ctx).pop();
              },
              isDestructiveAction: true,
              child: const Text('Löschen'),
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
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
              ),
              const SizedBox(width: 12),
              const Text('Löschen bestätigen'),
            ],
          ),
          content: const Text(AppStrings.confirmDelete),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.cancel),
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
              child: const Text(AppStrings.delete),
            ),
          ],
        ),
      );
    }
  }
}
