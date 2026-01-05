// presentation/screens/memorial/memorial_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/presentation/screens/auth/qr_scanner_screen.dart';
import 'package:rememberme/presentation/widgets/show_memorial_share_sheet.dart';
import 'package:rememberme/core/utils/qr_claiming_handler.dart'; // NEU!
import 'package:rememberme/data/repositories/memorial_repository.dart'; // NEU!

import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/memorial/memorial_bloc.dart';
import '../../../business_logic/memorial/memorial_event.dart';
import '../../../business_logic/memorial/memorial_state.dart';
import '../../../data/models/memorial_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import 'memorial_create_screen.dart';
import 'memorial_edit_screen.dart';
import '../../widgets/preview/web_preview_mixin.dart';

class MemorialDetailScreen extends StatefulWidget {
  final MemorialModel? memorial;

  const MemorialDetailScreen({super.key, this.memorial});

  @override
  State<MemorialDetailScreen> createState() => _MemorialDetailScreenState();
}

class _MemorialDetailScreenState extends State<MemorialDetailScreen> {
  // ❌ ENTFERNT: final MemorialValidationService _validationService = MemorialValidationService();

  @override
  void initState() {
    super.initState();
    _loadMemorialsIfNeeded();
  }

  void _loadMemorialsIfNeeded() {
    final state = context.read<MemorialBloc>().state;
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    if (user != null && state.status == MemorialBlocStatus.initial) {
      context.read<MemorialBloc>().add(
            MemorialLoadRequested(userId: user.id),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MemorialBloc, MemorialState>(
      listener: (context, state) {
        if (state.status == MemorialBlocStatus.success) {
          if (state.memorials.isEmpty) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }

        if (state.hasError && state.errorMessage != null) {
          _showErrorSnackBar(context, state.errorMessage!);
        }

        if (state.status == MemorialBlocStatus.success &&
            state.successMessage != null) {
          _showSuccessSnackBar(context, state.successMessage!);
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.status == MemorialBlocStatus.loading) {
          return _buildLoadingScreen(context);
        }

        if (state.memorials.isEmpty) {
          return const MemorialCreateScreen();
        }

        final MemorialModel memorialToShow = widget.memorial ??
            state.selectedMemorial ??
            (ModalRoute.of(context)?.settings.arguments as MemorialModel?) ??
            state.memorials.first;

        final updatedMemorial = state.memorials.firstWhere(
          (m) => m.id == memorialToShow.id,
          orElse: () => memorialToShow,
        );

        if (Platform.isIOS) {
          return _buildIOSView(context, updatedMemorial, state.memorials);
        }
        return _buildAndroidView(context, updatedMemorial, state.memorials);
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(AppStrings.errorTitle),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              isDefaultAction: true,
              child: Text(AppStrings.ok),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(message, style: const TextStyle(color: AppColors.textLight)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    if (!Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(message, style: const TextStyle(color: AppColors.textLight)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          middle: Text(AppStrings.myMemorialPage),
          backgroundColor: isDark
              ? AppColors.backgroundDarkElevated.withOpacity(0.8)
              : AppColors.surface.withOpacity(0.94),
        ),
        child: const Center(child: CupertinoActivityIndicator(radius: 20)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(title: Text(AppStrings.myMemorialPage)),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? AppColors.accent : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidView(BuildContext context, MemorialModel memorial,
      List<MemorialModel> allMemorials) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = context.read<AuthBloc>().state.user?.id;

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
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
        foregroundColor: isDark ? AppColors.textLight : AppColors.textPrimary,
        actions: [
          IconButton(
            onPressed: () => _openQrScanner(context),
            icon: Icon(Icons.qr_code_scanner_rounded,
                color: isDark ? AppColors.accent : AppColors.primary),
            tooltip: 'QR-Code scannen',
          ),
          IconButton(
            onPressed: () => _showShareSheet(context, memorial),
            icon: Icon(Icons.share_rounded,
                color: isDark ? AppColors.accent : AppColors.primary),
          ),
          IconButton(
            onPressed: () => _navigateToEditScreen(context, memorial),
            icon: Icon(Icons.edit_rounded,
                color: isDark ? AppColors.accent : AppColors.primary),
          ),
        ],
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
                      if (allMemorials.length > 1) ...[
                        _buildMemorialSelector(
                          context,
                          memorial,
                          allMemorials,
                          isDark,
                          currentUserId,
                        ),
                        const SizedBox(height: 16),
                      ],
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

  Widget _buildIOSView(BuildContext context, MemorialModel memorial,
      List<MemorialModel> allMemorials) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = context.read<AuthBloc>().state.user?.id;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          AppStrings.myMemorialPage,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _openQrScanner(context),
              child: Icon(CupertinoIcons.qrcode_viewfinder,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  size: 24),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showShareSheet(context, memorial),
              child: Icon(CupertinoIcons.share,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  size: 24),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _navigateToEditScreen(context, memorial),
              child: Icon(CupertinoIcons.pencil,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  size: 24),
            ),
          ],
        ),
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
      ),
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
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
                          if (allMemorials.length > 1) ...[
                            _buildMemorialSelector(
                              context,
                              memorial,
                              allMemorials,
                              isDark,
                              currentUserId,
                            ),
                            const SizedBox(height: 16),
                          ],
                          CupertinoButton.filled(
                            onPressed: () =>
                                _navigateToPageBuilder(context, memorial),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(CupertinoIcons.pencil, size: 20),
                                const SizedBox(width: 8),
                                Text(AppStrings.editMemorialPage),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          CupertinoButton.filled(
                            onPressed: () => _showPreview(context, memorial),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(CupertinoIcons.eye, size: 20),
                                const SizedBox(width: 8),
                                Text(AppStrings.viewPreview),
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

  Widget _buildMemorialSelector(
    BuildContext context,
    MemorialModel currentMemorial,
    List<MemorialModel> allMemorials,
    bool isDark,
    String? currentUserId,
  ) {
    final isIOS = Platform.isIOS;

    final ownedMemorials =
        allMemorials.where((m) => m.ownerId == currentUserId).toList();
    final sharedMemorials =
        allMemorials.where((m) => m.ownerId != currentUserId).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.greyLighter),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ownedMemorials.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              icon: isIOS ? CupertinoIcons.person_fill : Icons.person_rounded,
              title: 'Meine Gedenkseiten',
              count: ownedMemorials.length,
              color: isDark ? AppColors.accent : AppColors.primary,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            ...ownedMemorials.map((memorial) => _buildMemorialTile(
                  context,
                  memorial,
                  currentMemorial,
                  isDark,
                  isOwner: true,
                )),
          ],
          if (ownedMemorials.isNotEmpty && sharedMemorials.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                height: 1,
              ),
            ),
          ],
          if (sharedMemorials.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              icon: isIOS ? CupertinoIcons.person_2_fill : Icons.people_rounded,
              title: 'Eingeladen',
              count: sharedMemorials.length,
              color: AppColors.success,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            ...sharedMemorials.map((memorial) => _buildMemorialTile(
                  context,
                  memorial,
                  currentMemorial,
                  isDark,
                  isOwner: false,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkSecondary : AppColors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorialTile(
    BuildContext context,
    MemorialModel memorial,
    MemorialModel currentMemorial,
    bool isDark, {
    required bool isOwner,
  }) {
    final isIOS = Platform.isIOS;
    final isSelected = memorial.id == currentMemorial.id;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          context
              .read<MemorialBloc>()
              .add(MemorialSelected(memorial: memorial));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.accent.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.accent : AppColors.primary)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.1),
              ),
              child: ClipOval(
                child: memorial.profileImageUrl != null &&
                        memorial.profileImageUrl!.isNotEmpty
                    ? Image.network(memorial.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                            isIOS
                                ? CupertinoIcons.person_fill
                                : Icons.person_rounded,
                            size: 20,
                            color: AppColors.accent))
                    : Icon(
                        isIOS
                            ? CupertinoIcons.person_fill
                            : Icons.person_rounded,
                        size: 20,
                        color: AppColors.accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          memorial.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildOwnershipBadge(context, isOwner, isDark),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    memorial.lifespan,
                    style: TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                isIOS
                    ? CupertinoIcons.checkmark_circle_fill
                    : Icons.check_circle_rounded,
                color: isDark ? AppColors.accent : AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnershipBadge(BuildContext context, bool isOwner, bool isDark) {
    final isIOS = Platform.isIOS;

    if (isOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color:
              (isDark ? AppColors.accent : AppColors.primary).withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isIOS ? CupertinoIcons.star_fill : Icons.star_rounded,
              size: 10,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
            const SizedBox(width: 3),
            Text(
              'Eigene',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isIOS
                  ? CupertinoIcons.person_badge_plus_fill
                  : Icons.person_add_rounded,
              size: 10,
              color: AppColors.success,
            ),
            const SizedBox(width: 3),
            Text(
              'Eingeladen',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }
  }

  // ========================================
  // ✅ KOMPLETT NEU: QR Scanner mit neuem Flow
  // ========================================
  Future<void> _openQrScanner(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.user?.id;

    if (currentUserId == null) {
      _showErrorSnackBar(context, 'Bitte melde dich an.');
      return;
    }

    // Scanner öffnen
    final result = await Navigator.of(context).push<QrScanResult>(
      Platform.isIOS
          ? CupertinoPageRoute(builder: (context) => const QrScannerScreen())
          : MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (!mounted || result == null) return;

    // Ergebnis verarbeiten basierend auf Typ
    switch (result.type) {
      case QrScanResultType.unclaimed:
        // QR-Code ist frei → Claiming-Flow starten
        debugPrint('📱 QR-Code unclaimed: ${result.qrCodeId}');
        _handleUnclaimedQrCode(context, result.qrCodeId!, currentUserId);
        break;

      case QrScanResultType.active:
        // QR-Code ist bereits aktiviert → Memorial laden/anzeigen
        debugPrint('📱 QR-Code active, Memorial: ${result.memorialId}');
        _handleActiveQrCode(context, result.memorialId!, currentUserId);
        break;
    }
  }

  /// Handhabt unclaimed QR-Code → Claiming-Dialog anzeigen
  void _handleUnclaimedQrCode(
    BuildContext context,
    String qrCodeId,
    String currentUserId,
  ) {
    // QrClaimingHandler übernimmt den kompletten Flow
    // (Dialog anzeigen, Memorial erstellen, etc.)
    qrClaimingHandler.startClaimingFlow(
      context: context,
      qrCodeId: qrCodeId,
      userId: currentUserId,
    );
  }

  /// Handhabt active QR-Code → Prüfen ob User Zugang hat
  Future<void> _handleActiveQrCode(
    BuildContext context,
    String memorialId,
    String currentUserId,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Prüfen ob User bereits Zugang hat
    final memorialRepository = context.read<MemorialRepository>();
    final hasAccess = await memorialRepository.hasAccess(
      memorialId: memorialId,
      userId: currentUserId,
    );

    if (!mounted) return;

    if (hasAccess) {
      // User hat bereits Zugang → Memorial laden und anzeigen
      final memorial = await memorialRepository.getMemorialById(memorialId);

      if (memorial != null && mounted) {
        // Zum Memorial wechseln
        context.read<MemorialBloc>().add(MemorialSelected(memorial: memorial));
        _showSuccessSnackBar(context, 'Gedenkseite "${memorial.name}" geladen');
      }
    } else {
      // User hat keinen Zugang → Fragen ob Zugang gewährt werden soll
      _showAccessRequestDialog(context, memorialId, currentUserId);
    }
  }

  /// Dialog: Zugang zu fremdem Memorial anfragen
  void _showAccessRequestDialog(
    BuildContext context,
    String memorialId,
    String currentUserId,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Gedenkseite gefunden'),
          content: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Diese Gedenkseite gehört jemand anderem. '
              'Möchtest du Zugang anfragen?\n\n'
              '(In der aktuellen Version wird der Zugang direkt gewährt)',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _grantAccessAndReload(context, memorialId, currentUserId);
              },
              child: const Text('Zugang erhalten'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Gedenkseite gefunden'),
          content: const Text(
            'Diese Gedenkseite gehört jemand anderem. '
            'Möchtest du Zugang anfragen?\n\n'
            '(In der aktuellen Version wird der Zugang direkt gewährt)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _grantAccessAndReload(context, memorialId, currentUserId);
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? AppColors.accent : AppColors.primary,
              ),
              child: const Text('Zugang erhalten'),
            ),
          ],
        ),
      );
    }
  }

  /// Gewährt Zugang und lädt Memorials neu
  Future<void> _grantAccessAndReload(
    BuildContext context,
    String memorialId,
    String currentUserId,
  ) async {
    try {
      final memorialRepository = context.read<MemorialRepository>();

      // Zugang gewähren (als "Viewer" via QR-Code)
      await memorialRepository.addMemberAccess(
        memorialId: memorialId,
        userId: currentUserId,
        invitedById: currentUserId, // Self-invite via QR
      );

      if (!mounted) return;

      // Memorials neu laden
      context.read<MemorialBloc>().add(
            MemorialLoadRequested(userId: currentUserId),
          );

      // Memorial laden für Anzeige
      final memorial = await memorialRepository.getMemorialById(memorialId);

      if (memorial != null && mounted) {
        _showAccessGrantedDialog(context, memorial.name);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Zugang konnte nicht gewährt werden: $e');
      }
    }
  }

  void _showAccessGrantedDialog(BuildContext context, String memorialName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    HapticFeedback.heavyImpact();

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Zugang gewährt! 🎉'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child:
                Text('Du hast jetzt Zugang zur Gedenkseite "$memorialName".'),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle,
                  color: isDark ? AppColors.accent : AppColors.primary),
              const SizedBox(width: 8),
              const Text('Zugang gewährt!'),
            ],
          ),
          content:
              Text('Du hast jetzt Zugang zur Gedenkseite "$memorialName".'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.accent : AppColors.primary),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: isDark ? AppColors.primary : AppColors.background),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primary : AppColors.background)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, MemorialModel memorial, bool isDark) {
    final isIOS = Platform.isIOS;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [AppColors.backgroundDark, AppColors.backgroundDark]
              : [AppColors.primary.withOpacity(0.08), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.1),
            ),
            child: ClipOval(
              child: memorial.profileImageUrl != null &&
                      memorial.profileImageUrl!.isNotEmpty
                  ? Image.network(
                      memorial.profileImageUrl!,
                      fit: BoxFit.cover,
                      width: 160,
                      height: 160,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: isIOS
                              ? CupertinoActivityIndicator(
                                  color: isDark ? AppColors.grey : null)
                              : CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark
                                          ? AppColors.accent
                                          : AppColors.primary)),
                        );
                      },
                      errorBuilder: (_, __, ___) => Icon(
                          isIOS
                              ? CupertinoIcons.person_fill
                              : Icons.person_rounded,
                          size: 56,
                          color: AppColors.accent),
                    )
                  : Icon(
                      isIOS ? CupertinoIcons.person_fill : Icons.person_rounded,
                      size: 56,
                      color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            memorial.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              letterSpacing: -0.5,
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
                  width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    isIOS
                        ? CupertinoIcons.calendar
                        : Icons.calendar_today_rounded,
                    size: 16,
                    color: isDark ? AppColors.grey : AppColors.primary),
                const SizedBox(width: 8),
                Text(memorial.lifespan,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textPrimary)),
              ],
            ),
          ),
          if (memorial.biography != null && memorial.biography!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDarkElevated.withOpacity(0.5)
                    : AppColors.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark
                        ? AppColors.borderDarkSubtle.withOpacity(0.5)
                        : AppColors.greyLighter),
              ),
              child: Column(
                children: [
                  Icon(
                      isIOS
                          ? CupertinoIcons.quote_bubble
                          : Icons.format_quote_rounded,
                      size: 24,
                      color: isDark
                          ? AppColors.accent.withOpacity(0.6)
                          : AppColors.primary.withOpacity(0.4)),
                  const SizedBox(height: 8),
                  Text(
                    memorial.biography!,
                    style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsSection(
      BuildContext context, MemorialModel memorial, bool isDark) {
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
                      width: 1.5),
                ),
                child: Icon(
                    isIOS ? CupertinoIcons.settings : Icons.settings_rounded,
                    size: 18,
                    color: isDark ? AppColors.grey : AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(AppStrings.moreOptions,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textLight
                          : AppColors.textPrimary)),
            ],
          ),
        ),
        _buildActionTile(
          context,
          isIOS ? CupertinoIcons.trash : Icons.delete_outline_rounded,
          AppStrings.deleteMemorial,
          AppStrings.deleteMemorialPage,
          () => _showDeleteDialog(context, memorial),
          isDark: isDark,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap,
      {required bool isDark, bool isDestructive = false}) {
    final isIOS = Platform.isIOS;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDestructive
                    ? AppColors.error.withOpacity(0.3)
                    : (isDark ? AppColors.borderDark : AppColors.greyLighter)),
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
                ),
                child: Icon(icon,
                    size: 24,
                    color: isDestructive
                        ? AppColors.error
                        : (isDark ? AppColors.grey : AppColors.primary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isDestructive
                                ? AppColors.error
                                : (isDark
                                    ? AppColors.textLight
                                    : AppColors.textPrimary))),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(fontSize: 15, color: AppColors.grey)),
                  ],
                ),
              ),
              Icon(
                  isIOS
                      ? CupertinoIcons.chevron_right
                      : Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? AppColors.error : AppColors.greyDark),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPageBuilder(BuildContext context, MemorialModel memorial) {
    Navigator.of(context, rootNavigator: true)
        .pushNamed(AppRoutes.pageBuilder, arguments: memorial);
  }

  void _navigateToEditScreen(BuildContext context, MemorialModel memorial) {
    if (Platform.isIOS) {
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => MemorialEditScreen(memorial: memorial)));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MemorialEditScreen(memorial: memorial)));
    }
  }

  void _showPreview(BuildContext context, MemorialModel memorial) {
    showWebPreviewStandalone(context: context, memorial: memorial);
  }

  void _showShareSheet(BuildContext context, MemorialModel memorial) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.user?.id;

    if (currentUserId == null) {
      _showErrorSnackBar(context, 'Bitte melde dich an, um zu teilen.');
      return;
    }

    showMemorialShareSheet(
        context: context, memorial: memorial, currentUserId: currentUserId);
  }

  void _showDeleteDialog(BuildContext context, MemorialModel memorial) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.user?.id;

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
                if (currentUserId != null) {
                  context.read<MemorialBloc>().add(MemorialDeleteRequested(
                      memorialId: memorial.id,
                      requestingUserId: currentUserId));
                }
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(AppStrings.confirmDeleteTitle),
          content: Text(AppStrings.confirmDelete),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (currentUserId != null) {
                  context.read<MemorialBloc>().add(MemorialDeleteRequested(
                      memorialId: memorial.id,
                      requestingUserId: currentUserId));
                }
                Navigator.of(ctx).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(AppStrings.delete),
            ),
          ],
        ),
      );
    }
  }
}
