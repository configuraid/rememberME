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

  /// ❌ Dialog: Login erforderlich - NUR Dialog, KEINE Navigation!
  void _showLoginRequiredDialog() {
    if (_context == null || _isShowingDialog) return;

    _isShowingDialog = true;
    final isDark = Theme.of(_context!).brightness == Brightness.dark;
    final isIOS = Platform.isIOS;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIOS
                    ? CupertinoIcons.exclamationmark_triangle_fill
                    : Icons.warning_amber_rounded,
                size: 48,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Anmeldung erforderlich',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
        content: Text(
          'Um diesen QR-Code zu aktivieren und eine Gedenkseite zu erstellen, musst du dich zuerst mit deinem Account anmelden.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white70 : Colors.black54,
            height: 1.4,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _isShowingDialog = false;
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Verstanden'),
            ),
          ),
        ],
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
