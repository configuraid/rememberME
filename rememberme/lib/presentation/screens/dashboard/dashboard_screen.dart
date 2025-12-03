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

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildMemorialsTab(),
      _buildProfileTab(),
    ];

    if (Platform.isIOS) {
      final brightness = MediaQuery.of(context).platformBrightness;
      final isDark = brightness == Brightness.dark;

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
            builder: (context) => screens[index],
          );
        },
      );
    }

    // Android
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

  Widget _buildMemorialsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<MemorialBloc, MemorialState>(
      builder: (context, memorialState) {
        if (memorialState.isLoading) {
          return Scaffold(
            backgroundColor: isDark
                ? AppColors.backgroundDarkSecondary
                : AppColors.background,
            appBar: AppBar(
              title: Text(AppStrings.myMemorialPage),
              backgroundColor:
                  isDark ? AppColors.surfaceDark : AppColors.primary,
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

        if (memorialState.hasError) {
          return Scaffold(
            backgroundColor: isDark
                ? AppColors.backgroundDarkSecondary
                : AppColors.background,
            appBar: AppBar(
              title: Text(AppStrings.myMemorialPage),
              backgroundColor:
                  isDark ? AppColors.surfaceDark : AppColors.primary,
              foregroundColor: AppColors.textLight,
            ),
            body: Center(
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
                    memorialState.errorMessage ?? AppStrings.errorOccurred,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadData(),
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
          );
        }

        // Keine Gedenkseite vorhanden
        if (memorialState.memorials.isEmpty) {
          return Scaffold(
            backgroundColor: isDark
                ? AppColors.backgroundDarkSecondary
                : AppColors.background,
            appBar: AppBar(
              title: Text(AppStrings.myMemorialPage),
              backgroundColor:
                  isDark ? AppColors.surfaceDark : AppColors.primary,
              foregroundColor: AppColors.textLight,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: isDark
                          ? AppColors.accent.withOpacity(0.5)
                          : AppColors.accent.withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.noMemorialYet,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.createYourPersonalMemorial,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.greyDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pushNamed(
                          AppRoutes.memorialCreate,
                        );
                      },
                      icon: const Icon(Icons.add, size: 24),
                      label: Text(
                        AppStrings.createMemorialPage,
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                        foregroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Gedenkseite vorhanden → Detail-Ansicht anzeigen
        final memorial = memorialState.memorials.first;

        return MemorialDetailScreen(memorial: memorial);
      },
    );
  }

  Widget _buildProfileTab() {
    return const ProfileScreen();
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              // Navigiere zur Gedenkseite
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
