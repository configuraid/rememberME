import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rememberme/presentation/screens/memorial/memorial_screen.dart';
import 'package:rememberme/presentation/screens/profile/profile_screen.dart';
import 'dart:io';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MemorialDetailScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSView();
    }
    return _buildAndroidView();
  }

  // ==================== iOS View ====================
  Widget _buildIOSView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.95)
            : AppColors.surface.withOpacity(0.95),
        activeColor: isDark ? AppColors.accent : AppColors.primary,
        inactiveColor: AppColors.grey,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
            width: 0.5,
          ),
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.heart),
            activeIcon: const Icon(CupertinoIcons.heart_fill),
            label: AppStrings.memorial,
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
          builder: (context) => _screens[index],
        );
      },
    );
  }

  // ==================== Android View ====================
  Widget _buildAndroidView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: isDark ? AppColors.shadowDark : AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: isDark
                ? AppColors.accent.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.1),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.favorite_outline_rounded,
                  color: _currentIndex == 0
                      ? (isDark ? AppColors.accent : AppColors.primary)
                      : AppColors.grey,
                ),
                selectedIcon: Icon(
                  Icons.favorite_rounded,
                  color: isDark ? AppColors.accent : AppColors.primary,
                ),
                label: AppStrings.memorial,
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline_rounded,
                  color: _currentIndex == 1
                      ? (isDark ? AppColors.accent : AppColors.primary)
                      : AppColors.grey,
                ),
                selectedIcon: Icon(
                  Icons.person_rounded,
                  color: isDark ? AppColors.accent : AppColors.primary,
                ),
                label: AppStrings.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
