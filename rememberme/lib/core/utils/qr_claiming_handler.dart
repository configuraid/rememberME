import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/data/services/qr_code_services/claiming_service.dart';
import 'dart:io';

import '../../data/repositories/qr_code_repository.dart';
import '../../data/repositories/memorial_repository.dart';
import '../../business_logic/memorial/memorial_bloc.dart';
import '../../business_logic/memorial/memorial_event.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import 'deep_link_handler.dart';

/// Handler für QR-Code Claiming Flow
class QrClaimingHandler {
  static final QrClaimingHandler _instance = QrClaimingHandler._internal();
  factory QrClaimingHandler() => _instance;
  QrClaimingHandler._internal();

  late ClaimingService _claimingService;
  BuildContext? _context;
  String? _currentUserId;
  bool _isInitialized = false;

  // Verhindert doppelte Dialoge
  bool _isShowingDialog = false;

  /// Initialize with repositories
  void initialize({
    required BuildContext context,
    required QrCodeRepository qrCodeRepository,
    required MemorialRepository memorialRepository,
    String? userId,
  }) {
    _context = context;
    _currentUserId = userId;
    _claimingService = ClaimingService(
      qrCodeRepository: qrCodeRepository,
      memorialRepository: memorialRepository,
    );
    _isInitialized = true;

    // Callback für eingehende QR-Code Links
    deepLinkHandler.onQrCodeReceived = _onQrCodeReceived;

    // Prüfe auf pending QR-Code nach Login
    if (userId != null) {
      _checkPendingQrCode();
    }

    debugPrint('✅ QrClaimingHandler: Initialized');
  }

  /// Update context (wichtig für Dialoge!)
  void updateContext(BuildContext context) {
    _context = context;
  }

  /// Update user ID (bei Auth-Änderungen)
  void updateUserId(String? userId) {
    final wasLoggedOut = _currentUserId == null;
    _currentUserId = userId;

    // Wenn User sich gerade eingeloggt hat, prüfe auf pending QR-Code
    if (userId != null && wasLoggedOut) {
      _checkPendingQrCode();
    }
  }

  /// Callback wenn QR-Code Deep Link empfangen wird
  void _onQrCodeReceived(String qrCodeId) {
    debugPrint('📱 QrClaimingHandler: QR-Code empfangen: $qrCodeId');

    // Verhindere doppelte Dialoge
    if (_isShowingDialog) {
      debugPrint('⚠️ Dialog bereits sichtbar, ignoriere');
      return;
    }

    if (_currentUserId != null && _context != null) {
      // ✅ User eingeloggt → Zum Claiming-Flow
      debugPrint('✅ User authenticated, starting claim flow');
      _startClaimingFlow(qrCodeId);
    } else if (_context != null) {
      // ❌ User NICHT eingeloggt → Fehler-Dialog anzeigen
      debugPrint('❌ User not authenticated, showing login required dialog');
      _showLoginRequiredDialog();
    }
  }

  /// Prüft auf pending QR-Code nach Login
  Future<void> _checkPendingQrCode() async {
    if (!_isInitialized || _currentUserId == null || _context == null) return;

    final qrCodeId = await deepLinkHandler.consumePendingQrCode();
    if (qrCodeId != null) {
      debugPrint('📱 QrClaimingHandler: Pending QR-Code gefunden: $qrCodeId');

      // Kurz warten bis UI fertig ist
      await Future.delayed(const Duration(milliseconds: 500));

      if (_context != null && _currentUserId != null) {
        _startClaimingFlow(qrCodeId);
      }
    }
  }

