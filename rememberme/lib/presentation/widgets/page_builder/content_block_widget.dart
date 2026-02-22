import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/data/models/content_block_model.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'dart:io';

class ContentBlockWidget extends StatefulWidget {
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
  State<ContentBlockWidget> createState() => _ContentBlockWidgetState();
}

class _ContentBlockWidgetState extends State<ContentBlockWidget> {
  // Gallery Slider
  int _gallerySliderIndex = 0;
  final PageController _galleryPageController =
      PageController(viewportFraction: 0.85);

  @override
  void dispose() {
    _galleryPageController.dispose();
    super.dispose();
  }

  /// Helper to get content with empty string check
  /// Returns placeholder if value is empty string
  String _getTextContent(String key, String placeholder) {
    final value = widget.block.getContent<String>(key, '');
    return value.isEmpty ? placeholder : value;
  }

  /// Check if text content is empty (for styling purposes)
  bool _isTextEmpty(String key) {
    final value = widget.block.getContent<String>(key, '');
    return value.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPreview) {
      return _buildPreviewContent(context);
    }

    if (Platform.isAndroid) {
      return _buildAndroidContent(context);
    }

    return _buildIOSContent(context);
  }

  Widget _buildAndroidContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: widget.isSelected ? 3 : 1,
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        shadowColor: isDark ? AppColors.shadowDark : AppColors.shadow,
        child: InkWell(
          onTap: widget.onEdit,
          borderRadius: BorderRadius.circular(16),
          splashColor:
              (isDark ? AppColors.accent : AppColors.primary).withOpacity(0.1),
          highlightColor:
              (isDark ? AppColors.accent : AppColors.primary).withOpacity(0.05),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.isSelected
                    ? (isDark ? AppColors.accent : AppColors.primary)
                    : (isDark ? AppColors.borderDark : AppColors.greyLighter),
                width: widget.isSelected ? 2.5 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAndroidHeader(context),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                  thickness: 1,
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

  Widget _buildIOSContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: widget.isSelected ? 4 : 1,
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        child: InkWell(
          onTap: widget.onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.isSelected
                    ? (isDark ? AppColors.accent : AppColors.primary)
                    : (isDark ? AppColors.borderDark : AppColors.greyLighter),
                width: widget.isSelected ? 2 : 1,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator_rounded,
            color: AppColors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? (isDark
                      ? AppColors.accent.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.1))
                  : (isDark
                      ? AppColors.toastBackgroundDark
                      : AppColors.greyLighter),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  BlockTypeInfo.getIcon(widget.block.type),
                  size: 18,
                  color: widget.isSelected
                      ? (isDark ? AppColors.accent : AppColors.primary)
                      : AppColors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  BlockTypeInfo.getTitle(widget.block.type),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isSelected
                        ? (isDark ? AppColors.accent : AppColors.primary)
                        : AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildAndroidIconButton(
            context,
            icon: Icons.content_copy_rounded,
            onPressed: widget.onDuplicate,
            tooltip: AppStrings.duplicate,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          _buildAndroidIconButton(
            context,
            icon: Icons.delete_outline_rounded,
            onPressed: widget.onDelete,
            tooltip: AppStrings.delete,
            color: AppColors.error,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            color: AppColors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Icon(
            BlockTypeInfo.getIcon(widget.block.type),
            size: 20,
            color: isDark ? AppColors.accent : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              BlockTypeInfo.getTitle(widget.block.type),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: widget.onDuplicate,
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
            onPressed: widget.onDelete,
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
    switch (widget.block.type) {
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
      case ContentBlockType.video:
        return _buildVideoContent(context);
      case ContentBlockType.audio:
        return _buildAudioContent(context);
      case ContentBlockType.imageText:
        return _buildImageTextContent(context);
      case ContentBlockType.timeline:
        return _buildTimelineContent(context);
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

    final text = _getTextContent('text', 'Überschrift eingeben');
    final isEmpty = _isTextEmpty('text');
    final level = widget.block.getContent('level', 1);
    final align = widget.block.getContent('align', 'center');
    final colorHex = widget.block.getContent('color', '#000000');

    double fontSize = level == 1
        ? 32
        : level == 2
            ? 24
            : 20;

    Color textColor;
    if (isEmpty) {
      textColor = AppColors.grey;
    } else if (colorHex == '#000000') {
      textColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    } else {
      textColor = _hexToColor(colorHex);
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.5,
        fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
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

    final text = _getTextContent('text', 'Text eingeben...');
    final isEmpty = _isTextEmpty('text');
    final align = widget.block.getContent('align', 'left');
    final fontSize = widget.block.getContent('fontSize', 16.0);
    final colorHex = widget.block.getContent('color', '#333333');

    Color textColor;
    if (isEmpty) {
      textColor = AppColors.grey;
    } else if (colorHex == '#333333') {
      textColor = isDark ? AppColors.textLight : AppColors.textSecondary;
    } else {
      textColor = _hexToColor(colorHex);
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: textColor,
        height: 1.6,
        fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
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

    final url = widget.block.getContent('url', '');
    final caption = widget.block.getContent('caption', '');
    final description = widget.block.getContent('description', '');

    if (url.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.uploadImage,
              style: TextStyle(
                color: AppColors.grey,
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
                color: isDark
                    ? AppColors.toastBackgroundDark
                    : AppColors.greyLighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.broken_image_outlined,
                size: 64,
                color: AppColors.grey,
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
              color: AppColors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey.withOpacity(0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildGalleryContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final images = widget.block.getContent<List>('images', []);
    final columns = widget.block.getContent('columns', 3);
    final displayMode = widget.block.getContent('displayMode', 'grid');

    // Leerer Zustand
    if (images.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              '${AppStrings.galleryLabel} (${images.length}${AppStrings.imagesCount})',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Grid-Modus
    if (displayMode == 'grid') {
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
                  color: isDark
                      ? AppColors.toastBackgroundDark
                      : AppColors.greyLighter,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.grey,
                ),
              ),
            ),
          );
        },
      );
    }

    // Slider-Modus
    return _buildGallerySliderContent(images, isDark);
  }

  /// Slider/Carousel-Darstellung für Gallery
  Widget _buildGallerySliderContent(List images, bool isDark) {
    return Column(
      children: [
        // Slider Container
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _galleryPageController,
            onPageChanged: (index) {
              setState(() {
                _gallerySliderIndex = index;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Stack(
                  children: [
                    // Bild
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.toastBackgroundDark
                                  : AppColors.greyLighter,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? AppColors.accent : AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.toastBackgroundDark
                                : AppColors.greyLighter,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.broken_image_rounded,
                            size: 48,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ),
                    // Bild-Nummer Badge
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${index + 1}/${images.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            images.length,
            (index) => GestureDetector(
              onTap: () {
                _galleryPageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _gallerySliderIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _gallerySliderIndex == index
                      ? (isDark ? AppColors.accent : AppColors.primary)
                      : (isDark
                          ? AppColors.accent.withOpacity(0.3)
                          : AppColors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final text = _getTextContent('text', 'Zitat eingeben...');
    final isEmpty = _isTextEmpty('text');
    final author = widget.block.getContent('author', '');
    final colorHex = widget.block.getContent('color', '#666666');

    Color quoteColor = _hexToColor(colorHex);
    if (colorHex == '#666666') {
      quoteColor = isDark ? AppColors.accent : AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '"$text"',
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: isEmpty ? AppColors.grey : quoteColor,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          if (author.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '— $author',
              style: TextStyle(
                fontSize: 14,
                color: quoteColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final url = widget.block.getContent('url', '');
    final caption = widget.block.getContent('caption', '');
    final autoplay = widget.block.getContent('autoplay', false);
    final thumbnailUrl = widget.block.getContent('thumbnailUrl', '');

    if (url.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Platform.isIOS
                  ? CupertinoIcons.videocam
                  : Icons.play_circle_outline_rounded,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.addVideo,
              style: TextStyle(
                color: AppColors.grey,
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
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: thumbnailUrl.isNotEmpty
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Platform.isIOS
                                ? CupertinoIcons.video_camera_solid
                                : Icons.videocam_rounded,
                            size: 64,
                            color: AppColors.textLight.withOpacity(0.5),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Platform.isIOS
                              ? CupertinoIcons.video_camera_solid
                              : Icons.videocam_rounded,
                          size: 64,
                          color: AppColors.textLight.withOpacity(0.5),
                        ),
                      ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.backgroundDark.withOpacity(0.3),
                ),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Platform.isIOS
                          ? CupertinoIcons.play_fill
                          : Icons.play_arrow_rounded,
                      size: 32,
                      color: isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
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
              color: AppColors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

// ===== REPLACE the entire _buildAudioContent method in content_block_widget.dart =====

  Widget _buildAudioContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final url = widget.block.getContent('url', '');
    final title = widget.block.getContent('title', '');
    final description = widget.block.getContent('description', '');
    final duration = widget.block.getContent('duration', 0);
    final waveformData = widget.block.getContent<List>('waveformData', []);

    String formatDuration(int seconds) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    // Empty State
    if (url.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.accent.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Platform.isIOS
                    ? CupertinoIcons.music_note_2
                    : Icons.audio_file_rounded,
                size: 36,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Audiodatei auswählen',
              style: TextStyle(
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tippe zum Konfigurieren',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // Filled State
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.backgroundDarkElevated,
                  AppColors.backgroundDark,
                ]
              : [
                  AppColors.surface,
                  AppColors.greyLighter.withOpacity(0.5),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.accent, AppColors.accent.withOpacity(0.7)]
                        : [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8)
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Platform.isIOS
                      ? CupertinoIcons.music_note_2
                      : Icons.audio_file_rounded,
                  color: isDark ? AppColors.primary : AppColors.background,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Titel + Beschreibung + Dauer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isNotEmpty ? title : 'Audiodatei',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.grey,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Platform.isIOS
                              ? CupertinoIcons.clock
                              : Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatDuration(duration),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bereit Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Platform.isIOS
                          ? CupertinoIcons.checkmark_circle_fill
                          : Icons.check_circle,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bereit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Waveform Player Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark.withOpacity(0.5)
                  : AppColors.greyLighter.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.accent : AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Icon(
                    Platform.isIOS
                        ? CupertinoIcons.play_fill
                        : Icons.play_arrow_rounded,
                    color: isDark ? AppColors.primary : AppColors.background,
                    size: 24,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(
                        20,
                        (index) {
                          final heights = [
                            0.3,
                            0.5,
                            0.7,
                            0.4,
                            0.8,
                            0.6,
                            0.9,
                            0.5,
                            0.7,
                            0.4,
                            0.6,
                            0.8,
                            0.5,
                            0.7,
                            0.3,
                            0.6,
                            0.9,
                            0.4,
                            0.7,
                            0.5,
                          ];
                          final heightFactor = waveformData.isNotEmpty &&
                                  index < waveformData.length
                              ? (waveformData[index] as num)
                                  .toDouble()
                                  .clamp(0.1, 1.0)
                              : heights[index % heights.length];

                          return Container(
                            width: 3,
                            height: 32 * heightFactor,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.accent.withOpacity(0.7)
                                  : AppColors.primary.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    formatDuration(duration),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== IMAGE TEXT CONTENT =====
  Widget _buildImageTextContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final imageUrl = widget.block.getContent('imageUrl', '');
    final title = widget.block.getContent('title', '');
    final text = _getTextContent('text', 'Text eingeben...');
    final isTextEmpty = _isTextEmpty('text');
    final layout = widget.block.getContent('layout', 'left');
    final imageSize = widget.block.getContent('imageSize', 0.4);
    final imageCaption = widget.block.getContent('imageCaption', '');
    final colorHex = widget.block.getContent('color', '#333333');

    Color textColor;
    if (isTextEmpty) {
      textColor = AppColors.grey;
    } else if (colorHex == '#333333') {
      textColor = isDark ? AppColors.textLight : AppColors.textSecondary;
    } else {
      textColor = _hexToColor(colorHex);
    }

    Color titleColor;
    if (colorHex == '#333333') {
      titleColor = isDark ? AppColors.textLight : AppColors.textPrimary;
    } else {
      titleColor = _hexToColor(colorHex);
    }

    if (imageUrl.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Platform.isIOS
                  ? CupertinoIcons.text_badge_plus
                  : Icons.article_rounded,
              size: 48,
              color: AppColors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              'Bild mit Text',
              style: TextStyle(
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tippe zum Konfigurieren',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    Widget imageWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            height: layout == 'top' || layout == 'bottom' ? 180 : null,
            errorBuilder: (_, __, ___) => Container(
              height: 150,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.toastBackgroundDark
                    : AppColors.greyLighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: AppColors.grey,
              ),
            ),
          ),
        ),
        if (imageCaption.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            imageCaption,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    Widget textWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: textColor,
            height: 1.6,
            fontStyle: isTextEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );

    switch (layout) {
      case 'top':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            imageWidget,
            const SizedBox(height: 16),
            textWidget,
          ],
        );

      case 'bottom':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            textWidget,
            const SizedBox(height: 16),
            imageWidget,
          ],
        );

      case 'right':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: ((1 - imageSize) * 10).round(),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: textWidget,
              ),
            ),
            Expanded(
              flex: (imageSize * 10).round(),
              child: imageWidget,
            ),
          ],
        );

      case 'left':
      default:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: (imageSize * 10).round(),
              child: imageWidget,
            ),
            Expanded(
              flex: ((1 - imageSize) * 10).round(),
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: textWidget,
              ),
            ),
          ],
        );
    }
  }

  // ===== TIMELINE CONTENT =====
  Widget _buildTimelineContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final entriesRaw = widget.block.getContent<List>('entries', []);
    final lineColorHex = widget.block.getContent('lineColor', '#666666');
    final dotColorHex = widget.block.getContent('dotColor', '#000000');

    final lineColor = _hexToColor(lineColorHex);
    final dotColor = dotColorHex == '#000000'
        ? (isDark ? AppColors.accent : AppColors.primary)
        : _hexToColor(dotColorHex);

    // Parse entries
    final entries =
        entriesRaw.map((e) => Map<String, dynamic>.from(e)).toList();

    // Leerer Zustand
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Platform.isIOS ? CupertinoIcons.time : Icons.timeline_rounded,
              size: 48,
              color: AppColors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              'Lebenslauf',
              style: TextStyle(
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tippe zum Konfigurieren',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // Timeline mit Einträgen
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;

        return _buildTimelineEntry(
          context,
          entry: entry,
          isLast: isLast,
          lineColor: lineColor,
          dotColor: dotColor,
          isDark: isDark,
        );
      }),
    );
  }

  Widget _buildTimelineEntry(
    BuildContext context, {
    required Map<String, dynamic> entry,
    required bool isLast,
    required Color lineColor,
    required Color dotColor,
    required bool isDark,
  }) {
    final date = entry['date'] as String? ?? '';
    final label = entry['label'] as String? ?? '';
    final imageUrl = entry['imageUrl'] as String? ?? '';
    final text = entry['text'] as String? ?? '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline-Linie mit Punkt
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Punkt
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.backgroundDarkElevated
                          : AppColors.surface,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Linie nach unten (außer beim letzten)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: lineColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Inhalt
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.toastBackgroundDark.withOpacity(0.5)
                    : AppColors.greyLighter.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Datum und Label
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: dotColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          date,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: dotColor,
                          ),
                        ),
                      ),
                      if (label.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Bild (optional)
                  if (imageUrl.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.backgroundDark
                                : AppColors.greyLighter,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Text (optional)
                  if (text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textLight.withOpacity(0.8)
                            : AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoplayBadge(BuildContext context, bool isDark) {
    if (Platform.isIOS) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.accent : AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.play_fill,
              size: 12,
              color: isDark ? AppColors.primary : AppColors.background,
            ),
            const SizedBox(width: 4),
            Text(
              'Autoplay',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.primary : AppColors.background,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(20),
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
