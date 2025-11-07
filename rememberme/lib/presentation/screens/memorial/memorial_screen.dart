import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/memorial/memorial_bloc.dart';
import '../../../business_logic/memorial/memorial_event.dart';
import '../../../business_logic/memorial/memorial_state.dart';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../data/models/memorial_page_model.dart' hide MemorialStatus;
import '../../../data/models/content_block_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import 'memorial_create_screen.dart';

class MemorialDetailScreen extends StatelessWidget {
  final MemorialPageModel? memorial;

  const MemorialDetailScreen({super.key, this.memorial});

  @override
  Widget build(BuildContext context) {
    // 🔥 WICHTIG: BlocListener für Navigation nach Löschen
    return BlocListener<MemorialBloc, MemorialState>(
      listener: (context, state) {
        print('📊 MemorialDetailScreen - State geändert: ${state.status}');
        print('📊 Anzahl Memorials: ${state.memorials.length}');

        // Nach erfolgreichem Löschen: Prüfe ob keine Memorials mehr vorhanden
        if (state.status == MemorialStatus.success) {
          if (state.memorials.isEmpty) {
            print('✅ Letztes Memorial gelöscht - navigiere zurück zum Root');
            // Navigiere zurück zur Dashboard-Root (Create Screen wird automatisch angezeigt)
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            print(
                '✅ Memorial gelöscht, aber noch ${state.memorials.length} vorhanden');
            // Navigiere nur einen Screen zurück (zum Dashboard)
            Navigator.of(context).pop();
          }
        }

        // Zeige Fehlermeldungen an
        if (state.hasError && state.errorMessage != null) {
          print('❌ Fehler: ${state.errorMessage}');
          _showErrorSnackBar(context, state.errorMessage!);
        }
      },
      child: BlocBuilder<MemorialBloc, MemorialState>(
        builder: (context, state) {
          print('🏗️ MemorialDetailScreen wird gebaut...');
          print('🏗️ Memorial Parameter: ${memorial?.name ?? "null"}');
          print('🏗️ State Memorials: ${state.memorials.length}');
          print('🏗️ State Status: ${state.status}');

          // Wenn kein Memorial übergeben wurde und keine Memorials geladen sind
          // -> Zeige Create Screen
          if (memorial == null && state.memorials.isEmpty) {
            print('🎨 Kein Memorial vorhanden - zeige Create Screen');

            // Optional: Lade Memorials des Users, falls noch nicht geschehen
            if (state.status == MemorialStatus.initial) {
              print('🔄 Status ist initial - lade Memorials');
              final userId = context.read<AuthBloc>().state.user?.id;
              if (userId != null) {
                context.read<MemorialBloc>().add(MemorialLoadRequested(userId));
              }
            }

            // Wenn gerade lädt, zeige Loading
            if (state.isLoading && state.status == MemorialStatus.loading) {
              print('⏳ Lade Memorials...');
              return _buildLoadingScreen();
            }

            // Zeige Create Screen wenn definitiv keine Memorials vorhanden
            print('✨ Zeige MemorialCreateScreen');
            return const MemorialCreateScreen();
          }

          // Memorial-Daten ermitteln
          final memorialData = memorial ??
              state.selectedMemorial ??
              (ModalRoute.of(context)?.settings.arguments
                  as MemorialPageModel?);

          // Falls immer noch kein Memorial-Data vorhanden
          if (memorialData == null) {
            print('⚠️ Keine Memorial-Daten gefunden - zeige Create Screen');
            return const MemorialCreateScreen();
          }

          print('📄 Zeige Detail-Screen für: ${memorialData.name}');

          // Normal Detail-Screen anzeigen
          if (Platform.isIOS) {
            return _buildIOSView(context, memorialData);
          }
          return _buildAndroidView(context, memorialData);
        },
      ),
    );
  }