  /// ❌ Dialog: Login erforderlich - Mit Anmelden/Registrieren Buttons
  void _showLoginRequiredDialog() {
    if (_context == null || _isShowingDialog) return;

    _isShowingDialog = true;
    final isDark = Theme.of(_context!).brightness == Brightness.dark;
    final isIOS = Platform.isIOS;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon mit Gradient-Hintergrund
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.accent.withOpacity(0.2),
                          AppColors.accent.withOpacity(0.05)
                        ]
                      : [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.05)
                        ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIOS
                    ? CupertinoIcons.qrcode_viewfinder
                    : Icons.qr_code_scanner_rounded,
                size: 48,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Titel
            Text(
              'QR-Code erkannt! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Beschreibung
            Text(
              'Du bist nur noch einen Schritt davon entfernt, '
              'eine persönliche Gedenkseite für einen Geliebten zu erstellen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppColors.textDarkSecondary : AppColors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),

            // Hinweis
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.accent.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isIOS
                        ? CupertinoIcons.checkmark_shield_fill
                        : Icons.verified_user_rounded,
                    size: 18,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Melde dich an, um fortzufahren',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.accent : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Anmelden Button (Primary)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _isShowingDialog = false;
                  // Zur Login-Seite navigieren
                  Navigator.of(_context!).pushNamed(AppRoutes.login);
                },
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.accent : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Anmelden',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primary : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Registrieren Button (Secondary)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _isShowingDialog = false;
                  // Zur Registrierungs-Seite navigieren
                  Navigator.of(_context!).pushNamed(AppRoutes.register);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? AppColors.accent : AppColors.primary,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Neuen Account erstellen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Abbrechen Link
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _isShowingDialog = false;
              },
              child: Text(
                'Später',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      _isShowingDialog = false;
    });
  }

  /// Startet den Claiming-Flow
  Future<void> _startClaimingFlow(String qrCodeId) async {
    if (_context == null || !_isInitialized || _isShowingDialog) return;

    debugPrint('🎯 Starte Claiming-Flow für: $qrCodeId');

    _isShowingDialog = true;

    // Erst QR-Code Status prüfen
    final checkResult = await _claimingService.checkQrCode(qrCodeId);

    _isShowingDialog = false;

    if (!checkResult.exists) {
      _showErrorDialog('QR-Code nicht gefunden. Bitte überprüfe den Code.');
      return;
    }

    if (!checkResult.canBeClaimed) {
      if (checkResult.memorialId != null) {
        _showAlreadyClaimedDialog(checkResult.memorialId!);
      } else {
        _showErrorDialog(checkResult.message);
      }
      return;
    }

    // ✅ QR-Code kann geclaimed werden → Zur MemorialCreateScreen navigieren!
    _navigateToCreateScreen(qrCodeId);
  }

  /// Navigiert zur MemorialCreateScreen mit QR-Code ID
  void _navigateToCreateScreen(String qrCodeId) {
    if (_context == null) return;

    debugPrint('🚀 Navigiere zu MemorialCreateScreen mit QR-Code: $qrCodeId');

    Navigator.of(_context!).pushNamed(
      AppRoutes.memorialCreate,
      arguments: {'qrCodeId': qrCodeId},
    );
  }

  void _showErrorDialog(String message) {
    if (_context == null) return;

    showDialog(
      context: _context!,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Fehler'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAlreadyClaimedDialog(String memorialId) {
    if (_context == null) return;

    final isDark = Theme.of(_context!).brightness == Brightness.dark;

    showDialog(
      context: _context!,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bereits aktiviert'),
        content: const Text(
          'Dieser QR-Code wurde bereits aktiviert.\n\n'
          'Möchtest du zur Gedenkseite navigieren?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Zum Memorial navigieren
            },
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? AppColors.accent : AppColors.primary,
            ),
            child: const Text('Zur Gedenkseite'),
          ),
        ],
      ),
    );
  }

  void startClaimingFlow({
    required BuildContext context,
    required String qrCodeId,
    required String userId,
  }) {
    _context = context;
    _currentUserId = userId;
    debugPrint('🎯 QrClaimingHandler: Manueller Start für QR: $qrCodeId');
    _startClaimingFlow(qrCodeId);
  }
}

final qrClaimingHandler = QrClaimingHandler();
