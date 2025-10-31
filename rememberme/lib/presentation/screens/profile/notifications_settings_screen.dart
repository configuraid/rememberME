import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/profile/profile_bloc.dart';
import '../../../business_logic/profile/profile_event.dart';
import '../../../business_logic/profile/profile_state.dart';
import '../../../core/constants/app_colors.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benachrichtigungen'),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return ListView(
            children: [
              _buildSectionHeader('Push-Benachrichtigungen'),
              SwitchListTile(
                title: const Text('Push-Benachrichtigungen'),
                subtitle: const Text('Benachrichtigungen auf diesem Gerät'),
                value: state.settings.pushNotifications,
                onChanged: (value) => _updateNotifications(
                  context,
                  pushEnabled: value,
                  emailEnabled: state.settings.emailNotifications,
                  memorialUpdates: state.settings.memorialUpdates,
                  groupInvites: state.settings.groupInvites,
                ),
                secondary: const Icon(Icons.notifications_active),
                activeColor: AppColors.primary,
              ),
              const Divider(),
              _buildSectionHeader('E-Mail-Benachrichtigungen'),
              SwitchListTile(
                title: const Text('E-Mail-Benachrichtigungen'),
                subtitle: const Text('Benachrichtigungen per E-Mail'),
                value: state.settings.emailNotifications,
                onChanged: (value) => _updateNotifications(
                  context,
                  pushEnabled: state.settings.pushNotifications,
                  emailEnabled: value,
                  memorialUpdates: state.settings.memorialUpdates,
                  groupInvites: state.settings.groupInvites,
                ),
                secondary: const Icon(Icons.email),
                activeColor: AppColors.primary,
              ),
              const Divider(),
              _buildSectionHeader('Benachrichtigungstypen'),
              SwitchListTile(
                title: const Text('Gedenkseiten-Updates'),
                subtitle: const Text(
                  'Neue Beiträge und Änderungen',
                ),
                value: state.settings.memorialUpdates,
                onChanged: (value) => _updateNotifications(
                  context,
                  pushEnabled: state.settings.pushNotifications,
                  emailEnabled: state.settings.emailNotifications,
                  memorialUpdates: value,
                  groupInvites: state.settings.groupInvites,
                ),
                secondary: const Icon(Icons.favorite),
              ),
              SwitchListTile(
                title: const Text('Gruppen-Einladungen'),
                subtitle: const Text(
                  'Einladungen zu gemeinsamen Gedenkseiten',
                ),
                value: state.settings.groupInvites,
                onChanged: (value) => _updateNotifications(
                  context,
                  pushEnabled: state.settings.pushNotifications,
                  emailEnabled: state.settings.emailNotifications,
                  memorialUpdates: state.settings.memorialUpdates,
                  groupInvites: value,
                ),
                secondary: const Icon(Icons.group_add),
              ),
              const Divider(),
              _buildSectionHeader('Nicht stören'),
              ListTile(
                leading: const Icon(Icons.bedtime),
                title: const Text('Ruhezeiten'),
                subtitle: const Text('Keine Benachrichtigungen in der Nacht'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                ),
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Zeitplan'),
                subtitle: const Text('22:00 - 08:00'),
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sie können Benachrichtigungen jederzeit in den Systemeinstellungen Ihres Geräts anpassen.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
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

  void _updateNotifications(
    BuildContext context, {
    required bool pushEnabled,
    required bool emailEnabled,
    required bool memorialUpdates,
    required bool groupInvites,
  }) {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<ProfileBloc>().add(
            ProfileNotificationsUpdateRequested(
              userId: userId,
              pushEnabled: pushEnabled,
              emailEnabled: emailEnabled,
              memorialUpdates: memorialUpdates,
              groupInvites: groupInvites,
            ),
          );
    }
  }
}