  // Helper-Methode für Fehler-Anzeige
  void _showErrorSnackBar(BuildContext context, String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Fehler'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Loading Screen während Memorials geladen werden
  Widget _buildLoadingScreen() {
    return Platform.isIOS
        ? const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text('Meine Gedenkseite'),
            ),
            child: Center(
              child: CupertinoActivityIndicator(radius: 20),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text('Meine Gedenkseite'),
              elevation: 0,
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
  }

  // ===== ANDROID (Material Design) =====
  Widget _buildAndroidView(BuildContext context, MemorialPageModel memorial) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Gedenkseite'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          print('🔄 Pull-to-Refresh: Lade Memorial neu');
          // Reload memorial
          context.read<MemorialBloc>().add(
                MemorialDetailLoadRequested(memorial.id),
              );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header mit Profilbild
              _buildHeader(context, memorial),

              // Hauptaktionen
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bearbeiten Button
                    ElevatedButton.icon(
                      onPressed: () =>
                          _navigateToPageBuilder(context, memorial),
                      icon: const Icon(Icons.edit),
                      label: const Text(
                        'Gedenkseite bearbeiten',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Vorschau Button
                    OutlinedButton.icon(
                      onPressed: () => _showPreview(context, memorial),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text(
                        'Vorschau ansehen',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Content Preview
                    _buildContentPreview(context, memorial),

                    const SizedBox(height: 24),

                    // Weitere Aktionen
                    _buildActionsSection(context, memorial),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: memorial.isPublished
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _publishMemorial(context, memorial),
              icon: const Icon(Icons.publish),
              label: const Text('Veröffentlichen'),
              backgroundColor: AppColors.success,
            ),
    );
  }

  // ===== iOS (Cupertino Design) =====
  Widget _buildIOSView(BuildContext context, MemorialPageModel memorial) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Meine Gedenkseite'),
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                print('🔄 Pull-to-Refresh: Lade Memorial neu');
                context.read<MemorialBloc>().add(
                      MemorialDetailLoadRequested(memorial.id),
                    );
              },
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Header mit Profilbild
                  _buildHeader(context, memorial),

                  // Hauptaktionen
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Bearbeiten Button
                        CupertinoButton.filled(
                          onPressed: () =>
                              _navigateToPageBuilder(context, memorial),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.pencil, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Gedenkseite bearbeiten',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Vorschau Button
                        CupertinoButton(
                          onPressed: () => _showPreview(context, memorial),
                          color:
                              CupertinoColors.systemGrey6.resolveFrom(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.eye,
                                size: 20,
                                color:
                                    CupertinoColors.label.resolveFrom(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Vorschau ansehen',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: CupertinoColors.label
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Content Preview
                        _buildContentPreview(context, memorial),

                        const SizedBox(height: 24),

                        // Weitere Aktionen
                        _buildActionsSection(context, memorial),

                        const SizedBox(height: 24),

                        // Veröffentlichen Button (wenn noch nicht veröffentlicht)
                        if (!memorial.isPublished)
                          CupertinoButton.filled(
                            onPressed: () =>
                                _publishMemorial(context, memorial),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.globe, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Veröffentlichen',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== GEMEINSAME WIDGETS =====

  Widget _buildHeader(BuildContext context, MemorialPageModel memorial) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Profilbild
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.1),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: memorial.profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      memorial.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.favorite, size: 48),
                    ),
                  )
                : const Icon(
                    Icons.favorite,
                    size: 48,
                    color: AppColors.accent,
                  ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            memorial.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Lebensdaten
          Text(
            memorial.lifespan,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          // Status Badge
          _buildStatusChip(memorial),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusChip(MemorialPageModel memorial) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: memorial.isPublished
            ? AppColors.success.withOpacity(0.15)
            : AppColors.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            memorial.isPublished ? Icons.check_circle : Icons.edit,
            size: 18,
            color: memorial.isPublished ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            memorial.isPublished ? 'Veröffentlicht' : 'Entwurf',
            style: TextStyle(
              color:
                  memorial.isPublished ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview(
      BuildContext context, MemorialPageModel memorial) {
    if (memorial.contentBlocks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Platform.isIOS
              ? CupertinoColors.systemGrey6.resolveFrom(context)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Noch keine Inhalte',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Füge Texte, Bilder oder Videos hinzu',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inhalte',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...memorial.sortedContentBlocks.take(3).map((block) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Platform.isIOS
                  ? CupertinoColors.systemBackground.resolveFrom(context)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Platform.isIOS
                    ? CupertinoColors.separator.resolveFrom(context)
                    : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getBlockIcon(block.type),
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getBlockTypeName(block.type),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (memorial.contentBlocks.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${memorial.contentBlocks.length - 3} weitere',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionsSection(
      BuildContext context, MemorialPageModel memorial) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weitere Optionen',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          context,
          Icons.share_outlined,
          'Teilen',
          'QR-Code oder Link teilen',
          () => _shareMemorial(context, memorial),
        ),
        _buildActionTile(
          context,
          Icons.delete_outline,
          'Löschen',
          'Gedenkseite entfernen',
          () => _showDeleteDialog(context, memorial.id),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : Colors.grey[700]!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Platform.isIOS
              ? CupertinoColors.systemBackground.resolveFrom(context)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Platform.isIOS
                ? CupertinoColors.separator.resolveFrom(context)
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Platform.isIOS
                  ? CupertinoIcons.chevron_right
                  : Icons.chevron_right,
              color: Colors.grey[400],
              size: Platform.isIOS ? 20 : 24,
            ),
          ],
        ),
      ),
    );
  }

  // ===== HILFSFUNKTIONEN =====

  IconData _getBlockIcon(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.text:
        return Icons.text_fields;
      case ContentBlockType.video:
        return Icons.videocam_outlined;
      case ContentBlockType.gallery:
        return Icons.photo_library_outlined;
      case ContentBlockType.image:
        return Icons.image_outlined;
      case ContentBlockType.quote:
        return Icons.format_quote;
      default:
        return Icons.article_outlined;
    }
  }

