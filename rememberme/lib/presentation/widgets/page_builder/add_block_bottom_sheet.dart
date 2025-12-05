import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:rememberme/data/models/content_block_model.dart';
import 'package:rememberme/core/constants/app_colors.dart';
import 'package:rememberme/core/constants/app_strings.dart';

class AddBlockBottomSheet extends StatelessWidget {
  final Function(ContentBlockType) onBlockTypeSelected;

  const AddBlockBottomSheet({
    super.key,
    required this.onBlockTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSSheet(context);
    } else {
      return _buildAndroidSheet(context);
    }
  }

  // ========== iOS Native UI ==========
  Widget _buildIOSSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.greyLight,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.addBlock,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                        fontFamily: '.SF Pro Display',
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.accent : AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Fertig',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? AppColors.primary : AppColors.background,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: ContentBlockType.values.length,
                itemBuilder: (context, index) {
                  final type = ContentBlockType.values[index];
                  return _buildWidgetTile(context, type, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetTile(
    BuildContext context,
    ContentBlockType type,
    bool isDark,
  ) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => onBlockTypeSelected(type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.toastBackgroundDark : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDarkElevated
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  BlockTypeInfo.getIcon(type),
                  size: 20,
                  color: isDark ? AppColors.accent : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BlockTypeInfo.getTitle(type),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  Text(
                    BlockTypeInfo.getDescription(type),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey,
                      fontFamily: '.SF Pro Text',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // ========== Android Material UI ==========
  Widget _buildAndroidSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          width: 1,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.toastBackgroundDark
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      size: 24,
                      color: isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.addBlock,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.toastBackgroundDark
                          : AppColors.greyLighter,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.grey,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? AppColors.borderDark : AppColors.greyLighter,
            ),

            // Scrollable Block Types Grid
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: ContentBlockType.values.length,
                    itemBuilder: (context, index) {
                      final type = ContentBlockType.values[index];
                      return _buildAndroidBlockTypeCard(context, type, isDark);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidBlockTypeCard(
    BuildContext context,
    ContentBlockType type,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onBlockTypeSelected(type),
          borderRadius: BorderRadius.circular(16),
          splashColor: isDark
              ? AppColors.accent.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.08),
          highlightColor: isDark
              ? AppColors.accent.withOpacity(0.05)
              : AppColors.primary.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.toastBackgroundDark
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    BlockTypeInfo.getIcon(type),
                    size: 28,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  BlockTypeInfo.getTitle(type),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Description - jetzt flexibel
                Flexible(
                  child: Text(
                    BlockTypeInfo.getDescription(type),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.grey,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
