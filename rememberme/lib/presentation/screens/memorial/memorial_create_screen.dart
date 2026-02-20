import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rememberme/data/repositories/memorial_repository.dart';
import 'package:rememberme/presentation/screens/memorial/memorial_private_screen.dart';
import 'package:rememberme/presentation/screens/memorial/memorial_screen.dart';
import 'package:rememberme/presentation/screens/preview/webview_preview_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/memorial/memorial_bloc.dart';
import '../../../business_logic/memorial/memorial_event.dart';
import '../../../business_logic/memorial/memorial_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/qr_claiming_handler.dart';
import '../../../data/repositories/qr_code_repository.dart';

/// Shop URL für QR-Code Kauf
const String _shopUrl = 'https://www.google.com/?hl=de';

class MemorialCreateScreen extends StatefulWidget {
  const MemorialCreateScreen({super.key});

  @override
  State<MemorialCreateScreen> createState() => _MemorialCreateScreenState();
}

class _MemorialCreateScreenState extends State<MemorialCreateScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  File? _profileImage;

  // QR-Code State
  String? _qrCodeId;
  bool _isValidatingQrCode = false;
  bool _hasScannedOnce = false;
  String? _lastScannedQrCode;
  DateTime? _lastScanTime;
  static const Duration _scanCooldown = Duration(seconds: 3);

  // Scanner Controller
  MobileScannerController? _scannerController;
  bool _isScannerDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Prüfe ob QR-Code ID via Deep Link übergeben wurde
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('qrCodeId')) {
        final qrCodeId = args['qrCodeId'] as String?;
        if (qrCodeId != null && qrCodeId.isNotEmpty) {
          setState(() {
            _qrCodeId = qrCodeId;
          });
          debugPrint(
              '📱 MemorialCreateScreen: QR-Code via Deep Link: $_qrCodeId');
        }
      }
    });

    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _disposeScanner();
    super.dispose();
  }

  /// App-Lifecycle beobachten
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_scannerController == null || _qrCodeId != null) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _safeStopScanner();
        break;
      case AppLifecycleState.resumed:
        if (!_hasScannedOnce && !_isValidatingQrCode) {
          _safeStartScanner();
        }
        break;
      default:
        break;
    }
  }

  // ============================================================
  // Scanner Lifecycle Management
  // ============================================================

  void _initScanner() {
    if (_scannerController != null || _isScannerDisposed) return;

    debugPrint('📷 Scanner wird initialisiert...');
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  void _disposeScanner() {
    if (_scannerController == null) return;

    debugPrint('📷 Scanner wird disposed...');
    _isScannerDisposed = true;

    try {
      _scannerController?.stop().catchError((e) {
        debugPrint('ℹ️ Scanner stop bei dispose: $e');
      });
    } catch (e) {
      debugPrint('ℹ️ Scanner stop error: $e');
    }

    try {
      _scannerController?.dispose();
    } catch (e) {
      debugPrint('ℹ️ Scanner dispose error: $e');
    }

    _scannerController = null;
  }

  Future<void> _safeStartScanner() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || _scannerController == null) return;
      await _scannerController?.start();
      debugPrint('✅ Scanner gestartet');
    } catch (e) {
      debugPrint('ℹ️ Scanner Start Info: $e');
    }
  }

  Future<void> _safeStopScanner() async {
    try {
      if (_scannerController == null) return;
      await _scannerController?.stop();
      debugPrint('✅ Scanner gestoppt');
    } catch (e) {
      debugPrint('ℹ️ Scanner Stop Info: $e');
    }
  }

  bool _isRecentlyScanned(String qrCodeId) {
    if (_lastScannedQrCode == qrCodeId && _lastScanTime != null) {
      final elapsed = DateTime.now().difference(_lastScanTime!);
      if (elapsed < _scanCooldown) {
        debugPrint(
            '⏳ QR-Code kürzlich gescannt, ignoriere für ${_scanCooldown.inSeconds - elapsed.inSeconds}s');
        return true;
      }
    }
    return false;
  }

  Widget _buildScannerWidget() {
    if (_scannerController == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Platform.isIOS ? CupertinoIcons.camera : Icons.camera_alt_rounded,
              size: 48,
              color: AppColors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Kamera wird geladen...',
              style: TextStyle(color: AppColors.grey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return MobileScanner(
      controller: _scannerController!,
      onDetect: _onQrCodeDetected,
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
                style: TextStyle(color: AppColors.grey, fontSize: 15),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // QR-Code Detection & Validation
  // ============================================================

  Future<void> _onQrCodeDetected(BarcodeCapture capture) async {
    if (_hasScannedOnce || _isValidatingQrCode) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final scannedValue = barcode.rawValue!;
    final qrCodeId = _extractQrCodeId(scannedValue);

    if (qrCodeId == null) {
      debugPrint('⚠️ Ungültiger QR-Code Format: $scannedValue');
      return;
    }

    if (_isRecentlyScanned(qrCodeId)) return;

    debugPrint('📱 QR-Code gescannt: $scannedValue');

    setState(() {
      _hasScannedOnce = true;
      _isValidatingQrCode = true;
      _lastScannedQrCode = qrCodeId;
      _lastScanTime = DateTime.now();
    });

    await _safeStopScanner();
    await _validateAndSetQrCode(qrCodeId);
  }

  String? _extractQrCodeId(String value) {
    if (value.contains('/memorial/')) {
      final uri = Uri.tryParse(value);
      if (uri != null && uri.pathSegments.contains('memorial')) {
        final index = uri.pathSegments.indexOf('memorial');
        if (index < uri.pathSegments.length - 1) {
          return uri.pathSegments[index + 1];
        }
      }
    }

    if (value.contains('/m/')) {
      final uri = Uri.tryParse(value);
      if (uri != null && uri.pathSegments.contains('m')) {
        final index = uri.pathSegments.indexOf('m');
        if (index < uri.pathSegments.length - 1) {
          return uri.pathSegments[index + 1];
        }
      }
    }

    if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value) && value.length >= 8) {
      return value;
    }

    return null;
  }

  Future<void> _validateAndSetQrCode(String qrCodeId) async {
    debugPrint('🔍 Validiere und Claime QR-Code: $qrCodeId');

    try {
      final qrCodeRepository = context.read<QrCodeRepository>();
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id;

      if (userId == null) {
        debugPrint('❌ User nicht eingeloggt!');
        _showError('Du musst eingeloggt sein um einen QR-Code zu aktivieren.');
        setState(() {
          _hasScannedOnce = false;
          _isValidatingQrCode = false;
        });
        await _safeStartScanner();
        return;
      }

      final result = await qrCodeRepository.claimQrCode(
        qrId: qrCodeId,
        userId: userId,
      );

      debugPrint('   - success: ${result.success}');
      debugPrint('   - errorType: ${result.errorType}');
      debugPrint('   - errorMessage: ${result.errorMessage}');

      if (!result.success) {
        switch (result.errorType) {
          case ClaimErrorType.notFound:
            _showError('QR-Code nicht gefunden. Bitte prüfe den Code.');
            break;
          case ClaimErrorType.alreadyClaimed:
            final memorialId = result.qrCode?.memorialId;
            if (memorialId != null && memorialId.isNotEmpty) {
              await _handleExistingMemorial(memorialId);
              return;
            } else {
              _showError('Dieser QR-Code ist bereits aktiviert.');
            }
            break;
          case ClaimErrorType.claimingInProgress:
            _showError(
                'Dieser QR-Code wird gerade von jemand anderem aktiviert. Bitte versuche es später erneut.');
            break;
          default:
            _showError(result.errorMessage ?? 'Fehler bei der Aktivierung.');
        }

        setState(() {
          _hasScannedOnce = false;
          _isValidatingQrCode = false;
        });
        await _safeStartScanner();
        return;
      }

      debugPrint('✅ QR-Code geclaimed: $qrCodeId für User $userId');

      setState(() {
        _qrCodeId = qrCodeId;
        _isValidatingQrCode = false;
      });
    } catch (e) {
      debugPrint('❌ Fehler bei QR-Code Claiming: $e');
      _showError('Fehler bei der Aktivierung. Bitte erneut versuchen.');
      setState(() {
        _hasScannedOnce = false;
        _isValidatingQrCode = false;
      });
      await _safeStartScanner();
    }
  }

  Future<void> _openShop() async {
    final uri = Uri.parse(_shopUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('Shop konnte nicht geöffnet werden.');
    }
  }

  // ============================================================
  // Image Picker
  // ============================================================

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError('Fehler beim Auswählen des Bildes: $e');
    }
  }

  void _showImageSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(
            'Foto auswählen',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.camera,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Kamera',
                    style: TextStyle(
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.photo,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Galerie',
                    style: TextStyle(
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.cancel,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor:
            isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Foto auswählen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.accent.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                  title: Text(
                    'Kamera',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Neues Foto aufnehmen',
                    style: TextStyle(color: AppColors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.accent.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                  title: Text(
                    'Galerie',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Aus Fotos auswählen',
                    style: TextStyle(color: AppColors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _profileImage = null;
    });
  }

  // ============================================================
  // Memorial erstellen — nur Name + Foto
  // ============================================================

  void _createMemorial() {
    debugPrint('🔘 _createMemorial() aufgerufen');
    debugPrint('   - _qrCodeId: $_qrCodeId');
    debugPrint('   - Form valid: ${_formKey.currentState?.validate()}');
    debugPrint('   - Profile image: ${_profileImage != null}');

    if (_formKey.currentState?.validate() ?? false) {
      final authState = context.read<AuthBloc>().state;
      final user = authState.user;

      if (user == null) {
        debugPrint('❌ User ist null!');
        _showError(AppStrings.userNotFound);
        return;
      }

      if (_profileImage == null) {
        debugPrint('❌ Kein Profilbild!');
        _showError('Bitte wähle ein Foto aus');
        return;
      }

      if (_qrCodeId == null) {
        debugPrint('❌ Keine QR-Code ID!');
        _showError('Kein QR-Code verknüpft');
        return;
      }

      debugPrint('✅ Alle Validierungen bestanden, erstelle Memorial...');
      debugPrint('   - ownerId: ${user.id}');
      debugPrint('   - name: ${_nameController.text.trim()}');
      debugPrint('   - qrCodeId: $_qrCodeId');

      context.read<MemorialBloc>().add(
            MemorialCreateRequested(
              ownerId: user.id,
              name: _nameController.text.trim(),
              templateId: 'classic',
              profileImage: _profileImage!,
              biography: null,
              birthDate: null,
              deathDate: null,
              isPublic: false, // Default: Privat
              qrCodeId: _qrCodeId,
            ),
          );
    } else {
      debugPrint('❌ Formular-Validierung fehlgeschlagen');
    }
  }

  bool _isFormValid() {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasProfileImage = _profileImage != null;
    return hasName && hasProfileImage;
  }

  void _showError(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
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

  // ============================================================
  // Existing Memorial Navigation
  // ============================================================

  Future<void> _handleExistingMemorial(String memorialId) async {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id;

    if (userId == null) {
      _showError('Bitte melde dich an.');
      await _resetScannerAfterNavigation();
      return;
    }

    _showLoadingDialog();

    try {
      final memorialRepository = context.read<MemorialRepository>();
      final access = await memorialRepository.checkViewAccess(
        memorialId: memorialId,
        userId: userId,
      );

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      switch (access.type) {
        case MemorialViewAccessType.fullAccess:
          debugPrint('✅ Full Access → MemorialDetailScreen');
          await Navigator.of(context).push(
            Platform.isIOS
                ? CupertinoPageRoute(
                    builder: (_) =>
                        MemorialDetailScreen(memorial: access.memorial!))
                : MaterialPageRoute(
                    builder: (_) =>
                        MemorialDetailScreen(memorial: access.memorial!)),
          );
          await _resetScannerAfterNavigation();
          break;

        case MemorialViewAccessType.publicReadOnly:
          debugPrint('👁️ Public Read-Only → WebViewPreviewScreen');
          final previewUrl =
              'https://remember-me-slug.vercel.app/preview/${access.memorial!.id}';
          await Navigator.of(context).push(
            Platform.isIOS
                ? CupertinoPageRoute(
                    builder: (_) => WebViewPreviewScreen(
                          previewUrl: previewUrl,
                          memorialName: access.memorial!.name,
                        ))
                : MaterialPageRoute(
                    builder: (_) => WebViewPreviewScreen(
                          previewUrl: previewUrl,
                          memorialName: access.memorial!.name,
                        )),
          );
          await _resetScannerAfterNavigation();
          break;

        case MemorialViewAccessType.privateNoAccess:
          debugPrint('🔒 Private No Access → MemorialPrivateScreen');
          await Navigator.of(context).push(
            Platform.isIOS
                ? CupertinoPageRoute(
                    builder: (_) =>
                        MemorialPrivateScreen(memorial: access.memorial!))
                : MaterialPageRoute(
                    builder: (_) =>
                        MemorialPrivateScreen(memorial: access.memorial!)),
          );
          await _resetScannerAfterNavigation();
          break;

        case MemorialViewAccessType.notFound:
          _showError('Gedenkseite nicht gefunden.');
          await _resetScannerAfterNavigation();
          break;
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      debugPrint('❌ Fehler bei Access-Check: $e');
      _showError('Fehler beim Laden der Gedenkseite.');
      await _resetScannerAfterNavigation();
    }
  }

  Future<void> _resetScannerAfterNavigation() async {
    if (!mounted) return;

    debugPrint('🔄 Setze Scanner zurück...');

    setState(() {
      _hasScannedOnce = false;
      _isValidatingQrCode = false;
    });

    await _safeStartScanner();
  }

  void _showLoadingDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
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
                        radius: 16, color: isDark ? AppColors.accent : null)
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

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return BlocListener<MemorialBloc, MemorialState>(
      listener: (context, state) {
        debugPrint('📡 MemorialBloc State: ${state.status}');

        if (state.status == MemorialBlocStatus.success &&
            state.memorials.isNotEmpty) {
          debugPrint('✅ Memorial erstellt! Navigiere zum HomeScreen...');

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
              AppRoutes.home,
              (route) => false,
            );
          }
        }

        if (state.hasError) {
          debugPrint('❌ MemorialBloc Error: ${state.errorMessage}');
          _showError(state.errorMessage ?? AppStrings.errorOccurred);
        }
      },
      child: Platform.isIOS ? _buildIOSView() : _buildAndroidView(),
    );
  }

  // ============================================================
  // Android View
  // ============================================================

  Widget _buildAndroidView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          _qrCodeId == null ? 'QR-Code scannen' : AppStrings.createMemorialPage,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
        foregroundColor: isDark ? AppColors.textLight : AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<MemorialBloc, MemorialState>(
        builder: (context, state) {
          if (state.status == MemorialBlocStatus.creating) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.creatingMemorial,
                    style: TextStyle(fontSize: 15, color: AppColors.grey),
                  ),
                ],
              ),
            );
          }

          if (_qrCodeId == null) {
            return _buildScannerView(isDark);
          }

          return _buildDetailsContent(isDark);
        },
      ),
      floatingActionButton: _qrCodeId != null ? _buildFAB(isDark) : null,
    );
  }

  // ============================================================
  // iOS View
  // ============================================================

  Widget _buildIOSView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          _qrCodeId == null ? 'QR-Code scannen' : AppStrings.createMemorialPage,
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
        automaticallyImplyLeading: false,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: BlocBuilder<MemorialBloc, MemorialState>(
            builder: (context, state) {
              if (state.status == MemorialBlocStatus.creating) {
                return Center(
                  child: CupertinoActivityIndicator(
                    radius: 20,
                    color: isDark ? AppColors.grey : null,
                  ),
                );
              }

              if (_qrCodeId == null) {
                return _buildIOSScannerView(isDark);
              }

              return Column(
                children: [
                  Expanded(child: _buildIOSDetailsContent(isDark)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        color: _isFormValid()
                            ? (isDark ? AppColors.accent : AppColors.primary)
                            : (isDark
                                ? AppColors.toastBackgroundDark
                                : AppColors.greyLighter),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _isFormValid() ? _createMemorial : null,
                        child: Text(
                          AppStrings.createMemorialPage,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _isFormValid()
                                ? (isDark
                                    ? AppColors.primary
                                    : AppColors.background)
                                : AppColors.grey,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Scanner Views
  // ============================================================

  Widget _buildScannerView(bool isDark) {
    _initScanner();

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              _buildScannerWidget(),
              _buildScannerOverlay(isDark),
              if (_isValidatingQrCode)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textLight),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'QR-Code wird geprüft...',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            color: isDark ? AppColors.backgroundDark : AppColors.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 48,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Scanne den QR-Code',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Halte deine Kamera auf den QR-Code\nauf deinem RememberMe Produkt',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _openShop,
                    child: Text.rich(
                      TextSpan(
                        text: 'Noch keinen QR-Code? ',
                        style: TextStyle(fontSize: 14, color: AppColors.grey),
                        children: [
                          TextSpan(
                            text: 'Jetzt bestellen',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? AppColors.accent : AppColors.primary,
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  isDark ? AppColors.accent : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIOSScannerView(bool isDark) {
    _initScanner();

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              _buildScannerWidget(),
              _buildScannerOverlay(isDark),
              if (_isValidatingQrCode)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoActivityIndicator(
                          radius: 16,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'QR-Code wird geprüft...',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            color: isDark ? AppColors.backgroundDark : AppColors.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.qrcode_viewfinder,
                    size: 48,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Scanne den QR-Code',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                      fontFamily: '.SF Pro Display',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Halte deine Kamera auf den QR-Code\nauf deinem RememberMe Produkt',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey,
                      height: 1.4,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _openShop,
                    child: Text.rich(
                      TextSpan(
                        text: 'Noch keinen QR-Code? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                          fontFamily: '.SF Pro Text',
                        ),
                        children: [
                          TextSpan(
                            text: 'Jetzt bestellen',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? AppColors.accent : AppColors.primary,
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  isDark ? AppColors.accent : AppColors.primary,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScannerOverlay(bool isDark) {
    return CustomPaint(
      painter: ScannerOverlayPainter(
        borderColor: isDark ? AppColors.accent : AppColors.primary,
        borderWidth: 3,
        overlayColor: Colors.black.withOpacity(0.5),
        borderRadius: 16,
        scanAreaSize: 250,
      ),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildFAB(bool isDark) {
    final isValid = _isFormValid();

    return FloatingActionButton.extended(
      onPressed: isValid ? _createMemorial : null,
      backgroundColor: isValid
          ? (isDark ? AppColors.accent : AppColors.primary)
          : (isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter),
      elevation: isValid ? 4 : 0,
      icon: Icon(
        Icons.check_rounded,
        color: isValid
            ? (isDark ? AppColors.primary : AppColors.background)
            : AppColors.grey,
      ),
      label: Text(
        AppStrings.create,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isValid
              ? (isDark ? AppColors.primary : AppColors.background)
              : AppColors.grey,
        ),
      ),
    );
  }

  // ============================================================
  // Details Content — Vereinfacht: Nur Name + Foto
  // ============================================================

  Widget _buildDetailsContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeHeader(isDark, false),
            const SizedBox(height: 24),
            _buildAndroidProfileImagePicker(isDark),
            const SizedBox(height: 20),
            _buildAndroidNameField(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSDetailsContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeHeader(isDark, true),
            const SizedBox(height: 24),
            _buildIOSProfileImagePicker(isDark),
            const SizedBox(height: 20),
            _buildIOSNameField(isDark),
          ],
        ),
      ),
    );
  }

  /// Einladender Header statt kahlem Formular
  Widget _buildWelcomeHeader(bool isDark, bool isIOS) {
    return Column(
      children: [
        Icon(
          isIOS ? CupertinoIcons.heart_fill : Icons.favorite_rounded,
          size: 40,
          color: isDark ? AppColors.accent : AppColors.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'Erstelle eine Gedenkseite',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
            fontFamily: isIOS ? '.SF Pro Display' : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Wähle ein Foto und einen Namen.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.grey,
            height: 1.4,
            fontFamily: isIOS ? '.SF Pro Text' : null,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Form Fields
  // ============================================================

  Widget _buildAndroidNameField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
        ),
      ),
      child: TextFormField(
        controller: _nameController,
        style: TextStyle(
          fontSize: 17,
          color: isDark ? AppColors.textLight : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: AppStrings.personName,
          hintText: AppStrings.personNameHint,
          labelStyle: TextStyle(color: AppColors.grey),
          hintStyle: TextStyle(color: AppColors.grey),
          prefixIcon: Icon(
            Icons.person_outline_rounded,
            color: isDark ? AppColors.accent : AppColors.primary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return AppStrings.enterPersonName;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildIOSNameField(bool isDark) {
    return CupertinoTextField(
      controller: _nameController,
      placeholder: AppStrings.personName,
      placeholderStyle: TextStyle(color: AppColors.grey),
      style: TextStyle(
        fontSize: 17,
        color: isDark ? AppColors.textLight : AppColors.textPrimary,
        fontFamily: '.SF Pro Text',
      ),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Icon(
          CupertinoIcons.person,
          size: 20,
          color: isDark ? AppColors.accent : AppColors.primary,
        ),
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // ============================================================
  // Image Picker Widgets
  // ============================================================

  Widget _buildAndroidProfileImagePicker(bool isDark) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: InkWell(
        onTap: _showImageSourceSheet,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            border: Border.all(
              color: _profileImage != null
                  ? (isDark ? AppColors.accent : AppColors.primary)
                  : (isDark ? AppColors.borderDark : AppColors.greyLighter),
              width: _profileImage != null ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _profileImage != null
              ? _buildImagePreview(isDark)
              : _buildImagePlaceholder(isDark, false),
        ),
      ),
    );
  }

  Widget _buildIOSProfileImagePicker(bool isDark) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: GestureDetector(
        onTap: _showImageSourceSheet,
        child: Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            border: Border.all(
              color: _profileImage != null
                  ? (isDark ? AppColors.accent : AppColors.primary)
                  : (isDark ? AppColors.borderDark : AppColors.greyLighter),
              width: _profileImage != null ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _profileImage != null
              ? _buildImagePreview(isDark)
              : _buildImagePlaceholder(isDark, true),
        ),
      ),
    );
  }

  Widget _buildImagePreview(bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Image.file(
              _profileImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: (isDark ? Colors.black : Colors.white).withOpacity(0.1),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            _profileImage!,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _removeImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Platform.isIOS ? CupertinoIcons.xmark : Icons.close_rounded,
                size: 16,
                color: AppColors.textLight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(bool isDark, bool isIOS) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.accent.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isIOS ? CupertinoIcons.camera : Icons.camera_alt_rounded,
            size: 40,
            color: isDark ? AppColors.accent : AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Foto hinzufügen',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.accent : AppColors.primary,
            fontFamily: isIOS ? '.SF Pro Text' : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tippen zum Auswählen',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.grey,
            fontFamily: isIOS ? '.SF Pro Text' : null,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Scanner Overlay Painter
// ============================================================
class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double scanAreaSize;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.overlayColor,
    required this.borderRadius,
    required this.scanAreaSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scanRect = Rect.fromCenter(
        center: center, width: scanAreaSize, height: scanAreaSize);

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
          RRect.fromRectAndRadius(scanRect, Radius.circular(borderRadius)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, Paint()..color = overlayColor);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, Radius.circular(borderRadius)),
      borderPaint,
    );

    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(scanRect.left, scanRect.top + cornerLength),
        Offset(scanRect.left, scanRect.top + borderRadius), cornerPaint);
    canvas.drawLine(Offset(scanRect.left + cornerLength, scanRect.top),
        Offset(scanRect.left + borderRadius, scanRect.top), cornerPaint);

    canvas.drawLine(Offset(scanRect.right, scanRect.top + cornerLength),
        Offset(scanRect.right, scanRect.top + borderRadius), cornerPaint);
    canvas.drawLine(Offset(scanRect.right - cornerLength, scanRect.top),
        Offset(scanRect.right - borderRadius, scanRect.top), cornerPaint);

    canvas.drawLine(Offset(scanRect.left, scanRect.bottom - cornerLength),
        Offset(scanRect.left, scanRect.bottom - borderRadius), cornerPaint);
    canvas.drawLine(Offset(scanRect.left + cornerLength, scanRect.bottom),
        Offset(scanRect.left + borderRadius, scanRect.bottom), cornerPaint);

    canvas.drawLine(Offset(scanRect.right, scanRect.bottom - cornerLength),
        Offset(scanRect.right, scanRect.bottom - borderRadius), cornerPaint);
    canvas.drawLine(Offset(scanRect.right - cornerLength, scanRect.bottom),
        Offset(scanRect.right - borderRadius, scanRect.bottom), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
