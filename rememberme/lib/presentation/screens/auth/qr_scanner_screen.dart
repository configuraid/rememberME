import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_event.dart';
import 'package:rememberme/business_logic/auth/auth_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import 'user_selection_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;

  /// Simuliert QR-Code Scan für Entwicklung
  void _simulateScan() {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    print('📱 QRScannerScreen - Simuliere QR-Scan');

    // Simuliere QR-Code Scan mit Demo-Key
    const demoQRCode = 'QR-SCHMIDT-123'; // Aus Mock-Daten

    // ✅ Sende Login Event mit QR-Code
    context.read<AuthBloc>().add(AuthLoginWithQRRequested(demoQRCode));

    print('⏳ QRScannerScreen - Warte auf Auth-State Änderung...');
  }

  /// Verarbeitet gescannten QR-Code (für echten Scanner)
  void _processScannedCode(String qrCode) {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    print('📱 QRScannerScreen - QR-Code gescannt: $qrCode');

    // ✅ Sende Login Event mit gescanntem QR-Code
    context.read<AuthBloc>().add(AuthLoginWithQRRequested(qrCode));
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSView();
    }
    return _buildAndroidView();
  }

  // ===== ANDROID VIEW =====
  Widget _buildAndroidView() {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        print('👂 QRScannerScreen Listener - Status: ${state.status}');

        // ✅ Organisation gefunden → Lade User und navigiere zu UserSelectionScreen
        if (state.status == AuthStatus.unauthenticated && !state.hasError) {
          final authRepo = context.read<AuthBloc>().authRepository;
          final organization = authRepo.currentOrganization;

          if (organization != null) {
            print(
                '✅ QRScannerScreen - Organisation gefunden: ${organization.name}');
            setState(() => _isProcessing = false);

            // Lade alle User für diese Organisation
            final membersWithData =
                await authRepo.getUsersForOrganization(organization.id);

            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<AuthBloc>(),
                    child: UserSelectionScreen(
                      organization: organization,
                      membersWithData: membersWithData,
                    ),
                  ),
                ),
              );
            }
          }
        }
        // ✅ User authentifiziert → Dashboard
        else if (state.isAuthenticated) {
          print(
              '✅ QRScannerScreen - User authentifiziert, navigiere zu Dashboard');
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        }
        // ❌ Fehler → Zeige Meldung, erlaube erneuten Scan
        else if (state.hasError) {
          print('❌ QRScannerScreen - Fehler: ${state.errorMessage}');
          setState(() => _isProcessing = false);
          _showError(state.errorMessage ?? 'Ungültiger QR-Code');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'QR-Code scannen',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Stack(
          children: [
            // Scanner Bereich
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Scanner Frame
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isProcessing ? Colors.grey : AppColors.primary,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isProcessing
                              ? Icons.hourglass_empty
                              : Icons.qr_code_scanner,
                          size: 100,
                          color:
                              _isProcessing ? Colors.white30 : Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isProcessing
                              ? 'Verarbeite QR-Code...'
                              : 'QR-Code hier positionieren',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Anweisungen
                  Text(
                    _isProcessing
                        ? 'Bitte warten...'
                        : 'Halte den QR-Code vor die Kamera',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Demo-Scan Button (nur für Entwicklung)
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _simulateScan,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isProcessing
                        ? 'Verarbeite...'
                        : 'Demo-Scan (QR-SCHMIDT-123)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isProcessing ? Colors.grey : AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Hinweis unten
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Für QR-Scanner wird später ein Plugin wie mobile_scanner integriert',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading Overlay
            if (_isProcessing)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===== iOS VIEW =====
  Widget _buildIOSView() {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        print('👂 QRScannerScreen iOS Listener - Status: ${state.status}');

        // ✅ Organisation gefunden → Lade User und navigiere zu UserSelectionScreen
        if (state.status == AuthStatus.unauthenticated && !state.hasError) {
          final authRepo = context.read<AuthBloc>().authRepository;
          final organization = authRepo.currentOrganization;

          if (organization != null) {
            print(
                '✅ QRScannerScreen iOS - Organisation gefunden: ${organization.name}');
            setState(() => _isProcessing = false);

            // Lade alle User für diese Organisation
            final membersWithData =
                await authRepo.getUsersForOrganization(organization.id);

            if (mounted) {
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<AuthBloc>(),
                    child: UserSelectionScreen(
                      organization: organization,
                      membersWithData: membersWithData,
                    ),
                  ),
                ),
              );
            }
          }
        }
        // ✅ User authentifiziert → Dashboard
        else if (state.isAuthenticated) {
          print(
              '✅ QRScannerScreen iOS - User authentifiziert, navigiere zu Dashboard');
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        }
        // ❌ Fehler → Zeige Meldung, erlaube erneuten Scan
        else if (state.hasError) {
          print('❌ QRScannerScreen iOS - Fehler: ${state.errorMessage}');
          setState(() => _isProcessing = false);
          _showError(state.errorMessage ?? 'Ungültiger QR-Code');
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: Colors.black,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: Colors.transparent,
          border: null,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            child: const Icon(
              CupertinoIcons.xmark,
              color: Colors.white,
            ),
          ),
          middle: const Text(
            'QR-Code scannen',
            style: TextStyle(color: Colors.white),
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Scanner Bereich
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Scanner Frame
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              _isProcessing ? Colors.grey : AppColors.primary,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isProcessing
                                ? CupertinoIcons.hourglass
                                : CupertinoIcons.qrcode_viewfinder,
                            size: 100,
                            color:
                                _isProcessing ? Colors.white30 : Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isProcessing
                                ? 'Verarbeite QR-Code...'
                                : 'QR-Code hier positionieren',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Anweisungen
                    Text(
                      _isProcessing
                          ? 'Bitte warten...'
                          : 'Halte den QR-Code vor die Kamera',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Demo-Scan Button (nur für Entwicklung)
                    CupertinoButton.filled(
                      onPressed: _isProcessing ? null : _simulateScan,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CupertinoActivityIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.play_arrow_solid, size: 20),
                                SizedBox(width: 8),
                                Text('Demo-Scan (QR-SCHMIDT-123)'),
                              ],
                            ),
                    ),
                  ],
                ),
              ),

              // Hinweis unten
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Für QR-Scanner wird später ein Plugin wie mobile_scanner integriert',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading Overlay
              if (_isProcessing)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      radius: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== HELPER METHODS =====

  void _showError(String message) {
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
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