  String _getBlockTypeName(ContentBlockType type) {
    switch (type) {
      case ContentBlockType.text:
        return 'Text';
      case ContentBlockType.video:
        return 'Video';
      case ContentBlockType.gallery:
        return 'Galerie';
      case ContentBlockType.image:
        return 'Bild';
      case ContentBlockType.quote:
        return 'Zitat';
      default:
        return type.toString().split('.').last;
    }
  }

  // ===== AKTIONEN =====

  void _navigateToPageBuilder(
      BuildContext context, MemorialPageModel memorial) {
    print('📝 Navigiere zum PageBuilder für: ${memorial.name}');
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.pageBuilder,
      arguments: memorial,
    );
  }

  void _showPreview(BuildContext context, MemorialPageModel memorial) {
    print('👁️ Zeige Vorschau für: ${memorial.name}');
    final snackBar = SnackBar(
      content: const Text('Vorschau wird geladen...'),
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _publishMemorial(BuildContext context, MemorialPageModel memorial) {
    print('🌐 Veröffentlichungs-Dialog für: ${memorial.name}');

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Veröffentlichen'),
          content: const Text(
            'Möchtest du deine Gedenkseite jetzt veröffentlichen? Sie wird dann für andere sichtbar.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                print('❌ Veröffentlichung abgebrochen');
                Navigator.of(ctx).pop();
              },
              child: const Text('Abbrechen'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                print('✅ Veröffentlichung bestätigt');
                context
                    .read<MemorialBloc>()
                    .add(MemorialPublishRequested(memorial.id));
                Navigator.of(ctx).pop();
              },
              isDefaultAction: true,
              child: const Text('Veröffentlichen'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Veröffentlichen'),
          content: const Text(
            'Möchtest du deine Gedenkseite jetzt veröffentlichen? Sie wird dann für andere sichtbar.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('❌ Veröffentlichung abgebrochen');
                Navigator.of(ctx).pop();
              },
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                print('✅ Veröffentlichung bestätigt');
                context
                    .read<MemorialBloc>()
                    .add(MemorialPublishRequested(memorial.id));
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: const Text('Veröffentlichen'),
            ),
          ],
        ),
      );
    }
  }

  void _shareMemorial(BuildContext context, MemorialPageModel memorial) {
    print('🔗 Teilen-Funktion für: ${memorial.name}');
    final snackBar = SnackBar(
      content: const Text('Teilen-Funktion kommt bald...'),
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showDeleteDialog(BuildContext context, String memorialId) {
    print('🗑️ Delete Dialog geöffnet für Memorial-ID: $memorialId');

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Löschen bestätigen'),
          content: const Text(AppStrings.confirmDelete),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                print('❌ Löschen abgebrochen');
                Navigator.of(ctx).pop();
              },
              child: const Text('Abbrechen'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                print(
                    '🗑️ Löschung bestätigt, sende MemorialDeleteRequested Event');
                context
                    .read<MemorialBloc>()
                    .add(MemorialDeleteRequested(memorialId));
                Navigator.of(ctx).pop(); // 🔥 NUR den Dialog schließen
                print(
                    '🗑️ Dialog geschlossen - BlocListener kümmert sich um Navigation');
                // KEIN Navigator.of(context).pop() hier!
                // Der BlocListener übernimmt die Navigation nach erfolgreichem Löschen
              },
              isDestructiveAction: true,
              child: const Text('Löschen'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Löschen bestätigen'),
          content: const Text(AppStrings.confirmDelete),
          actions: [
            TextButton(
              onPressed: () {
                print('❌ Löschen abgebrochen');
                Navigator.of(ctx).pop();
              },
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                print(
                    '🗑️ Löschung bestätigt, sende MemorialDeleteRequested Event');
                context
                    .read<MemorialBloc>()
                    .add(MemorialDeleteRequested(memorialId));
                Navigator.of(ctx).pop(); // 🔥 NUR den Dialog schließen
                print(
                    '🗑️ Dialog geschlossen - BlocListener kümmert sich um Navigation');
                // KEIN Navigator.of(context).pop() hier!
                // Der BlocListener übernimmt die Navigation nach erfolgreichem Löschen
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(AppStrings.delete),
            ),
          ],
        ),
      );
    }
  }
}
