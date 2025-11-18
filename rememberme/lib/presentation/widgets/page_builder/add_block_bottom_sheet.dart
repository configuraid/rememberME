import 'package:flutter/material.dart';
import 'package:rememberme/data/models/content_block_model.dart';
import 'package:rememberme/core/constants/app_colors.dart';

class AddBlockBottomSheet extends StatelessWidget {
  final Function(ContentBlockType) onBlockTypeSelected;

  const AddBlockBottomSheet({
    super.key,
    required this.onBlockTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark
              ? AppColors.primaryLight.withOpacity(0.2)
              : Colors.grey.shade200,
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
                color: isDark ? const Color(0xFF404040) : Colors.grey.shade300,
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                AppColors.primaryLight.withOpacity(0.25),
                                AppColors.primaryLight.withOpacity(0.15),
                              ]
                            : [
                                AppColors.primary.withOpacity(0.15),
                                AppColors.primary.withOpacity(0.08),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.primaryLight.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      size: 24,
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Block hinzufügen',
                      style: theme.textTheme.titleLarge?.copyWith(
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
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? const Color(0xFF909090)
                            : Colors.grey.shade600,
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
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
            ),

            // Block Types Grid
            Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: ContentBlockType.values.map((type) {
                  return _buildBlockTypeCard(context, type, isDark);
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockTypeCard(
    BuildContext context,
    ContentBlockType type,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.04),
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
              ? AppColors.primaryLight.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.08),
          highlightColor: isDark
              ? AppColors.primaryLight.withOpacity(0.05)
              : AppColors.primary.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Container mit Gradient
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppColors.primaryLight.withOpacity(0.2),
                              AppColors.primaryLight.withOpacity(0.1),
                            ]
                          : [
                              AppColors.primary.withOpacity(0.12),
                              AppColors.primary.withOpacity(0.06),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.primaryLight.withOpacity(0.25)
                          : AppColors.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    BlockTypeInfo.getIcon(type),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  BlockTypeInfo.getTitle(type),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    letterSpacing: 0.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  BlockTypeInfo.getDescription(type),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color:
                        isDark ? const Color(0xFF909090) : Colors.grey.shade600,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
