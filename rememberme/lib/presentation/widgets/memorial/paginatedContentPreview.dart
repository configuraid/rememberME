import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';
import 'package:rememberme/data/models/content_block_model.dart';
import 'package:rememberme/data/models/memorial_page_model.dart';

class PaginatedContentPreview extends StatefulWidget {
  final MemorialPageModel memorial;
  final bool isDark;
  final ThemeData theme;
  final bool isIOS;
  final IconData Function(ContentBlockType, bool) getBlockIcon;
  final String Function(ContentBlockType) getBlockTypeName;

  const PaginatedContentPreview({
    super.key,
    required this.memorial,
    required this.isDark,
    required this.theme,
    required this.isIOS,
    required this.getBlockIcon,
    required this.getBlockTypeName,
  });

  @override
  State<PaginatedContentPreview> createState() =>
      _PaginatedContentPreviewState();
}

class _PaginatedContentPreviewState extends State<PaginatedContentPreview> {
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  int get _totalPages =>
      (widget.memorial.contentBlocks.length / _itemsPerPage).ceil();

  List<ContentBlock> get _currentPageItems {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage)
        .clamp(0, widget.memorial.contentBlocks.length);
    return widget.memorial.contentBlocks.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppColors.backgroundDarkElevated
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark ? AppColors.borderDark : AppColors.greyLighter,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isDark ? AppColors.shadowDark : AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildPageSelector(),
          const SizedBox(height: 20),
          _buildContentGrid(),
          const SizedBox(height: 16),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.toastBackgroundDark
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isDark
                      ? AppColors.borderDark
                      : AppColors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                widget.isIOS
                    ? CupertinoIcons.square_grid_2x2
                    : Icons.widgets_rounded,
                size: 20,
                color: widget.isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppStrings.contents,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color:
                    widget.isDark ? AppColors.textLight : AppColors.textPrimary,
                fontFamily: widget.isIOS ? '.SF Pro Display' : null,
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.toastBackgroundDark
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.borderDark
                  : AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${widget.memorial.contentBlocks.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? AppColors.accent : AppColors.primary,
              fontFamily: widget.isIOS ? '.SF Pro Text' : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageSelector() {
    if (widget.isIOS) {
      return _buildIOSSegmentedControl();
    } else {
      return _buildAndroidTabBar();
    }
  }

  Widget _buildIOSSegmentedControl() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: _currentPage,
        backgroundColor: widget.isDark
            ? AppColors.toastBackgroundDark
            : AppColors.greyLighter,
        thumbColor: widget.isDark
            ? AppColors.backgroundDarkElevated
            : AppColors.surface,
        children: Map.fromEntries(
          List.generate(_totalPages, (index) {
            final startItem = index * _itemsPerPage + 1;
            final endItem = ((index + 1) * _itemsPerPage)
                .clamp(1, widget.memorial.contentBlocks.length);
            return MapEntry(
              index,
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  '$startItem-$endItem',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _currentPage == index
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: _currentPage == index
                        ? (widget.isDark
                            ? AppColors.textLight
                            : AppColors.primary)
                        : AppColors.grey,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ),
            );
          }),
        ),
        onValueChanged: (value) {
          if (value != null) {
            setState(() => _currentPage = value);
          }
        },
      ),
    );
  }

  Widget _buildAndroidTabBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppColors.toastBackgroundDark
            : AppColors.greyLighter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? AppColors.borderDark : AppColors.greyLight,
          width: 1,
        ),
      ),
      child: Row(
        children: List.generate(_totalPages, (index) {
          final isSelected = _currentPage == index;
          final startItem = index * _itemsPerPage + 1;
          final endItem = ((index + 1) * _itemsPerPage)
              .clamp(1, widget.memorial.contentBlocks.length);

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentPage = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (widget.isDark
                          ? AppColors.accent.withOpacity(0.3)
                          : AppColors.primary)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected && !widget.isDark
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$startItem-$endItem',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? (widget.isDark
                              ? AppColors.accent
                              : AppColors.background)
                          : AppColors.grey,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContentGrid() {
    final items = _currentPageItems;
    final startIndex = _currentPage * _itemsPerPage;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final block = items[index];
        final globalIndex = startIndex + index;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.toastBackgroundDark
                : AppColors.greyLighter,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark ? AppColors.borderDark : AppColors.greyLight,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.backgroundDarkElevated
                      : AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${globalIndex + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          widget.isDark ? AppColors.accent : AppColors.primary,
                      decoration: TextDecoration.none,
                      fontFamily: widget.isIOS ? '.SF Pro Text' : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                widget.getBlockIcon(block.type, widget.isIOS),
                size: 16,
                color: widget.isDark ? AppColors.accent : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.getBlockTypeName(block.type),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? AppColors.textLight
                        : AppColors.textPrimary,
                    fontFamily: widget.isIOS ? '.SF Pro Text' : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator() {
    if (widget.isIOS) {
      return _buildIOSPageIndicator();
    } else {
      return _buildAndroidPageIndicator();
    }
  }

  Widget _buildIOSPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 36,
          onPressed:
              _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _currentPage > 0
                  ? (widget.isDark
                      ? AppColors.toastBackgroundDark
                      : AppColors.primary.withOpacity(0.1))
                  : (widget.isDark
                      ? AppColors.backgroundDark
                      : AppColors.greyLighter),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _currentPage > 0
                    ? (widget.isDark
                        ? AppColors.borderDark
                        : AppColors.primary.withOpacity(0.3))
                    : (widget.isDark
                        ? AppColors.borderDark
                        : AppColors.greyLight),
                width: 1,
              ),
            ),
            child: Icon(
              CupertinoIcons.chevron_left,
              size: 16,
              color: _currentPage > 0
                  ? (widget.isDark ? AppColors.accent : AppColors.primary)
                  : AppColors.grey,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Seite ${_currentPage + 1} von $_totalPages',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
            fontFamily: '.SF Pro Text',
          ),
        ),
        const SizedBox(width: 16),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 36,
          onPressed: _currentPage < _totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _currentPage < _totalPages - 1
                  ? (widget.isDark
                      ? AppColors.toastBackgroundDark
                      : AppColors.primary.withOpacity(0.1))
                  : (widget.isDark
                      ? AppColors.backgroundDark
                      : AppColors.greyLighter),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _currentPage < _totalPages - 1
                    ? (widget.isDark
                        ? AppColors.borderDark
                        : AppColors.primary.withOpacity(0.3))
                    : (widget.isDark
                        ? AppColors.borderDark
                        : AppColors.greyLight),
                width: 1,
              ),
            ),
            child: Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: _currentPage < _totalPages - 1
                  ? (widget.isDark ? AppColors.accent : AppColors.primary)
                  : AppColors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAndroidPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed:
              _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          icon: Icon(
            Icons.chevron_left_rounded,
            color: _currentPage > 0
                ? (widget.isDark ? AppColors.accent : AppColors.primary)
                : AppColors.grey,
          ),
          style: IconButton.styleFrom(
            backgroundColor: _currentPage > 0
                ? (widget.isDark
                    ? AppColors.toastBackgroundDark
                    : AppColors.primary.withOpacity(0.1))
                : (widget.isDark
                    ? AppColors.backgroundDark
                    : AppColors.greyLighter),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: _currentPage > 0
                    ? (widget.isDark
                        ? AppColors.borderDark
                        : AppColors.primary.withOpacity(0.3))
                    : (widget.isDark
                        ? AppColors.borderDark
                        : AppColors.greyLight),
                width: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_totalPages, (index) {
            final isSelected = _currentPage == index;
            return GestureDetector(
              onTap: () => setState(() => _currentPage = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (widget.isDark ? AppColors.accent : AppColors.primary)
                      : (widget.isDark
                          ? AppColors.borderDark
                          : AppColors.greyLight),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: _currentPage < _totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
          icon: Icon(
            Icons.chevron_right_rounded,
            color: _currentPage < _totalPages - 1
                ? (widget.isDark ? AppColors.accent : AppColors.primary)
                : AppColors.grey,
          ),
          style: IconButton.styleFrom(
            backgroundColor: _currentPage < _totalPages - 1
                ? (widget.isDark
                    ? AppColors.toastBackgroundDark
                    : AppColors.primary.withOpacity(0.1))
                : (widget.isDark
                    ? AppColors.backgroundDark
                    : AppColors.greyLighter),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: _currentPage < _totalPages - 1
                    ? (widget.isDark
                        ? AppColors.borderDark
                        : AppColors.primary.withOpacity(0.3))
                    : (widget.isDark
                        ? AppColors.borderDark
                        : AppColors.greyLight),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
