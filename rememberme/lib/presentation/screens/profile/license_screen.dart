import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/license/license_bloc.dart';
import '../../../business_logic/license/license_state.dart';
import '../../../business_logic/license/license_event.dart';
import '../../../data/models/license_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/common/loading_indicator.dart';

class LicenseScreen extends StatelessWidget {
  const LicenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.license),
      ),
      body: BlocBuilder<LicenseBloc, LicenseState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const LoadingIndicator();
          }

          if (!state.hasLicense) {
            return const Center(child: Text('Keine Lizenz gefunden'));
          }

          final license = state.license!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lizenz-Typ Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: license.type == LicenseType.lifetime
                            ? [AppColors.accent, AppColors.accentLight]
                            : [AppColors.basicLicense, AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      license.type == LicenseType.lifetime
                          ? AppStrings.lifetimeLicense
                          : AppStrings.basicLicense,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Speicher-Info
                Text(AppStrings.storageUsed,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: license.storageUsedPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    license.storageUsedPercentage > 80
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${license.storageUsed.toStringAsFixed(2)} GB von ${license.storageLimit} GB genutzt',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 32),

                // Features
                _buildFeaturesList(context, license),

                if (license.type == LicenseType.basic) ...[
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _showUpgradeDialog(context, license),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(AppStrings.upgradeLicense),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context, LicenseModel license) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Features', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildFeatureItem(
                'Gedenkseiten',
                license.maxMemorials == -1
                    ? 'Unbegrenzt'
                    : '${license.maxMemorials}'),
            _buildFeatureItem(
                'Bilder',
                license.maxImages == -1
                    ? 'Unbegrenzt'
                    : '${license.maxImages}'),
            _buildFeatureItem(
                'Videos',
                license.maxVideos == -1
                    ? 'Unbegrenzt'
                    : license.maxVideos == 0
                        ? 'Nicht verfügbar'
                        : '${license.maxVideos}'),
            _buildFeatureItem(
                'Content-Blöcke', '${license.availableContentBlocks.length}'),
            _buildFeatureItem('Gruppen-Kollaboration',
                license.canInviteMembers ? 'Ja' : 'Nein'),
            _buildFeatureItem(
                'Custom Domain', license.canUseCustomDomain ? 'Ja' : 'Nein'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, LicenseModel license) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Auf Lifetime upgraden?'),
        content: const Text(
            'Schalten Sie alle Features frei für eine einmalige Zahlung von €399.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<LicenseBloc>().add(
                    LicenseUpgradeRequested(
                      userId: license.userId,
                      newType: LicenseType.lifetime,
                    ),
                  );
              Navigator.of(ctx).pop();
            },
            child: const Text('Upgraden'),
          ),
        ],
      ),
    );
  }
}
