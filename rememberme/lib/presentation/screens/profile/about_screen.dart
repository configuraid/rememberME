import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Über die App'),
      ),
      body: ListView(
        children: [
          // App Logo & Name
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Digital Memorial',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version $_version',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const Divider(),

          // Info Sections
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Was ist Digital Memorial?'),
            subtitle: const Text(
              'Eine würdevolle Plattform für digitale Gedenkseiten',
            ),
            onTap: () => _showInfoDialog(
              context,
              'Über Digital Memorial',
              'Digital Memorial ermöglicht es Ihnen, würdevolle digitale Gedenkseiten für verstorbene Angehörige und Freunde zu erstellen und zu teilen. Bewahren Sie Erinnerungen, teilen Sie Geschichten und ermöglichen Sie anderen, Beileid auszudrücken.',
            ),
          ),

          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Nutzungsbedingungen'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchUrl('https://example.com/terms'),
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Datenschutzerklärung'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchUrl('https://example.com/privacy'),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Website'),
            subtitle: const Text('www.digital-memorial.com'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl('https://www.digital-memorial.com'),
          ),

          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Kontakt'),
            subtitle: const Text('support@digital-memorial.com'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launchUrl('mailto:support@digital-memorial.com'),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Open Source Lizenzen'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Digital Memorial',
              applicationVersion: _version,
              applicationIcon: const Icon(
                Icons.favorite,
                size: 48,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Social Media
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  'Folgen Sie uns',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      Icons.facebook,
                      () => _launchUrl('https://facebook.com'),
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      Icons.wordpress,
                      () => _launchUrl('https://twitter.com'),
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      Icons.camera_alt,
                      () => _launchUrl('https://instagram.com'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Copyright
          Center(
            child: Text(
              '© 2024 Digital Memorial\nMade with ❤️',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konnte $urlString nicht öffnen'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
