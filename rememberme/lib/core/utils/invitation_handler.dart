import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/data/models/memorial_model.dart';
import 'package:rememberme/data/services/invitation_redeem_service.dart';
import 'package:rememberme/business_logic/memorial/memorial_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_event.dart';
import 'dart:io';

import '../../core/utils/deep_link_handler.dart';
import '../../core/constants/app_colors.dart';

/// Handles incoming invitation links and redeems them
class InvitationHandler {
  static final InvitationHandler _instance = InvitationHandler._internal();
  factory InvitationHandler() => _instance;
  InvitationHandler._internal();

  final InvitationRedeemService _redeemService = InvitationRedeemService();

  BuildContext? _context;
  String? _currentUserId;

  /// Initialize with context and user ID
  /// Call this in your main app widget when user state changes
  void initialize({
    required BuildContext context,
    String? userId,
  }) {
    _context = context;
    _currentUserId = userId;

    // Set up the callback for incoming links
    deepLinkHandler.onInvitationReceived = _onInvitationReceived;

    // Check for pending invitation if user is logged in
    if (userId != null) {
      _checkPendingInvitation();
    }
  }

  /// Update user ID (call when auth state changes)
  void updateUserId(String? userId) {
    _currentUserId = userId;

    // Check for pending invitation when user logs in
    if (userId != null) {
      _checkPendingInvitation();
    }
  }

  /// Called when a deep link with invitation is received
  void _onInvitationReceived(String token) {
    debugPrint('🎫 InvitationHandler: Received token: $token');

    // If user is logged in, redeem immediately
    if (_currentUserId != null && _context != null) {
      _redeemInvitation(token);
    }
    // Otherwise, token is already stored and will be processed after login
  }

  /// Check and redeem any pending invitation
  Future<void> _checkPendingInvitation() async {
    if (_currentUserId == null || _context == null) return;

    final result =
        await _redeemService.checkAndRedeemPendingInvitation(_currentUserId!);

    if (result != null && _context != null) {
      if (result.success) {
        // ✅ FIX: Reload memorials after successful invitation redemption
        _reloadMemorials();
        _showSuccessDialog(result.memorial, result.alreadyHadAccess);
      }
    }
  }

  /// Redeem a specific invitation token
  Future<void> _redeemInvitation(String token) async {
    if (_currentUserId == null || _context == null) return;

    debugPrint('🎫 InvitationHandler: Redeeming token: $token');

    final result = await _redeemService.redeemInvitation(
      token: token,
      userId: _currentUserId!,
    );

    if (result.success) {
      // ✅ FIX: Reload memorials after successful invitation redemption
      _reloadMemorials();
      _showSuccessDialog(result.memorial, result.alreadyHadAccess);
    } else {
      _showErrorDialog(result.message ?? 'Fehler beim Einlösen der Einladung');
    }
  }

  /// ✅ NEW: Reload memorials in the MemorialBloc
  void _reloadMemorials() {
    if (_context == null || _currentUserId == null) return;

    try {
      final memorialBloc = _context!.read<MemorialBloc>();
      debugPrint(
          '🔄 InvitationHandler: Reloading memorials for user: $_currentUserId');
      memorialBloc.add(MemorialLoadRequested(userId: _currentUserId!));
    } catch (e) {
      debugPrint('⚠️ InvitationHandler: Could not reload memorials: $e');
    }
  }

  /// Show success dialog
  void _showSuccessDialog(MemorialModel? memorial, bool alreadyHadAccess) {
    if (_context == null) return;

    final isDark = Theme.of(_context!).brightness == Brightness.dark;
    final memorialName = memorial?.name ?? 'Gedenkseite';

    final message = alreadyHadAccess
        ? 'Du hast bereits Zugang zu "$memorialName"'
        : 'Du hast jetzt Zugang zu "$memorialName"';

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: _context!,
        builder: (ctx) => CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                alreadyHadAccess ? 'Bereits Zugang' : 'Erfolgreich!',
                style: const TextStyle(fontSize: 17),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              isDefaultAction: true,
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: _context!,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(alreadyHadAccess ? 'Bereits Zugang' : 'Erfolgreich!'),
            ],
          ),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? AppColors.accent : AppColors.primary,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    if (_context == null) return;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: _context!,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Fehler'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              isDefaultAction: true,
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: _context!,
        builder: (ctx) => AlertDialog(
          title: const Text('Fehler'),
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
}

/// Global instance
final invitationHandler = InvitationHandler();
