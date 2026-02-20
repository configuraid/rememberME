import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_routes.dart';
import 'package:rememberme/data/repositories/qr_code_repository.dart';
import 'package:rememberme/data/models/qr_code_model.dart';
import 'package:rememberme/business_logic/auth/auth_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_state.dart';
import 'dart:io';

/// QR Scanner Screen - Angepasst für neuen Claiming-Flow
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _scannerController;

  bool _isProcessing = false;
  bool _hasScanned = false;
  String? _statusMessage;
  bool _showSuccess = false;
  QrScanResultType? _resultType;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _initScanner();
  }

  /// Scanner sicher initialisieren
  void _initScanner() {
    if (_scannerController != null) return;

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    // FIX: Erst stoppen, dann disposen, dann null setzen
    _scannerController?.stop().catchError((_) {});
    _scannerController?.dispose();
    _scannerController = null;
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _hasScanned = true;
      _statusMessage = 'QR-Code wird überprüft...';
    });

    HapticFeedback.mediumImpact();

    // QR-Code ID extrahieren
    final qrCodeId = _extractQrCodeId(rawValue);

    if (qrCodeId == null) {
      _showError('Ungültiger QR-Code. Bitte scanne einen RememberMe QR-Code.');
      _resetScanner();
      return;
    }

    setState(() {
      _statusMessage = 'Status wird geprüft...';
    });

    // QR-Code Status prüfen
    final qrCodeRepository = context.read<QrCodeRepository>();
    final checkResult = await qrCodeRepository.checkQrCodeStatus(qrCodeId);

    if (!mounted) return;

    if (!checkResult.exists) {
      _showError('QR-Code nicht gefunden. Bitte überprüfe den Code.');
      _resetScanner();
      return;
    }

    // Entscheiden was zu tun ist basierend auf Status
    if (checkResult.canBeClaimed) {
      // QR-Code ist UNCLAIMED → Claiming-Flow starten
      _handleUnclaimedQrCode(qrCodeId);
    } else if (checkResult.memorialId != null) {
      // QR-Code ist ACTIVE → Zum Memorial navigieren
      _handleActiveQrCode(qrCodeId, checkResult.memorialId!);
    } else {
      // Claiming läuft bereits
      _showError(checkResult.message);
      _resetScanner();
    }
  }

  /// Extrahiert die QR-Code ID aus verschiedenen Formaten
  String? _extractQrCodeId(String rawValue) {
    // Format 1: Volle URL - https://domain.com/m/{qrCodeId}
    final uri = Uri.tryParse(rawValue);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final mIndex = uri.pathSegments.indexOf('m');
      if (mIndex >= 0 && mIndex < uri.pathSegments.length - 1) {
        return uri.pathSegments[mIndex + 1];
      }
    }

    // Format 2: Kurze ID (alphanumerisch, typischerweise 6-20 Zeichen)
    if (RegExp(r'^[a-zA-Z0-9]{3,30}$').hasMatch(rawValue)) {
      return rawValue;
    }

    return null;
  }

  /// Handhabt unclaimed QR-Code → Claiming starten
  void _handleUnclaimedQrCode(String qrCodeId) {
    setState(() {
      _showSuccess = true;
      _statusMessage = 'QR-Code verfügbar!';
      _resultType = QrScanResultType.unclaimed;
    });

    _scanLineController.stop();
    HapticFeedback.heavyImpact();

    // Kurz warten, dann Result zurückgeben
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.of(context).pop(QrScanResult(
        type: QrScanResultType.unclaimed,
        qrCodeId: qrCodeId,
      ));
    });
  }

  /// Handhabt active QR-Code → Zum Memorial navigieren
  void _handleActiveQrCode(String qrCodeId, String memorialId) {
    setState(() {
      _showSuccess = true;
      _statusMessage = 'Gedenkseite gefunden!';
      _resultType = QrScanResultType.active;
    });

    _scanLineController.stop();
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.of(context).pop(QrScanResult(
        type: QrScanResultType.active,
        qrCodeId: qrCodeId,
        memorialId: memorialId,
      ));
    });
  }

  void _resetScanner() {
    setState(() {
      _isProcessing = false;
      _hasScanned = false;
      _statusMessage = null;
      _showSuccess = false;
      _resultType = null;
    });
    _scanLineController.repeat();
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Fehler'),
          content: Text(message),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _toggleFlash() async {
    await _scannerController?.toggleTorch();
    HapticFeedback.lightImpact();
  }

  /// Baut den Scanner-Widget mit Error-Handling
  Widget _buildScannerWidget() {
    if (_scannerController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return MobileScanner(
      controller: _scannerController!,
      onDetect: _onDetect,
      errorBuilder: (context, error) {
        debugPrint('📷 Scanner Error: ${error.errorCode}');
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Platform.isIOS
                    ? CupertinoIcons.camera
                    : Icons.camera_alt_rounded,
                size: 48,
                color: AppColors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Kamera wird geladen...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSView();
    }
    return _buildAndroidView();
  }

  Widget _buildAndroidView() {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'QR-Code scannen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_scannerController != null)
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _scannerController!,
              builder: (context, state, child) {
                final isOn = state.torchState == TorchState.on;
                return IconButton(
                  icon: Icon(
                    isOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: isOn ? AppColors.accent : Colors.white,
                  ),
                  onPressed: _toggleFlash,
                );
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildIOSView() {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'QR-Code scannen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back, color: Colors.white),
        ),
        trailing: _scannerController != null
            ? ValueListenableBuilder<MobileScannerState>(
                valueListenable: _scannerController!,
                builder: (context, state, child) {
                  final isOn = state.torchState == TorchState.on;
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _toggleFlash,
                    child: Icon(
                      isOn ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt,
                      color: isOn ? AppColors.accent : Colors.white,
                    ),
                  );
                },
              )
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final size = MediaQuery.of(context).size;
    final scanSize = size.width * 0.7;
    final scanTop = size.height * 0.3;
    final scanLeft = (size.width - scanSize) / 2;

    return Stack(
      children: [
        // Camera
        _buildScannerWidget(),

        // Overlay
        CustomPaint(
          painter: _OverlayPainter(
            scanRect: Rect.fromLTWH(scanLeft, scanTop, scanSize, scanSize),
            borderColor: _showSuccess ? AppColors.success : AppColors.accent,
          ),
          child: const SizedBox.expand(),
        ),

        // Scan line
        if (!_showSuccess)
          AnimatedBuilder(
            animation: _scanLineAnimation,
            builder: (context, child) {
              final lineY = scanTop + (scanSize * _scanLineAnimation.value);
              return Positioned(
                top: lineY,
                left: scanLeft + 10,
                right: size.width - scanLeft - scanSize + 10,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.accent,
                        AppColors.accent,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        // Success icon
        if (_showSuccess)
          Positioned(
            top: scanTop + (scanSize - 80) / 2,
            left: (size.width - 80) / 2,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Platform.isIOS ? CupertinoIcons.checkmark_alt : Icons.check,
                color: Colors.white,
                size: 45,
              ),
            ),
          ),

        // Status
        if (_statusMessage != null)
          Positioned(
            top: scanTop + scanSize + 30,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _showSuccess ? AppColors.success : Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_showSuccess)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      _statusMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Instructions
        Positioned(
          bottom: 50,
          left: 24,
          right: 24,
          child: Text(
            'RememberMe QR-Code im Rahmen platzieren',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// Overlay Painter
class _OverlayPainter extends CustomPainter {
  final Rect scanRect;
  final Color borderColor;

  _OverlayPainter({required this.scanRect, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
        overlayPath, Paint()..color = Colors.black.withOpacity(0.7));

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    _drawCorners(canvas, scanRect, borderColor);
  }

  void _drawCorners(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const len = 25.0;
    const r = 16.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + len)
        ..lineTo(rect.left, rect.top + r)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + r, rect.top)
        ..lineTo(rect.left + len, rect.top),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - len, rect.top)
        ..lineTo(rect.right - r, rect.top)
        ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + r)
        ..lineTo(rect.right, rect.top + len),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - len)
        ..lineTo(rect.left, rect.bottom - r)
        ..quadraticBezierTo(rect.left, rect.bottom, rect.left + r, rect.bottom)
        ..lineTo(rect.left + len, rect.bottom),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - len, rect.bottom)
        ..lineTo(rect.right - r, rect.bottom)
        ..quadraticBezierTo(
            rect.right, rect.bottom, rect.right, rect.bottom - r)
        ..lineTo(rect.right, rect.bottom - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) =>
      old.borderColor != borderColor;
}

/// Ergebnis-Typ des QR-Scans
enum QrScanResultType {
  unclaimed, // QR-Code kann geclaimed werden
  active, // QR-Code ist bereits aktiviert, Memorial existiert
}

/// Scan-Ergebnis
class QrScanResult {
  final QrScanResultType type;
  final String? qrCodeId;
  final String? memorialId; // Nur bei type == active

  QrScanResult({
    required this.type,
    this.qrCodeId,
    this.memorialId,
  });
}
