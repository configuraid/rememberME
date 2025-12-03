import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rememberme/business_logic/auth/auth_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_event.dart';
import 'package:rememberme/business_logic/auth/auth_state.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _showError(String message) {
    if (Platform.isIOS) {
      final brightness = MediaQuery.of(context).platformBrightness;
      final isDark = brightness == Brightness.dark;

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
              child: Text(
                AppStrings.ok,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.interactive,
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
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _openQRScanner() {
    Navigator.of(context).push(
      Platform.isIOS
          ? CupertinoPageRoute(
              builder: (context) => _QRScannerScreen(
                onCodeScanned: _handleQRCodeScanned,
              ),
            )
          : MaterialPageRoute(
              builder: (context) => _QRScannerScreen(
                onCodeScanned: _handleQRCodeScanned,
              ),
            ),
    );
  }

  void _handleQRCodeScanned(String code) {
    // Validiere den QR-Code (Auth-Key)
    if (code.length < 10) {
      _showError(AppStrings.invalidAuthKey);
      return;
    }

    setState(() => _isLoading = true);

    // Haptic Feedback
    if (Platform.isIOS) {
      HapticFeedback.vibrate();
    } else {
      HapticFeedback.mediumImpact();
    }

    // Login mit dem gescannten Auth-Key
    context.read<AuthBloc>().add(AuthLoginWithKeyRequested(code));
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSView();
    }
    return _buildAndroidView();
  }

  // ============================================================
  // Android View
  // ============================================================
  Widget _buildAndroidView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state.status == AuthStatus.unauthenticated && !state.hasError) {
          final authRepo = context.read<AuthBloc>().authRepository;
          final organization = authRepo.currentOrganization;

          if (organization != null) {
            setState(() => _isLoading = false);

            final membersWithData =
                await authRepo.getUsersForOrganization(organization.id);

            if (mounted) {
              Navigator.of(context).pushNamed(
                AppRoutes.userSelection,
                arguments: {
                  'organization': organization,
                  'membersWithData': membersWithData,
                },
              );
            }
          }
        } else if (state.hasError) {
          setState(() => _isLoading = false);
          _showError(state.errorMessage ?? AppStrings.errorOccurred);
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDarkSecondary : AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo Container
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.accentGradient,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 60,
                    color: AppColors.textLight,
                  ),
                ),

                const SizedBox(height: 24),

                // App Name
                Text(
                  AppStrings.appNameRememberMe,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  AppStrings.digitalMemorials,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 1),

                // QR Scanner Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? AppColors.shadowDark
                            : AppColors.shadow.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // QR Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 36,
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        'QR-Code scannen',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Description
                      Text(
                        'Scanne den QR-Code deiner\nOrganisation zum Anmelden',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // Scan Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _openQRScanner,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.primaryLight
                                : AppColors.primary,
                            foregroundColor: AppColors.textLight,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textLight,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Scanner öffnen',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: AppColors.textLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withOpacity(isDark ? 0.4 : 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Den QR-Code findest du in deinen Unterlagen oder bei deinem Administrator.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.info.withOpacity(0.9)
                                : AppColors.info,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // iOS View - Mit Material Wrapper für korrekte Text-Darstellung
  // ============================================================
  Widget _buildIOSView() {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state.status == AuthStatus.unauthenticated && !state.hasError) {
          final authRepo = context.read<AuthBloc>().authRepository;
          final organization = authRepo.currentOrganization;

          if (organization != null) {
            setState(() => _isLoading = false);

            final membersWithData =
                await authRepo.getUsersForOrganization(organization.id);

            if (mounted) {
              Navigator.of(context).pushNamed(
                AppRoutes.userSelection,
                arguments: {
                  'organization': organization,
                  'membersWithData': membersWithData,
                },
              );
            }
          }
        } else if (state.hasError) {
          setState(() => _isLoading = false);
          _showError(state.errorMessage ?? AppStrings.errorOccurred);
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        // Material Wrapper entfernt gelbe Unterstriche
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.accentGradient,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.accent.withOpacity(isDark ? 0.5 : 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.heart_fill,
                      size: 60,
                      color: AppColors.textLight,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Name
                  Text(
                    AppStrings.appNameRememberMe,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                      letterSpacing: -0.5,
                      fontFamily: '.SF Pro Display',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    AppStrings.digitalMemorials,
                    style: TextStyle(
                      fontSize: 17,
                      color: AppColors.grey,
                      fontWeight: FontWeight.w400,
                      fontFamily: '.SF Pro Text',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 1),

                  // QR Scanner Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDarkElevated
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? AppColors.shadowDark
                              : AppColors.shadow.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // QR Icon Container
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primary.withOpacity(0.15)
                                : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            CupertinoIcons.qrcode_viewfinder,
                            size: 36,
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          'QR-Code scannen',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                            fontFamily: '.SF Pro Display',
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Description
                        Text(
                          'Scanne den QR-Code deiner\nOrganisation zum Anmelden',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.grey,
                            height: 1.5,
                            fontFamily: '.SF Pro Text',
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        // Scan Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                            onPressed: _isLoading ? null : _openQRScanner,
                            child: _isLoading
                                ? CupertinoActivityIndicator(
                                    color: AppColors.textLight,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.camera_fill,
                                        size: 22,
                                        color: AppColors.textLight,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Scanner öffnen',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textLight,
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

                  const SizedBox(height: 20),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.info.withOpacity(0.15)
                          : AppColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.info.withOpacity(0.4)
                            : AppColors.info.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.info_circle,
                          color: isDark
                              ? AppColors.info.withOpacity(0.9)
                              : AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Den QR-Code findest du in deinen Unterlagen oder bei deinem Administrator.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.info.withOpacity(0.9)
                                  : AppColors.info,
                              height: 1.4,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// QR Scanner Screen
// ============================================================
class _QRScannerScreen extends StatefulWidget {
  final Function(String) onCodeScanned;

  const _QRScannerScreen({required this.onCodeScanned});

  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _scannerController;
  bool _hasScanned = false;
  bool _isTorchOn = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    // Scanner Line Animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() => _hasScanned = true);

        // Haptic Feedback
        if (Platform.isIOS) {
          HapticFeedback.vibrate();
        } else {
          HapticFeedback.heavyImpact();
        }

        // Kurze Verzögerung für visuelles Feedback
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onCodeScanned(barcode.rawValue!);
          }
        });

        break;
      }
    }
  }

  void _toggleTorch() {
    _scannerController?.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);

    if (Platform.isIOS) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSScanner();
    }
    return _buildAndroidScanner();
  }

  // ============================================================
  // iOS Scanner - Mit Material Wrapper
  // ============================================================
  Widget _buildIOSScanner() {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.backgroundDark.withOpacity(0.8),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.xmark,
            color: AppColors.textLight,
            size: 24,
          ),
        ),
        middle: Text(
          'QR-Code scannen',
          style: TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _toggleTorch,
          child: Icon(
            _isTorchOn
                ? CupertinoIcons.bolt_fill
                : CupertinoIcons.bolt_slash_fill,
            color: _isTorchOn ? AppColors.warning : AppColors.textLight,
            size: 24,
          ),
        ),
      ),
      // Material Wrapper entfernt gelbe Unterstriche
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Camera
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),

            // Overlay
            _buildScannerOverlay(isDark),

            // Bottom Instructions
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _hasScanned
                          ? '✓ Code erkannt!'
                          : 'Halte die Kamera auf den QR-Code',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontFamily: '.SF Pro Text',
                      ),
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

  // ============================================================
  // Android Scanner
  // ============================================================
  Widget _buildAndroidScanner() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'QR-Code scannen',
          style: TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? AppColors.warning : AppColors.textLight,
            ),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Overlay
          _buildScannerOverlay(isDark),

          // Bottom Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _hasScanned
                        ? '✓ Code erkannt!'
                        : 'Halte die Kamera auf den QR-Code',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Scanner Overlay mit animierter Linie
  // ============================================================
  Widget _buildScannerOverlay(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.7;

        return Stack(
          children: [
            // Dunkle Überlagerung mit Ausschnitt
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                AppColors.backgroundDark.withOpacity(0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      margin: const EdgeInsets.only(bottom: 80),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scanner Rahmen
            Center(
              child: Container(
                width: scanAreaSize,
                height: scanAreaSize,
                margin: const EdgeInsets.only(bottom: 80),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _hasScanned ? AppColors.success : AppColors.accent,
                    width: 3,
                  ),
                ),
                child: Stack(
                  children: [
                    // Ecken
                    _buildCorner(Alignment.topLeft),
                    _buildCorner(Alignment.topRight),
                    _buildCorner(Alignment.bottomLeft),
                    _buildCorner(Alignment.bottomRight),

                    // Animierte Scanner-Linie
                    if (!_hasScanned)
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Positioned(
                            top: _animation.value * (scanAreaSize - 4),
                            left: 20,
                            right: 20,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accent.withOpacity(0),
                                    AppColors.accent,
                                    AppColors.accent.withOpacity(0),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Success Checkmark
                    if (_hasScanned)
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Platform.isIOS
                                ? CupertinoIcons.checkmark_alt
                                : Icons.check_rounded,
                            color: AppColors.textLight,
                            size: 48,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorner(Alignment alignment) {
    final isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(
                    color: _hasScanned ? AppColors.success : AppColors.accent,
                    width: 4,
                  )
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(
                    color: _hasScanned ? AppColors.success : AppColors.accent,
                    width: 4,
                  )
                : BorderSide.none,
            left: isLeft
                ? BorderSide(
                    color: _hasScanned ? AppColors.success : AppColors.accent,
                    width: 4,
                  )
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(
                    color: _hasScanned ? AppColors.success : AppColors.accent,
                    width: 4,
                  )
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: alignment == Alignment.topLeft
                ? const Radius.circular(24)
                : Radius.zero,
            topRight: alignment == Alignment.topRight
                ? const Radius.circular(24)
                : Radius.zero,
            bottomLeft: alignment == Alignment.bottomLeft
                ? const Radius.circular(24)
                : Radius.zero,
            bottomRight: alignment == Alignment.bottomRight
                ? const Radius.circular(24)
                : Radius.zero,
          ),
        ),
      ),
    );
  }
}
