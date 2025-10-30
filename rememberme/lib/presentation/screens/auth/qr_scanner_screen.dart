import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/auth/auth_event.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  // In einer echten App würde hier qr_code_scanner oder mobile_scanner verwendet werden
  // Für das Demo verwenden wir einen Mock-Scanner

  void _simulateScan() {
    // Simuliere QR-Code Scan mit Demo-Key
    const demoKey = 'DEMO-AUTH-KEY-12345';
    context.read<AuthBloc>().add(const AuthLoginWithQRRequested(demoKey));

    // Navigate zurück nach Login - BlocListener dort übernimmt Navigation
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'QR-Code scannen',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Scanner Bereich (Mock)
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
                      color: AppColors.accent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        size: 100,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'QR-Code hier positionieren',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Anweisungen
                Text(
                  'Halte den QR-Code vor die Kamera',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Demo-Scan Button (nur für Entwicklung)
                ElevatedButton.icon(
                  onPressed: _simulateScan,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Demo-Scan simulieren'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
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
        ],
      ),
    );
  }
}
