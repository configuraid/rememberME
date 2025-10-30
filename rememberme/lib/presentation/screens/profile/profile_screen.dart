import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/auth/auth_event.dart';
import '../../../business_logic/auth/auth_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.profile),
          ),
          body: ListView(
            children: [
              // Profil Header
              Container(
                padding: const EdgeInsets.all(24),
                color: AppColors.primary,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? '',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Menu Items
              ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: const Text(AppStrings.license),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.license),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text(AppStrings.settings),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text(AppStrings.notifications),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text(AppStrings.privacy),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text(AppStrings.about),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text(AppStrings.logout,
                    style: TextStyle(color: AppColors.error)),
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text('Möchten Sie sich wirklich abmelden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}
