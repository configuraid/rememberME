import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/data/models/content_block_model.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'dart:io';

class ContentBlockWidget extends StatelessWidget {
  final ContentBlock block;
  final bool isSelected;
  final bool isPreview;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final Function(String key, dynamic value) onContentChanged;

  const ContentBlockWidget({
    super.key,
    required this.block,
    required this.isSelected,
    this.isPreview = false,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isPreview) {
      return _buildPreviewContent(context);
    }

    // Für Android: Material Design 3
    if (Platform.isAndroid) {
      return _buildAndroidContent(context);
    }

    // Für iOS: Ursprüngliches Design
    return _buildIOSContent(context);
  }

  Widget _buildAndroidContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: isSelected ? 3 : 1,
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        shadowColor: isDark ? AppColors.shadowDark : AppColors.shadow,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          splashColor: colorScheme.primary.withOpacity(0.1),
          highlightColor: colorScheme.primary.withOpacity(0.05),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : (isDark
                        ? AppColors.cardBorderDark
                        : AppColors.greyLighter),
                width: isSelected ? 2.5 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with type and actions (ohne Edit-Button)
                _buildAndroidHeader(context),

                // Divider
                Divider(
                  height: 1,
                  color:
                      isDark ? AppColors.cardBorderDark : AppColors.greyLighter,
                  thickness: 1,
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildContent(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: isSelected ? 4 : 1,
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? AppColors.interactive
                    : (isDark ? AppColors.borderDark : AppColors.greyLighter),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIOSHeader(context),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildContent(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Drag Handle mit Theme-Farben
          Icon(
            Icons.drag_indicator_rounded,
            color: isDark ? AppColors.greyDark : AppColors.greyLight,
            size: 24,
          ),
          const SizedBox(width: 12),

          // Icon & Type mit Chip-Design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : (isDark ? AppColors.cardBorderDark : AppColors.greyLighter),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  BlockTypeInfo.getIcon(block.type),
                  size: 18,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : (isDark
                          ? AppColors.greyLighter
                          : AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Text(
                  BlockTypeInfo.getTitle(block.type),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : (isDark
                            ? AppColors.greyLighter
                            : AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          _buildAndroidIconButton(
            context,
            icon: Icons.content_copy_rounded,
            onPressed: onDuplicate,
            tooltip: AppStrings.duplicate,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          _buildAndroidIconButton(
            context,
            icon: Icons.delete_outline_rounded,
            onPressed: onDelete,
            tooltip: AppStrings.delete,
            color: isDark ? AppColors.errorLight : AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildIOSHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.line_horizontal_3,
            color: isDark ? AppColors.grey : AppColors.greyLight,
            size: 20,
          ),
          const SizedBox(width: 8),
          Icon(
            BlockTypeInfo.getIcon(block.type),
            size: 20,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              BlockTypeInfo.getTitle(block.type),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.greyLighter : AppColors.textSecondary,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: onDuplicate,
            child: Icon(
              CupertinoIcons.doc_on_doc,
              size: 18,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: onDelete,
            child: const Icon(
              CupertinoIcons.trash,
              size: 18,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (block.type) {
      case ContentBlockType.header:
        return _buildHeaderContent(context);
      case ContentBlockType.text:
        return _buildTextContent(context);
      case ContentBlockType.image:
        return _buildImageContent(context);
      case ContentBlockType.gallery:
        return _buildGalleryContent(context);
      case ContentBlockType.quote:
        return _buildQuoteContent(context);
      case ContentBlockType.divider:
        return _buildDividerContent(context);
      case ContentBlockType.video:
        return _buildVideoContent(context);
    }
  }

  Widget _buildPreviewContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _buildContent(context),
    );
  }

  // ===== CONTENT RENDERERS =====

  Widget _buildHeaderContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final text = block.getContent('text', AppStrings.headerPlaceholder);
    final level = block.getContent('level', 1);
    final align = block.getContent('align', 'center');
    final colorHex = block.getContent('color', '#000000');

    double fontSize = level == 1
        ? 32
        : level == 2
            ? 24
            : 20;

    // Theme-bewusste Farben
    Color textColor = _hexToColor(colorHex);
    if (colorHex == '#000000') {
      textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.5,
      ),
      textAlign: align == 'center'
          ? TextAlign.center
          : align == 'right'
              ? TextAlign.right
              : TextAlign.left,
    );
  }

  Widget _buildTextContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final text = block.getContent('text', AppStrings.textPlaceholder);
    final align = block.getContent('align', 'left');
    final fontSize = block.getContent('fontSize', 16.0);
    final colorHex = block.getContent('color', '#333333');

    // Theme-bewusste Farben
    Color textColor = _hexToColor(colorHex);
    if (colorHex == '#333333') {
      textColor = isDark ? AppColors.greyLighter : AppColors.textSecondary;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: textColor,
        height: 1.6,
      ),
      textAlign: align == 'center'
          ? TextAlign.center
          : align == 'right'
              ? TextAlign.right
              : TextAlign.left,
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final url = block.getContent('url', '');
    final caption = block.getContent('caption', '');

    if (url.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBorderDark : AppColors.greyLighter,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDarkLight : AppColors.greyLighter,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: isDark ? AppColors.greyDark : AppColors.greyLight,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.uploadImage,
              style: TextStyle(
                color: isDark ? AppColors.grey : AppColors.greyDark,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.cardBorderDark : AppColors.greyLighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.broken_image_outlined,
                size: 64,
                color: isDark ? AppColors.greyDark : AppColors.greyLight,
              ),
            ),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            caption,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.grey : AppColors.greyDark,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildGalleryContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final images = block.getContent<List>('images', []);
    final columns = block.getContent('columns', 3);

    if (images.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBorderDark : AppColors.greyLighter,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDarkLight : AppColors.greyLighter,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: isDark ? AppColors.greyDark : AppColors.greyLight,
            ),
            const SizedBox(height: 12),
            Text(
              '${AppStrings.galleryLabel} (${images.length}${AppStrings.imagesCount})',
              style: TextStyle(
                color: isDark ? AppColors.grey : AppColors.greyDark,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.cardBorderDark : AppColors.greyLighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.broken_image_outlined,
                color: isDark ? AppColors.greyDark : AppColors.greyLight,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuoteContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final text = block.getContent('text', AppStrings.quotePlaceholder);
    final author = block.getContent('author', '');
    final colorHex = block.getContent('color', '#666666');

    Color quoteColor = _hexToColor(colorHex);
    if (colorHex == '#666666') {
      quoteColor = isDark ? AppColors.info : AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBorderDark : AppColors.greyLighter,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: quoteColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"$text"',
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.greyLighter : AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          if (author.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '— $author',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.grey : AppColors.greyDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDividerContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colorHex = block.getContent('color', '#E0E0E0');
    final thickness = block.getContent('thickness', 1.0);

    Color dividerColor = _hexToColor(colorHex);
    if (colorHex == '#E0E0E0') {
      dividerColor = isDark ? AppColors.borderDarkLight : AppColors.greyLighter;
    }

    return Container(
      height: thickness,
      decoration: BoxDecoration(
        color: dividerColor,
        borderRadius: BorderRadius.circular(thickness / 2),
      ),
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final url = block.getContent('url', '');
    final caption = block.getContent('caption', '');
    final autoplay = block.getContent('autoplay', false);

    if (url.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBorderDark : AppColors.greyLighter,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDarkLight : AppColors.greyLighter,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
              size: 64,
              color: isDark ? AppColors.greyDark : AppColors.greyLight,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.addVideo,
              style: TextStyle(
                color: isDark ? AppColors.grey : AppColors.greyDark,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDarkSecondary
                    : AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  size: 64,
                  color: AppColors.textLight.withOpacity(0.9),
                ),
              ),
            ),
            // ============================================================
            // NEU: Autoplay Badge
            // ============================================================
            if (autoplay)
              Positioned(
                top: 12,
                right: 12,
                child: _buildAutoplayBadge(context, isDark),
              ),
          ],
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            caption,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.grey : AppColors.greyDark,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildAutoplayBadge(BuildContext context, bool isDark) {
    if (Platform.isIOS) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.accent : AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowDark,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.play_fill,
              size: 12,
              color: AppColors.textLight,
            ),
            const SizedBox(width: 4),
            Text(
              'Autoplay',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
                fontFamily: '.SF Pro Text',
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.success,
              AppColors.success.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_arrow_rounded,
              size: 14,
              color: AppColors.textLight,
            ),
            const SizedBox(width: 4),
            Text(
              'Autoplay',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
