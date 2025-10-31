import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/presentation/screens/memorial/memorial_list_screen.dart';
import 'package:rememberme/presentation/screens/profile/profile_screen.dart';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/auth/auth_state.dart';
import '../../../business_logic/memorial/memorial_bloc.dart';
import '../../../business_logic/memorial/memorial_event.dart';
import '../../../business_logic/memorial/memorial_state.dart';
import '../../../business_logic/license/license_bloc.dart';
import '../../../business_logic/license/license_event.dart';
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
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<MemorialBloc>().add(MemorialLoadRequested(userId));
      context.read<LicenseBloc>().add(LicenseLoadRequested(userId));
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeTab(),
      _buildMemorialsTab(),
      _buildProfileTab(),
    ];

    if (Platform.isIOS) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home),
              label: 'Übersicht',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.memories),
              label: 'Gedenkseiten',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person),
              label: 'Profil',
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

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: AppStrings.dashboard,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: AppStrings.myMemorials,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppStrings.profile,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pushNamed(
                AppRoutes.memorialList,
                arguments: {'create': true},
              ),
              icon: const Icon(Icons.add),
              label: const Text('Erstellen'),
            )
          : null,
    );
  }

  Widget _buildHomeTab() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<MemorialBloc, MemorialState>(
          builder: (context, memorialState) {
            final user = authState.user;
            final memorials = memorialState.memorials;

            return Scaffold(
              appBar: AppBar(
                title: const Text(AppStrings.dashboard),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async => _loadData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Begrüßung
                        Text(
                          'Hallo, ${user?.name ?? ""}!',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Willkommen in deinem Dashboard',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),

                        // Statistik-Karten
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                'Gedenkseiten',
                                '${memorials.length}',
                                Icons.favorite,
                                AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                'Besucher',
                                '${memorials.fold<int>(0, (sum, m) => sum + m.viewCount)}',
                                Icons.visibility,
                                AppColors.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Schnellzugriff
                        Text(
                          AppStrings.quickActions,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),

                        _buildQuickActions(context),

                        const SizedBox(height: 24),

                        // Letzte Aktivitäten
                        Text(
                          AppStrings.recentActivity,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),

                        ...memorials.take(3).map((memorial) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.accent.withOpacity(0.2),
                                child: const Icon(Icons.favorite,
                                    color: AppColors.accent),
                              ),
                              title: Text(memorial.name),
                              subtitle: Text(
                                'Erstellt am ${memorial.createdAt.day}.${memorial.createdAt.month}.${memorial.createdAt.year}',
                              ),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () =>
                                  Navigator.of(context, rootNavigator: true)
                                      .pushNamed(
                                AppRoutes.memorialDetail,
                                arguments: memorial,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMemorialsTab() {
    return const MemorialListScreen();
  }

  Widget _buildProfileTab() {
    return const ProfileScreen();
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Card(
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
              style: Theme.of(context).textTheme.bodyMedium,
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
            'Neue Seite',
            Icons.add_circle_outline,
            AppColors.accent,
            () => Navigator.of(context, rootNavigator: true)
                .pushNamed(AppRoutes.memorialList),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            'Lizenz',
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
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
