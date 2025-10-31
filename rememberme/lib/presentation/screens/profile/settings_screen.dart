import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/profile/profile_bloc.dart';
import '../../../business_logic/profile/profile_event.dart';
import '../../../business_logic/profile/profile_state.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return ListView(
            children: [
              _buildSectionHeader('Erscheinungsbild'),
              _buildThemeSelector(context, state),
              const Divider(),
              _buildSectionHeader('Sprache & Region'),
              _buildLanguageSelector(context, state),
              const Divider(),
              _buildSectionHeader('App-Verhalten'),
              SwitchListTile(
                title: const Text('Animationen aktivieren'),
                subtitle: const Text('Bewegungen und Übergänge'),
                value: true,
                onChanged: (value) {},
                secondary: const Icon(Icons.animation),
              ),
              SwitchListTile(
                title: const Text('Offline-Modus'),
                subtitle: const Text('Daten lokal zwischenspeichern'),
                value: false,
                onChanged: (value) {},
                secondary: const Icon(Icons.cloud_off),
              ),
              const Divider(),
              _buildSectionHeader('Daten & Speicher'),
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Cache leeren'),
                subtitle: const Text('Temporäre Daten entfernen'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showClearCacheDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download-Qualität'),
                subtitle: const Text('Hoch'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ProfileState state) {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Hell'),
          subtitle: const Text('Helles Design'),
          value: 'light',
          groupValue: state.settings.themeMode,
          onChanged: (value) {
            if (value != null) {
              final userId = context.read<AuthBloc>().state.user?.id;
              if (userId != null) {
                context.read<ProfileBloc>().add(
                      ProfileThemeChangeRequested(
                        userId: userId,
                        themeMode: value,
                      ),
                    );
              }
            }
          },
          secondary: const Icon(Icons.light_mode),
        ),
        RadioListTile<String>(
          title: const Text('Dunkel'),
          subtitle: const Text('Dunkles Design'),
          value: 'dark',
          groupValue: state.settings.themeMode,
          onChanged: (value) {
            if (value != null) {
              final userId = context.read<AuthBloc>().state.user?.id;
              if (userId != null) {
                context.read<ProfileBloc>().add(
                      ProfileThemeChangeRequested(
                        userId: userId,
                        themeMode: value,
                      ),
                    );
              }
            }
          },
          secondary: const Icon(Icons.dark_mode),
        ),
        RadioListTile<String>(
          title: const Text('System'),
          subtitle: const Text('Systemeinstellung verwenden'),
          value: 'system',
          groupValue: state.settings.themeMode,
          onChanged: (value) {
            if (value != null) {
              final userId = context.read<AuthBloc>().state.user?.id;
              if (userId != null) {
                context.read<ProfileBloc>().add(
                      ProfileThemeChangeRequested(
                        userId: userId,
                        themeMode: value,
                      ),
                    );
              }
            }
          },
          secondary: const Icon(Icons.brightness_auto),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(BuildContext context, ProfileState state) {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Deutsch'),
          value: 'de',
          groupValue: state.settings.languageCode,
          onChanged: (value) {
            if (value != null) {
              final userId = context.read<AuthBloc>().state.user?.id;
              if (userId != null) {
                context.read<ProfileBloc>().add(
                      ProfileLanguageChangeRequested(
                        userId: userId,
                        languageCode: value,
                      ),
                    );
              }
            }
          },
          secondary: const Text('🇩🇪', style: TextStyle(fontSize: 24)),
        ),
        RadioListTile<String>(
          title: const Text('English'),
          value: 'en',
          groupValue: state.settings.languageCode,
          onChanged: (value) {
            if (value != null) {
              final userId = context.read<AuthBloc>().state.user?.id;
              if (userId != null) {
                context.read<ProfileBloc>().add(
                      ProfileLanguageChangeRequested(
                        userId: userId,
                        languageCode: value,
                      ),
                    );
              }
            }
          },
          secondary: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
        ),
      ],
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cache leeren'),
        content: const Text(
          'Möchten Sie wirklich alle temporären Daten löschen? Dies kann die App-Leistung vorübergehend beeinträchtigen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Cache leeren
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache wurde geleert'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Leeren'),
          ),
        ],
      ),
    );
  }
}
