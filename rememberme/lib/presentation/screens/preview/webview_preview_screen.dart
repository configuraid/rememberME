import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView Preview Screen for displaying memorial page preview
///
/// This screen loads the preview URL in an in-app WebView with
/// platform-native UI (iOS: Cupertino, Android: Material Design)
class WebViewPreviewScreen extends StatefulWidget {
  final String previewUrl;
  final String memorialName;

  const WebViewPreviewScreen({
    super.key,
    required this.previewUrl,
    required this.memorialName,
  });

  @override
  State<WebViewPreviewScreen> createState() => _WebViewPreviewScreenState();
}

class _WebViewPreviewScreenState extends State<WebViewPreviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
        Platform.isIOS ? CupertinoColors.systemBackground : Colors.white,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('🌐 Page started loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
                _errorMessage = null;
              });
            }
          },
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
              });
            }
          },
          onPageFinished: (String url) {
            debugPrint('✅ Page finished loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ WebView error: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = _getErrorMessage(error);
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation within our domain
            if (request.url.contains('remember-me-slug.vercel.app')) {
              return NavigationDecision.navigate;
            }
            // Block external links or handle them differently
            debugPrint('🚫 Blocked external navigation: ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.previewUrl));
  }

  String _getErrorMessage(WebResourceError error) {
    // Map common error codes to user-friendly messages
    switch (error.errorCode) {
      case -2: // NSURLErrorCannotFindHost / ERR_NAME_NOT_RESOLVED
        return 'Server nicht gefunden. Bitte überprüfe deine Internetverbindung.';
      case -1009: // NSURLErrorNotConnectedToInternet
      case -6: // ERR_INTERNET_DISCONNECTED
        return 'Keine Internetverbindung.';
      case -1001: // NSURLErrorTimedOut
      case -7: // ERR_TIMED_OUT
        return 'Die Verbindung hat zu lange gedauert.';
      case -1003: // NSURLErrorCannotFindHost
        return 'Server nicht erreichbar.';
      default:
        return error.description ?? 'Ein Fehler ist aufgetreten.';
    }
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _isLoading = true;
    });
    await _controller.reload();
  }

  void _sharePreview() {
    HapticFeedback.lightImpact();
    Share.share(
      'Schau dir die Vorschau an: ${widget.previewUrl}',
      subject: 'Preview: ${widget.memorialName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSLayout(context);
    }
    return _buildAndroidLayout(context);
  }

  // ============================================================
  // iOS Layout with CupertinoPageScaffold
  // ============================================================
  Widget _buildIOSLayout(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vorschau',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                fontFamily: '.SF Pro Text',
              ),
            ),
            if (_isLoading)
              Text(
                '${_loadingProgress}%',
                style: TextStyle(
                  fontSize: 11,
                  color: CupertinoColors.systemGrey,
                  fontFamily: '.SF Pro Text',
                ),
              ),
          ],
        ),
        backgroundColor: isDark
            ? const Color(0xFF1C1C1E).withOpacity(0.94)
            : CupertinoColors.systemBackground.withOpacity(0.94),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF38383A) : CupertinoColors.separator,
            width: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: () => Navigator.pop(context),
          child: Icon(
            CupertinoIcons.xmark,
            color: CupertinoColors.activeBlue,
            size: 22,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: _refresh,
              child: Icon(
                CupertinoIcons.refresh,
                color: CupertinoColors.activeBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: _sharePreview,
              child: Icon(
                CupertinoIcons.share,
                color: CupertinoColors.activeBlue,
                size: 22,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // WebView
            if (!_hasError) WebViewWidget(controller: _controller),

            // Loading indicator
            if (_isLoading && !_hasError) _buildIOSLoadingIndicator(isDark),

            // Error state
            if (_hasError) _buildIOSErrorState(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSLoadingIndicator(bool isDark) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _loadingProgress / 100,
            backgroundColor:
                isDark ? const Color(0xFF38383A) : CupertinoColors.systemGrey5,
            valueColor: const AlwaysStoppedAnimation<Color>(
              CupertinoColors.activeBlue,
            ),
            minHeight: 2,
          ),
          // Loading overlay (only shown at start)
          if (_loadingProgress < 30)
            Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                children: [
                  const CupertinoActivityIndicator(radius: 14),
                  const SizedBox(height: 16),
                  Text(
                    'Vorschau wird geladen...',
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.systemGrey,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIOSErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                CupertinoIcons.wifi_slash,
                size: 48,
                color: CupertinoColors.systemRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Laden fehlgeschlagen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                fontFamily: '.SF Pro Display',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Ein unbekannter Fehler ist aufgetreten.',
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.systemGrey,
                height: 1.5,
                fontFamily: '.SF Pro Text',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CupertinoButton(
              onPressed: _refresh,
              color: CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.refresh,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Erneut versuchen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                      fontFamily: '.SF Pro Text',
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
  // Android Layout with Material Design
  // ============================================================
  Widget _buildAndroidLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Vorschau'),
            if (_isLoading)
              Text(
                '${_loadingProgress}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Neu laden',
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _sharePreview,
            tooltip: 'Teilen',
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          if (!_hasError) WebViewWidget(controller: _controller),

          // Loading indicator
          if (_isLoading && !_hasError) _buildAndroidLoadingIndicator(isDark),

          // Error state
          if (_hasError) _buildAndroidErrorState(isDark),
        ],
      ),
    );
  }

  Widget _buildAndroidLoadingIndicator(bool isDark) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _loadingProgress / 100,
            backgroundColor:
                isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppColors.primaryLight : AppColors.primary,
            ),
            minHeight: 3,
          ),
          // Loading overlay (only shown at start)
          if (_loadingProgress < 30)
            Container(
              width: double.infinity,
              color: isDark ? const Color(0xFF121212) : Colors.white,
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Vorschau wird geladen...',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? const Color(0xFFB0B0B0)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAndroidErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.error.withOpacity(0.15),
                    AppColors.error.withOpacity(0.08),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Laden fehlgeschlagen',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Ein unbekannter Fehler ist aufgetreten.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? const Color(0xFFB0B0B0)
                        : AppColors.textSecondary,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.primaryLight,
                          AppColors.primaryLight.withOpacity(0.8),
                        ]
                      : [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.9),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? AppColors.primaryLight.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: const Text(
                  'Erneut versuchen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
