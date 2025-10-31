import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/profile/profile_bloc.dart';
import '../../../business_logic/profile/profile_event.dart';
import '../../../business_logic/profile/profile_state.dart';
import '../../../core/constants/app_colors.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datenschutz & Sicherheit'),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return ListView(
            children: [
              _buildSectionHeader('Profil-Sichtbarkeit'),
              SwitchListTile(
                title: const Text('Öffentliches Profil'),
                subtitle: const Text(
                  'Ihr Profil kann von anderen Nutzern gefunden werden',
                ),
                value: state.settings.profilePublic,
                onChanged: (value) => _updatePrivacy(
                  context,
                  profilePublic: value,
                  showEmail: state.settings.showEmail,
                  allowSearchEngines: state.settings.allowSearchEngines,
                ),
                secondary: const Icon(Icons.public),
                activeColor: AppColors.primary,
              ),
              SwitchListTile(
                title: const Text('E-Mail-Adresse anzeigen'),
                subtitle: const Text(
                  'Andere können Ihre E-Mail-Adresse sehen',
                ),
                value: state.settings.showEmail,
                onChanged: (value) => _updatePrivacy(
                  context,
                  profilePublic: state.settings.profilePublic,
                  showEmail: value,
                  allowSearchEngines: state.settings.allowSearchEngines,
                ),
                secondary: const Icon(Icons.email),
                activeColor: AppColors.primary,
              ),
              const Divider(),
              _buildSectionHeader('Suchmaschinen'),
              SwitchListTile(
                title: const Text('In Suchmaschinen auffindbar'),
                subtitle: const Text(
                  'Ihre Gedenkseiten können über Google gefunden werden',
                ),
                value: state.settings.allowSearchEngines,
                onChanged: (value) => _updatePrivacy(
                  context,
                  profilePublic: state.settings.profilePublic,
                  showEmail: state.settings.showEmail,
                  allowSearchEngines: value,
                ),
                secondary: const Icon(Icons.search),
                activeColor: AppColors.primary,
              ),
              const Divider(),
              _buildSectionHeader('Daten & Downloads'),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Meine Daten herunterladen'),
                subtitle: const Text('Export aller Ihrer Daten'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showDownloadDataDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Aktivitätsprotokoll'),
                subtitle: const Text('Ihre letzten Aktivitäten ansehen'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const Divider(),
              _buildSectionHeader('Sicherheit'),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Zwei-Faktor-Authentifizierung'),
                subtitle: const Text('Nicht aktiviert'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.devices),
                title: const Text('Aktive Geräte'),
                subtitle: const Text('Geräte verwalten'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.vpn_key),
                title: const Text('App-Berechtigungen'),
                subtitle: const Text('Kamera, Speicher, etc.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: AppColors.info.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Ihre Daten sind sicher',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Wir verwenden modernste Verschlüsselung und speichern Ihre Daten gemäß DSGVO-Standards.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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

  void _updatePrivacy(
    BuildContext context, {
    required bool profilePublic,
    required bool showEmail,
    required bool allowSearchEngines,
  }) {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<ProfileBloc>().add(
            ProfilePrivacyUpdateRequested(
              userId: userId,
              profilePublic: profilePublic,
              showEmail: showEmail,
              allowSearchEngines: allowSearchEngines,
            ),
          );
    }
  }

  void _showDownloadDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daten herunterladen'),
        content: const Text(
          'Wir erstellen ein Archiv mit all Ihren Daten. Sie erhalten eine E-Mail, sobald der Download bereit ist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Daten-Export initiieren
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Daten-Export wurde gestartet'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Herunterladen'),
          ),
        ],
      ),
    );
  }
}
