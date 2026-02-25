import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/data/services/qr_code_services/claiming_service.dart';
import 'package:rememberme/presentation/screens/memorial/memorial_screen.dart';
import 'package:rememberme/presentation/screens/preview/webview_preview_screen.dart';
import 'dart:io';

import '../../data/repositories/qr_code_repository.dart';
import '../../data/repositories/memorial_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/memorial_model.dart';
import '../../business_logic/memorial/memorial_bloc.dart';
import '../../business_logic/memorial/memorial_event.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import 'deep_link_handler.dart';

import '../../presentation/screens/memorial/memorial_private_screen.dart';

/// Handler für QR-Code Claiming Flow
class QrClaimingHandler {
  static final QrClaimingHandler _instance = QrClaimingHandler._internal();
  factory QrClaimingHandler() => _instance;
  QrClaimingHandler._internal();

  late ClaimingService _claimingService;
  late MemorialRepository _memorialRepository;
  late AuthRepository _authRepository;
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
    required AuthRepository authRepository,
    String? userId,
  }) {
    _context = context;
    _currentUserId = userId;
    _memorialRepository = memorialRepository;
    _authRepository = authRepository;
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

    debugPrint('QrClaimingHandler: Initialized');
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
    debugPrint('QrClaimingHandler: QR-Code empfangen: $qrCodeId');

    if (_isShowingDialog) {
      debugPrint('Dialog bereits sichtbar, ignoriere');
      return;
    }

    if (_currentUserId != null && _context != null) {
      debugPrint('User authenticated, starting claim flow');
      _startClaimingFlow(qrCodeId);
    } else if (_context != null) {
      debugPrint('User not authenticated, showing login required dialog');
      _showLoginRequiredDialog();
    }
  }

  /// Prüft auf pending QR-Code nach Login
  Future<void> _checkPendingQrCode() async {
    if (!_isInitialized || _currentUserId == null || _context == null) return;

    final qrCodeId = await deepLinkHandler.consumePendingQrCode();
    if (qrCodeId != null) {
      debugPrint('QrClaimingHandler: Pending QR-Code gefunden: $qrCodeId');

      await Future.delayed(const Duration(milliseconds: 500));

      if (_context != null && _currentUserId != null) {
        _startClaimingFlow(qrCodeId);
      }
    }
  }

  /// Dialog: Login erforderlich
  void _showLoginRequiredDialog() {
    if (_context == null || _isShowingDialog) return;

    _isShowingDialog = true;
    final isDark = Theme.of(_context!).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: _context!,
        barrierDismissible: false,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Anmeldung erforderlich'),
          content: const Text(
            'Bitte melde dich an oder erstelle einen Account, um die Gedenkseite einzurichten.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _isShowingDialog = false;
              },
            ),
            CupertinoDialogAction(
              child: const Text('Registrieren'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _isShowingDialog = false;
                Navigator.of(_context!).pushNamed(AppRoutes.register);
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Anmelden'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _isShowingDialog = false;
                Navigator.of(_context!).pushNamed(AppRoutes.login);
              },
            ),
          ],
        ),
      ).then((_) => _isShowingDialog = false);
    } else {
      showDialog(
        context: _context!,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Anmeldung erforderlich',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Bitte melde dich an oder erstelle einen Account, um die Gedenkseite einzurichten.',
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : AppColors.grey,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _isShowingDialog = false;
              },
              child: Text(
                'Abbrechen',
                style: TextStyle(color: AppColors.grey),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _isShowingDialog = false;
                Navigator.of(_context!).pushNamed(AppRoutes.register);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? AppColors.accent : AppColors.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Registrieren',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accent : AppColors.primary,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _isShowingDialog = false;
                Navigator.of(_context!).pushNamed(AppRoutes.login);
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Anmelden',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primary : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ).then((_) => _isShowingDialog = false);
    }
  }

  /// Startet den Claiming-Flow
  Future<void> _startClaimingFlow(String qrCodeId) async {
    if (_context == null || !_isInitialized || _isShowingDialog) return;

    debugPrint('Starte Claiming-Flow für: $qrCodeId');

    _isShowingDialog = true;

    final checkResult = await _claimingService.checkQrCode(qrCodeId);

    _isShowingDialog = false;

    if (!checkResult.exists) {
      _showErrorDialog('QR-Code nicht gefunden. Bitte überprüfe den Code.');
      return;
    }

    if (!checkResult.canBeClaimed) {
      if (checkResult.memorialId != null) {
        await _handleExistingMemorial(checkResult.memorialId!);
      } else {
        _showErrorDialog(checkResult.message);
      }
      return;
    }

    _navigateToCreateScreen(qrCodeId);
  }

  /// Prüft Access-Rechte und navigiert zum richtigen Screen
  Future<void> _handleExistingMemorial(String memorialId) async {
    if (_context == null || _currentUserId == null) return;

    debugPrint('Prüfe Access für Memorial: $memorialId');

    _showLoadingDialog();

    try {
      final access = await _memorialRepository.checkViewAccess(
        memorialId: memorialId,
        userId: _currentUserId!,
      );

      if (_context != null && Navigator.of(_context!).canPop()) {
        Navigator.of(_context!).pop();
      }

      if (!_context!.mounted) return;

      switch (access.type) {
        case MemorialViewAccessType.fullAccess:
          debugPrint('Full Access -> MemorialDetailScreen');
          _navigateToDetailScreen(access.memorial!);
          break;

        case MemorialViewAccessType.publicReadOnly:
          debugPrint('Public Read-Only -> WebViewPreviewScreen');
          _navigateToPreviewScreen(access.memorial!);
          break;

        case MemorialViewAccessType.privateNoAccess:
          debugPrint('Private No Access -> MemorialPrivateScreen');
          _navigateToPrivateScreen(access.memorial!);
          break;

        case MemorialViewAccessType.notFound:
          _showErrorDialog('Gedenkseite nicht gefunden.');
          break;
      }
    } catch (e) {
      if (_context != null && Navigator.of(_context!).canPop()) {
        Navigator.of(_context!).pop();
      }
      debugPrint('Fehler bei Access-Check: $e');
      _showErrorDialog('Fehler beim Laden der Gedenkseite.');
    }
  }

  /// Zeigt Loading Dialog
  void _showLoadingDialog() {
    if (_context == null) return;

    final isDark = Theme.of(_context!).brightness == Brightness.dark;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDarkElevated : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Platform.isIOS
                    ? CupertinoActivityIndicator(
                        radius: 16,
                        color: isDark ? AppColors.accent : null,
                      )
                    : CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                const SizedBox(height: 16),
                Text(
                  'Gedenkseite wird geladen...',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Navigiert zum Detail Screen (für Owner/Members)
  void _navigateToDetailScreen(MemorialModel memorial) {
    if (_context == null) return;

    if (Platform.isIOS) {
      Navigator.push(
        _context!,
        CupertinoPageRoute(
          builder: (context) => MemorialDetailScreen(memorial: memorial),
        ),
      );
    } else {
      Navigator.push(
        _context!,
        MaterialPageRoute(
          builder: (context) => MemorialDetailScreen(memorial: memorial),
        ),
      );
    }
  }

  /// Navigiert zum Preview Screen (für öffentliche Memorials)
  void _navigateToPreviewScreen(MemorialModel memorial) {
    if (_context == null) return;

    final previewUrl = 'https://${DeepLinkHandler.webDomain}/m/${memorial.id}';

    if (Platform.isIOS) {
      Navigator.push(
        _context!,
        CupertinoPageRoute(
          builder: (context) => WebViewPreviewScreen(
            previewUrl: previewUrl,
            memorialName: memorial.name,
          ),
        ),
      );
    } else {
      Navigator.push(
        _context!,
        MaterialPageRoute(
          builder: (context) => WebViewPreviewScreen(
            previewUrl: previewUrl,
            memorialName: memorial.name,
          ),
        ),
      );
    }
  }

  /// Navigiert zum Private Screen (für private Memorials ohne Zugang)
  void _navigateToPrivateScreen(MemorialModel memorial) {
    if (_context == null) return;

    if (Platform.isIOS) {
      Navigator.push(
        _context!,
        CupertinoPageRoute(
          builder: (context) => MemorialPrivateScreen(memorial: memorial),
        ),
      );
    } else {
      Navigator.push(
        _context!,
        MaterialPageRoute(
          builder: (context) => MemorialPrivateScreen(memorial: memorial),
        ),
      );
    }
  }

  /// Navigiert zur MemorialCreateScreen mit QR-Code ID
  void _navigateToCreateScreen(String qrCodeId) {
    if (_context == null) return;

    debugPrint('Navigiere zu MemorialCreateScreen mit QR-Code: $qrCodeId');

    Navigator.of(_context!).pushNamed(
      AppRoutes.memorialCreate,
      arguments: {'qrCodeId': qrCodeId},
    );
  }

  void _showErrorDialog(String message) {
    if (_context == null) return;

    final isDark = Theme.of(_context!).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: _context!,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Fehler'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: _context!,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
  }

  void startClaimingFlow({
    required BuildContext context,
    required String qrCodeId,
    required String userId,
  }) {
    _context = context;
    _currentUserId = userId;
    debugPrint('QrClaimingHandler: Manueller Start für QR: $qrCodeId');
    _startClaimingFlow(qrCodeId);
  }
}

final qrClaimingHandler = QrClaimingHandler();
