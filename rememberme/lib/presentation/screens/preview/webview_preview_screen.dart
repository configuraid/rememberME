import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
    final isDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
        isDark ? AppColors.backgroundDark : AppColors.surface,
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
            debugPrint('   isForMainFrame: ${error.isForMainFrame}');

            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = _getErrorMessage(error);
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('remember-me-slug.vercel.app')) {
              return NavigationDecision.navigate;
            }
            debugPrint('🚫 Blocked external navigation: ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.previewUrl));
  }

  String _getErrorMessage(WebResourceError error) {
    switch (error.errorCode) {
      case -2:
        return 'Server nicht gefunden. Bitte überprüfe deine Internetverbindung.';
      case -1009:
      case -6:
        return 'Keine Internetverbindung.';
      case -1001:
      case -7:
        return 'Die Verbindung hat zu lange gedauert.';
      case -1003:
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vorschau',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontFamily: '.SF Pro Text',
              ),
            ),
            if (_isLoading)
              Text(
                '${_loadingProgress}%',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.grey,
                  fontFamily: '.SF Pro Text',
                ),
              ),
          ],
        ),
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.94)
            : AppColors.surface.withOpacity(0.94),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.divider,
            width: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: () => Navigator.pop(context),
          child: Icon(
            CupertinoIcons.xmark,
            color: AppColors.interactive,
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
                color: AppColors.interactive,
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
                color: AppColors.interactive,
                size: 22,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            if (!_hasError) WebViewWidget(controller: _controller),
            if (_isLoading && !_hasError) _buildIOSLoadingIndicator(isDark),
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
          LinearProgressIndicator(
            value: _loadingProgress / 100,
            backgroundColor:
                isDark ? AppColors.borderDark : AppColors.greyLighter,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.interactive,
            ),
            minHeight: 2,
          ),
          if (_loadingProgress < 30)
            Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                children: [
                  CupertinoActivityIndicator(
                    radius: 14,
                    color: isDark ? AppColors.grey : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vorschau wird geladen...',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey,
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
                color: isDark
                    ? AppColors.backgroundDarkElevated
                    : AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? AppColors.shadowDark : AppColors.shadow,
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.wifi_slash,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Laden fehlgeschlagen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontFamily: '.SF Pro Display',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Ein unbekannter Fehler ist aufgetreten.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.grey,
                height: 1.5,
                fontFamily: '.SF Pro Text',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CupertinoButton(
              onPressed: _refresh,
              color: AppColors.interactive,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    CupertinoIcons.refresh,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Erneut versuchen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDarkSecondary : AppColors.surface,
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
                  color: AppColors.textLight.withOpacity(0.7),
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
          if (!_hasError) WebViewWidget(controller: _controller),
          if (_isLoading && !_hasError) _buildAndroidLoadingIndicator(isDark),
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
          LinearProgressIndicator(
            value: _loadingProgress / 100,
            backgroundColor:
                isDark ? AppColors.cardBorderDark : AppColors.greyLighter,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppColors.primaryLight : AppColors.primary,
            ),
            minHeight: 3,
          ),
          if (_loadingProgress < 30)
            Container(
              width: double.infinity,
              color: isDark
                  ? AppColors.backgroundDarkSecondary
                  : AppColors.surface,
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
                          ? AppColors.textDarkSecondary
                          : AppColors.greyDark,
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
              child: const Icon(
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
                        ? AppColors.textDarkSecondary
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
                  foregroundColor: AppColors.textLight,
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
