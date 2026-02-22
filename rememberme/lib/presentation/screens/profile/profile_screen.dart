import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/data/models/user_model.dart';
import 'package:rememberme/data/services/biometric_service.dart';
import 'package:rememberme/presentation/widgets/profile/delete_account_sheet.dart';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/auth/auth_event.dart';
import '../../../business_logic/auth/auth_state.dart';
import '../../../business_logic/profile/profile_bloc.dart';
import '../../../business_logic/profile/profile_event.dart';
import '../../../business_logic/profile/profile_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import 'edit_profile_screen.dart';
import 'about_screen.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _biometricService = BiometricService();
  bool _biometricEnabled = false;
  bool _biometricSupported = false;
  String _biometricName = 'Biometrie';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadBiometricStatus();
  }

  void _loadProfile() {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<ProfileBloc>().add(ProfileLoadRequested(userId));
    }
  }

  Future<void> _loadBiometricStatus() async {
    final supported = await _biometricService.isDeviceSupported();
    final enabled = await _biometricService.isBiometricLoginEnabled();
    final name = await _biometricService.getBiometricTypeName();

    if (mounted) {
      setState(() {
        _biometricSupported = supported;
        _biometricEnabled = enabled;
        _biometricName = name;
      });
    }
  }

  Future<void> _toggleBiometricLogin(bool value) async {
    if (value) {
      final authenticated = await _biometricService.authenticate(
        reason: 'Bestätige deine Identität',
      );
      if (!authenticated) return;

      final hasCredentials = await _biometricService.hasStoredCredentials();

      if (!hasCredentials) {
        if (mounted) _showReLoginForBiometricDialog();
        return;
      }

      await _biometricService.enableBiometricLogin();
      debugPrint(
          '✅ Biometric Login re-aktiviert (Credentials waren vorhanden)');
    } else {
      await _biometricService.disableBiometricLogin();
    }

    if (mounted) {
      setState(() => _biometricEnabled = value);
    }
  }

  void _showReLoginForBiometricDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Erneut anmelden'),
          content: const Text(
            'Bitte logge dich einmal mit E-Mail und Passwort ein, um den biometrischen Login einzurichten.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              isDefaultAction: true,
              child: const Text('Verstanden'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor:
              isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Erneut anmelden',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Bitte logge dich einmal mit E-Mail und Passwort ein, um den biometrischen Login einzurichten.',
            style: TextStyle(fontSize: 15, color: AppColors.grey),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                foregroundColor:
                    isDark ? AppColors.primary : AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Verstanden'),
            ),
          ],
        ),
      );
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final trimmedName = name.trim();
    final parts = trimmedName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmedName[0].toUpperCase();
  }

  void _showErrorMessage(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
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
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.grey,
                fontFamily: '.SF Pro Text',
              ),
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
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: AppColors.textLight),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.textLight),
                ),
              ),
            ],
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

  void _handleAccountDeleted(BuildContext context) {
    _biometricService.clearCredentials();
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.isDeleted) {
          _handleAccountDeleted(context);
          return;
        }
        if (state.hasError && state.errorMessage != null) {
          _showErrorMessage(context, state.errorMessage!);
        }
      },
      builder: (context, profileState) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user = authState.user;
            if (Platform.isIOS) {
              return _buildIOSView(context, user, profileState);
            }
            return _buildAndroidView(context, user, profileState);
          },
        );
      },
    );
  }

  // ============================================================
  // iOS VIEW
  // ============================================================
  Widget _buildIOSView(
      BuildContext context, UserModel? user, ProfileState profileState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          AppStrings.profile,
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
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async => _loadProfile(),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildProfileHeader(user, profileState, isDark),
                  const SizedBox(height: 24),
                  _buildMenuSections(context, user, isDark),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Android VIEW
  // ============================================================
  Widget _buildAndroidView(
      BuildContext context, UserModel? user, ProfileState profileState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          AppStrings.profile,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
        foregroundColor: isDark ? AppColors.textLight : AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadProfile(),
        color: isDark ? AppColors.accent : AppColors.primary,
        child: ListView(
          children: [
            _buildProfileHeader(user, profileState, isDark),
            const SizedBox(height: 24),
            _buildMenuSections(context, user, isDark),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Profilbild + Name (WhatsApp-Style)
  // ============================================================
  Widget _buildProfileHeader(
      UserModel? user, ProfileState profileState, bool isDark) {
    final displayName =
        profileState.displayName ?? user?.displayName ?? AppStrings.unknown;

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          // Avatar – groß, ohne Border
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              Platform.isIOS
                  ? CupertinoPageRoute(
                      builder: (_) => const EditProfileScreen())
                  : MaterialPageRoute(
                      builder: (_) => const EditProfileScreen()),
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: isDark
                  ? AppColors.accent.withOpacity(0.3)
                  : AppColors.primary.withOpacity(0.15),
              backgroundImage: profileState.profileImageUrl != null
                  ? NetworkImage(profileState.profileImageUrl!)
                  : null,
              child: profileState.profileImageUrl == null
                  ? Text(
                      _getInitials(user?.displayName),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.accent : AppColors.primary,
                        fontFamily: Platform.isIOS ? '.SF Pro Display' : null,
                        decoration: TextDecoration.none,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            displayName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: Platform.isIOS ? '.SF Pro Display' : null,
              decoration: TextDecoration.none,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Alle Menu Sections (WhatsApp-Style)
  // ============================================================
  Widget _buildMenuSections(
      BuildContext context, UserModel? user, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Einstellungen
        _buildSectionHeader('Einstellungen', isDark),
        _buildCard(
          isDark: isDark,
          children: [
            _buildMenuItem(
              icon: Platform.isIOS
                  ? CupertinoIcons.person
                  : Icons.person_outline_rounded,
              title: AppStrings.editProfile,
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                Platform.isIOS
                    ? CupertinoPageRoute(
                        builder: (_) => const EditProfileScreen())
                    : MaterialPageRoute(
                        builder: (_) => const EditProfileScreen()),
              ),
            ),
            _buildDivider(isDark),
            if (_biometricSupported) ...[
              _buildBiometricToggle(isDark),
              _buildDivider(isDark),
            ],
            _buildMenuItem(
              icon: Platform.isIOS
                  ? CupertinoIcons.bell
                  : Icons.notifications_none_rounded,
              title: 'Benachrichtigungen',
              isDark: isDark,
              onTap: () {},
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Hilfe & Info
        _buildSectionHeader('Hilfe & Info', isDark),
        _buildCard(
          isDark: isDark,
          children: [
            _buildMenuItem(
              icon: Platform.isIOS
                  ? CupertinoIcons.question_circle
                  : Icons.help_outline_rounded,
              title: AppStrings.helpAndFaq,
              isDark: isDark,
              onTap: () {},
            ),
            _buildDivider(isDark),
            _buildMenuItem(
              icon: Platform.isIOS
                  ? CupertinoIcons.info_circle
                  : Icons.info_outline_rounded,
              title: AppStrings.about,
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                Platform.isIOS
                    ? CupertinoPageRoute(builder: (_) => const AboutScreen())
                    : MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
            ),
            _buildDivider(isDark),
            _buildMenuItem(
              icon: Platform.isIOS
                  ? CupertinoIcons.chat_bubble_text
                  : Icons.feedback_outlined,
              title: AppStrings.sendFeedback,
              isDark: isDark,
              onTap: () {},
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Konto
        _buildSectionHeader('Konto', isDark),
        _buildCard(
          isDark: isDark,
          children: [
            _buildMenuItem(
              icon: Platform.isIOS
                  ? CupertinoIcons.square_arrow_right
                  : Icons.logout_rounded,
              title: AppStrings.logout,
              isDark: isDark,
              isDestructive: true,
              onTap: () => _showLogoutDialog(
                  context, Theme.of(context).brightness == Brightness.dark),
            ),
            _buildDivider(isDark),
            _buildMenuItem(
              icon: Platform.isIOS
                  ? CupertinoIcons.trash
                  : Icons.delete_outline_rounded,
              title: AppStrings.deleteAccount,
              isDark: isDark,
              isDestructive: true,
              onTap: () => _showDeleteAccountDialog(
                  context, Theme.of(context).brightness == Brightness.dark),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // Section Header
  // ============================================================
  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.grey,
          fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  // ============================================================
  // Card Container
  // ============================================================
  Widget _buildCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  // ============================================================
  // Menu Item (WhatsApp-Style: Icon direkt, kein farbiger BG)
  // ============================================================
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.textLight : AppColors.textPrimary);
    final iconColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.textLight : AppColors.textPrimary);

    if (Platform.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: color,
                    fontFamily: '.SF Pro Text',
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 20,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Biometric Toggle (flach)
  // ============================================================
  Widget _buildBiometricToggle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Icon(
            Platform.isIOS
                ? CupertinoIcons.lock_shield
                : Icons.fingerprint_rounded,
            size: 22,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '$_biometricName Login',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          if (Platform.isIOS)
            CupertinoSwitch(
              value: _biometricEnabled,
              activeTrackColor: isDark ? AppColors.accent : AppColors.primary,
              onChanged: _toggleBiometricLogin,
            )
          else
            Switch.adaptive(
              value: _biometricEnabled,
              activeColor: isDark ? AppColors.accent : AppColors.primary,
              onChanged: _toggleBiometricLogin,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // Divider (eingerückt ab Icon-Ende)
  // ============================================================
  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 54),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.borderDark : AppColors.divider,
      ),
    );
  }

  // ============================================================
  // Dialoge (unverändert)
  // ============================================================
  void _showLogoutDialog(BuildContext context, bool isDark) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(
            AppStrings.logout,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            AppStrings.logoutConfirmMessage,
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
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
                Navigator.of(ctx).pop();
                Navigator.of(context, rootNavigator: true)
                    .pushReplacementNamed(AppRoutes.login);
              },
              child: Text(
                AppStrings.logout,
                style: const TextStyle(
                  fontSize: 17,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor:
              isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.toastBackgroundDark
                  : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.logout_rounded,
              size: 24,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
          ),
          title: Text(
            AppStrings.logout,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          content: Text(
            AppStrings.logoutConfirmMessage,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.grey,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
                Navigator.of(ctx).pop();
                Navigator.of(context, rootNavigator: true)
                    .pushReplacementNamed(AppRoutes.login);
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? AppColors.accent : AppColors.primary,
                foregroundColor:
                    isDark ? AppColors.primary : AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                AppStrings.logout,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showDeleteAccountDialog(BuildContext context, bool isDark) {
    if (Platform.isIOS) {
      DeleteAccountConfirmationFlow.show(
        context,
        isDark: isDark,
        userId: context.read<AuthBloc>().state.user?.id,
        onDeleteAccount: (userId) {
          context.read<ProfileBloc>().add(
                ProfileDeleteAccountRequested(userId: userId, password: ''),
              );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor:
              isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_rounded,
              size: 24,
              color: isDark ? AppColors.errorLight : AppColors.error,
            ),
          ),
          title: Text(
            AppStrings.deleteAccount,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          content: Text(
            AppStrings.deleteAccountWarning,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppStrings.cancel,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.grey,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                final userId = context.read<AuthBloc>().state.user?.id;
                if (userId != null) {
                  context.read<ProfileBloc>().add(
                        ProfileDeleteAccountRequested(
                          userId: userId,
                          password: '',
                        ),
                      );
                }
                Navigator.of(ctx).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.errorLight : AppColors.error,
                foregroundColor: AppColors.textLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                AppStrings.deleteAccount,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
