import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rememberme/core/constants/app_colors.dart';
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

class _WebViewPreviewScreenState extends State<WebViewPreviewScreen>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _loadingProgress = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initPulseAnimation();
    _initWebView();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initPulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
            debugPrint('Page started loading: $url');
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
            debugPrint('Page finished loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');

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
            debugPrint('Blocked external navigation: ${request.url}');
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
        return error.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSLayout(context);
    }
    return _buildAndroidLayout(context);
  }

  Widget _buildIOSLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.memorialName,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontFamily: '.SF Pro Text',
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Vorschau',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.grey,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
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
            color: isDark ? AppColors.accent : AppColors.primary,
            size: 22,
          ),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            if (!_hasError) WebViewWidget(controller: _controller),
            if (_isLoading && !_hasError) _buildLoadingState(isDark),
            if (_hasError) _buildIOSErrorState(isDark),
          ],
        ),
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
                color: AppColors.error.withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.wifi_slash,
                size: 48,
                color: isDark ? AppColors.errorLight : AppColors.error,
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
            SizedBox(
              width: double.infinity,
              height: 50,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                color: isDark ? AppColors.accent : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _controller.reload();
                },
                child: Text(
                  'Erneut versuchen',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primary : AppColors.background,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.memorialName,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Vorschau',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
        foregroundColor: isDark ? AppColors.textLight : AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? AppColors.accent : AppColors.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (!_hasError) WebViewWidget(controller: _controller),
          if (_isLoading && !_hasError) _buildLoadingState(isDark),
          if (_hasError) _buildAndroidErrorState(isDark),
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
                color: AppColors.error.withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: isDark ? AppColors.errorLight : AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Laden fehlgeschlagen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Ein unbekannter Fehler ist aufgetreten.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _controller.reload();
                },
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.accent : AppColors.primary,
                  foregroundColor:
                      isDark ? AppColors.primary : AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Erneut versuchen',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    final accentColor = isDark ? AppColors.accent : AppColors.primary;

    return Positioned.fill(
      child: Material(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
        child: Column(
          children: [
            LinearProgressIndicator(
              value: _loadingProgress / 100,
              backgroundColor:
                  isDark ? AppColors.borderDark : AppColors.greyLighter,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 2.5,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor.withOpacity(0.15),
                                accentColor.withOpacity(0.05),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Platform.isIOS
                                ? CupertinoIcons.heart_fill
                                : Icons.favorite_rounded,
                            size: 36,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        widget.memorialName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gedenkseite wird vorbereitet...',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 180,
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _loadingProgress / 100,
                                backgroundColor: isDark
                                    ? AppColors.borderDark
                                    : AppColors.greyLighter,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(accentColor),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_loadingProgress%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
