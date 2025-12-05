import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_event.dart';
import 'package:rememberme/business_logic/memorial/memorial_state.dart';
import 'package:rememberme/presentation/screens/memorial/memorial_screen.dart';
import '../profile/profile_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;

    if (user == null) {
      return;
    }

    if (user.primaryOrganizationId == null) {
      return;
    }

    context.read<MemorialBloc>().add(
          MemorialLoadRequested(
            organizationId: user.primaryOrganizationId!,
          ),
        );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // ============================================================
  // WICHTIG: Einheitliche Dark Mode Erkennung
  // ============================================================
  bool _isDarkMode(BuildContext context) {
    // Für iOS und Android gleichermaßen funktionierend
    if (Platform.isIOS) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode(context);

    final screens = [
      _buildMemorialsTab(context),
      _buildProfileTab(),
    ];

    if (Platform.isIOS) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          activeColor: isDark ? AppColors.accent : AppColors.primary,
          inactiveColor: AppColors.grey,
          backgroundColor: isDark
              ? AppColors.backgroundDarkElevated.withOpacity(0.94)
              : AppColors.surface.withOpacity(0.94),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.divider,
              width: 0.5,
            ),
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.heart),
              activeIcon: const Icon(CupertinoIcons.heart_fill),
              label: AppStrings.memorialPage,
            ),
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.person),
              activeIcon: const Icon(CupertinoIcons.person_fill),
              label: AppStrings.profile,
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return CupertinoTabView(
            builder: (context) {
              // WICHTIG: isDark hier nochmal neu ermitteln für den TabView Context
              final tabIsDark =
                  MediaQuery.of(context).platformBrightness == Brightness.dark;
              if (index == 0) {
                return _buildMemorialsTabContent(context, tabIsDark);
              }
              return const ProfileScreen();
            },
          );
        },
      );
    }

    // Android
    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: isDark ? AppColors.primaryLight : AppColors.primary,
        unselectedItemColor: isDark ? AppColors.grey : AppColors.greyDark,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_outline),
            activeIcon: const Icon(Icons.favorite),
            label: AppStrings.memorialPage,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildMemorialsTab(BuildContext context) {
    final isDark = _isDarkMode(context);
    return _buildMemorialsTabContent(context, isDark);
  }

  Widget _buildMemorialsTabContent(BuildContext context, bool isDark) {
    return BlocBuilder<MemorialBloc, MemorialState>(
      builder: (context, memorialState) {
        // WICHTIG: isDark hier nochmal für jeden Rebuild ermitteln
        final currentIsDark = _isDarkMode(context);

        // Loading State
        if (memorialState.isLoading) {
          return _buildLoadingState(context, currentIsDark);
        }

        // Error State
        if (memorialState.hasError) {
          return _buildErrorState(
              context, currentIsDark, memorialState.errorMessage);
        }

        // Empty State - Keine Gedenkseite vorhanden
        if (memorialState.memorials.isEmpty) {
          if (Platform.isIOS) {
            return _buildIOSEmptyState(context, currentIsDark);
          }
          return _buildAndroidEmptyState(context, currentIsDark);
        }

        // Memorial vorhanden
        final memorial = memorialState.memorials.first;
        return MemorialDetailScreen(memorial: memorial);
      },
    );
  }

  // ============================================================
  // LOADING STATE
  // ============================================================
  Widget _buildLoadingState(BuildContext context, bool isDark) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            AppStrings.myMemorialPage,
            style: TextStyle(
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          backgroundColor:
              isDark ? AppColors.backgroundDarkElevated.withOpacity(0.8) : null,
        ),
        child: Center(
          child: CupertinoActivityIndicator(
            radius: 14,
            color: isDark ? AppColors.accent : AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDarkSecondary : AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.myMemorialPage),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================
  Widget _buildErrorState(
      BuildContext context, bool isDark, String? errorMessage) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            AppStrings.myMemorialPage,
            style: TextStyle(
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          backgroundColor:
              isDark ? AppColors.backgroundDarkElevated.withOpacity(0.8) : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 64,
                  color: isDark ? AppColors.errorLight : AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage ?? AppStrings.errorOccurred,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    fontSize: 16,
                    fontFamily: '.SF Pro Text',
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: _loadData,
                  child: Text(AppStrings.tryAgain),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDarkSecondary : AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.myMemorialPage),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark ? AppColors.errorLight : AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage ?? AppStrings.errorOccurred,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.primaryLight : AppColors.primary,
                  foregroundColor: AppColors.textLight,
                ),
                child: Text(AppStrings.tryAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // iOS EMPTY STATE
  // ============================================================
  Widget _buildIOSEmptyState(BuildContext context, bool isDark) {
    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          AppStrings.myMemorialPage,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
            fontFamily: '.SF Pro Text',
          ),
        ),
        backgroundColor:
            isDark ? AppColors.backgroundDarkElevated.withOpacity(0.8) : null,
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration Container
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppColors.accent.withOpacity(0.3),
                              AppColors.primary.withOpacity(0.2),
                            ]
                          : [
                              AppColors.accent.withOpacity(0.15),
                              AppColors.primary.withOpacity(0.1),
                            ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      CupertinoIcons.heart_fill,
                      size: 64,
                      color: isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  AppStrings.noMemorialYet,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    fontFamily: '.SF Pro Display',
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  AppStrings.createYourPersonalMemorial,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? AppColors.textLight.withOpacity(0.7)
                        : AppColors.textSecondary,
                    fontFamily: '.SF Pro Text',
                    decoration: TextDecoration.none,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Feature List
                _buildIOSFeatureList(isDark),

                const SizedBox(height: 40),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    borderRadius: BorderRadius.circular(14),
                    color: isDark ? AppColors.accent : AppColors.primary,
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pushNamed(
                        AppRoutes.memorialCreate,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.add_circled_solid,
                          size: 22,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppStrings.createMemorialPage,
                          style: const TextStyle(
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
        ),
      ),
    );
  }

  Widget _buildIOSFeatureList(bool isDark) {
    final features = [
      (CupertinoIcons.photo_on_rectangle, 'Fotos & Videos teilen'),
      (CupertinoIcons.text_quote, 'Persönliche Geschichten'),
      (CupertinoIcons.person_2_fill, 'Mit Familie verbinden'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.surfaceDark.withOpacity(0.5) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDarkSubtle : AppColors.greyLighter,
          width: 1,
        ),
      ),
      child: Column(
        children: features.map((feature) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.accent.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    feature.$1,
                    size: 18,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    feature.$2,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                      fontFamily: '.SF Pro Text',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAndroidEmptyState(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDarkSecondary : AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.myMemorialPage),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration Container
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.primaryDark,
                            AppColors.primary.withOpacity(0.6),
                          ]
                        : [
                            AppColors.primary.withOpacity(0.2),
                            AppColors.accent.withOpacity(0.15),
                          ],
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 72,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                AppStrings.noMemorialYet,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                AppStrings.createYourPersonalMemorial,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Feature Cards
              _buildAndroidFeatureCards(isDark),

              const SizedBox(height: 40),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pushNamed(
                      AppRoutes.memorialCreate,
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 24),
                  label: Text(
                    AppStrings.createMemorialPage,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.primaryLight : AppColors.primary,
                    foregroundColor: AppColors.textLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: isDark ? 0 : 4,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidFeatureCards(bool isDark) {
    final features = [
      (Icons.photo_library_rounded, 'Fotos & Videos', 'Erinnerungen teilen'),
      (Icons.edit_note_rounded, 'Geschichten', 'Momente festhalten'),
      (Icons.people_rounded, 'Familie', 'Gemeinsam gedenken'),
    ];

    return Row(
      children: features.map((feature) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: features.indexOf(feature) == 1 ? 8 : 0,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                width: 1,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.shadow.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    feature.$1,
                    size: 24,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  feature.$2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  feature.$3,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfileTab() {
    return const ProfileScreen();
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    final isDark = _isDarkMode(context);

    return Card(
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            AppStrings.editMemorial,
            Icons.edit_outlined,
            AppColors.accent,
            () {
              setState(() => _selectedIndex = 1);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            AppStrings.license,
            Icons.workspace_premium,
            AppColors.primary,
            () => Navigator.of(context, rootNavigator: true)
                .pushNamed(AppRoutes.license),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    final isDark = _isDarkMode(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.4 : 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
