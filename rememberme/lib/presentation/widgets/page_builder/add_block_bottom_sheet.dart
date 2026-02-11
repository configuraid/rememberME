import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:rememberme/data/models/content_block_model.dart';
import 'package:rememberme/core/constants/app_colors.dart';

/// Kategorien für Block-Typen
enum _BlockCategory {
  media,
  textStructure,
}

/// Block-Typ mit Kategorie und emotionalen Texten
class _BlockOption {
  final ContentBlockType type;
  final String label;
  final IconData iosIcon;
  final IconData androidIcon;
  final _BlockCategory category;

  const _BlockOption({
    required this.type,
    required this.label,
    required this.iosIcon,
    required this.androidIcon,
    required this.category,
  });
}

/// Alle verfügbaren Block-Optionen
const List<_BlockOption> _blockOptions = [
  // === MEDIEN ===
  _BlockOption(
    type: ContentBlockType.image,
    label: 'Foto',
    iosIcon: CupertinoIcons.photo,
    androidIcon: Icons.image_outlined,
    category: _BlockCategory.media,
  ),
  _BlockOption(
    type: ContentBlockType.gallery,
    label: 'Galerie',
    iosIcon: CupertinoIcons.photo_on_rectangle,
    androidIcon: Icons.photo_library_outlined,
    category: _BlockCategory.media,
  ),
  _BlockOption(
    type: ContentBlockType.video,
    label: 'Video',
    iosIcon: CupertinoIcons.videocam,
    androidIcon: Icons.videocam_outlined,
    category: _BlockCategory.media,
  ),
  _BlockOption(
    type: ContentBlockType.audio,
    label: 'Stimme',
    iosIcon: CupertinoIcons.mic,
    androidIcon: Icons.mic_outlined,
    category: _BlockCategory.media,
  ),

  // === TEXT & STRUKTUR ===
  _BlockOption(
    type: ContentBlockType.header,
    label: 'Überschrift',
    iosIcon: CupertinoIcons.textformat_size,
    androidIcon: Icons.title_rounded,
    category: _BlockCategory.textStructure,
  ),
  _BlockOption(
    type: ContentBlockType.text,
    label: 'Geschichte',
    iosIcon: CupertinoIcons.text_alignleft,
    androidIcon: Icons.notes_rounded,
    category: _BlockCategory.textStructure,
  ),
  _BlockOption(
    type: ContentBlockType.quote,
    label: 'Zitat',
    iosIcon: CupertinoIcons.quote_bubble,
    androidIcon: Icons.format_quote_rounded,
    category: _BlockCategory.textStructure,
  ),
  _BlockOption(
    type: ContentBlockType.imageText,
    label: 'Foto & Text',
    iosIcon: CupertinoIcons.doc_richtext,
    androidIcon: Icons.article_outlined,
    category: _BlockCategory.textStructure,
  ),
  _BlockOption(
    type: ContentBlockType.timeline,
    label: 'Lebensweg',
    iosIcon: CupertinoIcons.time,
    androidIcon: Icons.timeline_rounded,
    category: _BlockCategory.textStructure,
  ),
];

class AddBlockBottomSheet extends StatelessWidget {
  final Function(ContentBlockType) onBlockTypeSelected;

  const AddBlockBottomSheet({
    super.key,
    required this.onBlockTypeSelected,
  });

  List<_BlockOption> _getByCategory(_BlockCategory category) {
    return _blockOptions.where((o) => o.category == category).toList();
  }

  void _onSelect(BuildContext context, ContentBlockType type) {
    HapticFeedback.selectionClick();
    onBlockTypeSelected(type);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      return _buildIOSSheet(context, isDark);
    } else {
      return _buildAndroidSheet(context, isDark);
    }
  }

  // ========================================
  // iOS Implementation
  // ========================================
  Widget _buildIOSSheet(BuildContext context, bool isDark) {
    final mediaOptions = _getByCategory(_BlockCategory.media);
    final textOptions = _getByCategory(_BlockCategory.textStructure);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Was möchtest du hinzufügen?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                  fontFamily: '.SF Pro Display',
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medien Section
                  _buildIOSSectionHeader('Medien', isDark),
                  const SizedBox(height: 12),
                  _buildIOSRow(context, mediaOptions, isDark),

                  const SizedBox(height: 28),

                  // Text & Struktur Section
                  _buildIOSSectionHeader('Text & Struktur', isDark),
                  const SizedBox(height: 12),
                  _buildIOSWrap(context, textOptions, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white38 : Colors.black38,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildIOSRow(
    BuildContext context,
    List<_BlockOption> options,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: options.map((option) {
        return _buildIOSTile(context, option, isDark);
      }).toList(),
    );
  }

  Widget _buildIOSWrap(
    BuildContext context,
    List<_BlockOption> options,
    bool isDark,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tileWidth = (screenWidth - 32) / 4;

    return Wrap(
      spacing: 0,
      runSpacing: 20,
      children: options.map((option) {
        return SizedBox(
          width: tileWidth,
          child: _buildIOSTile(context, option, isDark, fixedWidth: false),
        );
      }).toList(),
    );
  }

  Widget _buildIOSTile(
    BuildContext context,
    _BlockOption option,
    bool isDark, {
    bool fixedWidth = true,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: () => _onSelect(context, option.type),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              option.iosIcon,
              size: 26,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            option.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ========================================
  // Android Implementation
  // ========================================
  Widget _buildAndroidSheet(BuildContext context, bool isDark) {
    final mediaOptions = _getByCategory(_BlockCategory.media);
    final textOptions = _getByCategory(_BlockCategory.textStructure);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Text(
                'Was möchtest du hinzufügen?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medien Section
                  _buildAndroidSectionHeader('Medien', isDark),
                  const SizedBox(height: 16),
                  _buildAndroidRow(context, mediaOptions, isDark),

                  const SizedBox(height: 32),

                  // Text & Struktur Section
                  _buildAndroidSectionHeader('Text & Struktur', isDark),
                  const SizedBox(height: 16),
                  _buildAndroidWrap(context, textOptions, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white54 : Colors.black54,
        letterSpacing: 0.25,
      ),
    );
  }

  Widget _buildAndroidRow(
    BuildContext context,
    List<_BlockOption> options,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options.map((option) {
        return _buildAndroidTile(context, option, isDark);
      }).toList(),
    );
  }

  Widget _buildAndroidWrap(
    BuildContext context,
    List<_BlockOption> options,
    bool isDark,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tileWidth = (screenWidth - 48) / 4;

    return Wrap(
      spacing: 0,
      runSpacing: 20,
      children: options.map((option) {
        return SizedBox(
          width: tileWidth,
          child: _buildAndroidTile(context, option, isDark),
        );
      }).toList(),
    );
  }

  Widget _buildAndroidTile(
    BuildContext context,
    _BlockOption option,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => _onSelect(context, option.type),
      borderRadius: BorderRadius.circular(16),
      splashColor:
          (isDark ? AppColors.accent : AppColors.primary).withOpacity(0.1),
      highlightColor:
          (isDark ? AppColors.accent : AppColors.primary).withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.accent.withOpacity(0.12)
                    : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                option.androidIcon,
                size: 26,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              option.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
