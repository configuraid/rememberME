import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/profile/profile_bloc.dart';
import '../../../business_logic/profile/profile_state.dart';
import '../../../core/constants/app_colors.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiken'),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final stats = state.statistics;

          if (stats == null) {
            return const Center(
              child: Text('Keine Statistiken verfügbar'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Übersicht Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ihre Aktivität',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mitglied seit ${_formatDate(stats.memberSince)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Gedenkseiten Statistik
              _buildStatCard(
                context,
                'Gedenkseiten',
                [
                  _StatItem(
                    'Gesamt',
                    '${stats.totalMemorials}',
                    Icons.favorite,
                    AppColors.accent,
                  ),
                  _StatItem(
                    'Veröffentlicht',
                    '${stats.publishedMemorials}',
                    Icons.check_circle,
                    AppColors.success,
                  ),
                  _StatItem(
                    'Entwürfe',
                    '${stats.totalMemorials - stats.publishedMemorials}',
                    Icons.edit,
                    AppColors.warning,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Interaktions Statistik
              _buildStatCard(
                context,
                'Interaktionen',
                [
                  _StatItem(
                    'Besucher',
                    '${stats.totalViews}',
                    Icons.visibility,
                    AppColors.primary,
                  ),
                  _StatItem(
                    'Beileidsbekundungen',
                    '${stats.totalCondolences}',
                    Icons.message,
                    AppColors.info,
                  ),
                  _StatItem(
                    'Gruppen',
                    '${stats.groupMemberships}',
                    Icons.group,
                    AppColors.secondary,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Durchschnitte
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Durchschnitte',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      _buildAverageRow(
                        'Views pro Gedenkseite',
                        stats.totalMemorials > 0
                            ? (stats.totalViews / stats.totalMemorials)
                                .toStringAsFixed(1)
                            : '0',
                        Icons.trending_up,
                      ),
                      const Divider(),
                      _buildAverageRow(
                        'Beileidsbekundungen pro Seite',
                        stats.publishedMemorials > 0
                            ? (stats.totalCondolences /
                                    stats.publishedMemorials)
                                .toStringAsFixed(1)
                            : '0',
                        Icons.favorite_border,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Achievements
              _buildAchievementsCard(context, stats),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, String title, List<_StatItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: items.map((item) {
                return Expanded(
                  child: _buildStatItem(item),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(_StatItem item) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: item.color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          item.value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: item.color,
          ),
        ),
        Text(
          item.label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAverageRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard(BuildContext context, ProfileStatistics stats) {
    final achievements = <Map<String, dynamic>>[];

    if (stats.totalMemorials >= 1) {
      achievements.add({
        'title': 'Erste Gedenkseite',
        'description': 'Ihre erste Gedenkseite erstellt',
        'icon': Icons.star,
        'color': AppColors.accent,
      });
    }

    if (stats.publishedMemorials >= 1) {
      achievements.add({
        'title': 'Veröffentlicht',
        'description': 'Erste Gedenkseite veröffentlicht',
        'icon': Icons.publish,
        'color': AppColors.success,
      });
    }

    if (stats.totalViews >= 100) {
      achievements.add({
        'title': '100 Besucher',
        'description': '100 Menschen haben Ihre Seiten besucht',
        'icon': Icons.visibility,
        'color': AppColors.primary,
      });
    }

    if (stats.totalCondolences >= 10) {
      achievements.add({
        'title': '10 Beileidsbekundungen',
        'description': 'Ihre Seiten haben Menschen berührt',
        'icon': Icons.favorite,
        'color': AppColors.error,
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Erfolge',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (achievements.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.emoji_events,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Noch keine Erfolge',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...achievements.map((achievement) {
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (achievement['color'] as Color).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      achievement['icon'] as IconData,
                      color: achievement['color'] as Color,
                    ),
                  ),
                  title: Text(
                    achievement['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(achievement['description'] as String),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember'
    ];
    return '${date.day}. ${months[date.month - 1]} ${date.year}';
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem(this.label, this.value, this.icon, this.color);
}
