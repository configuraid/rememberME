import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rememberme/core/constants/app_colors.dart';

class ConfigDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  const ConfigDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      return _buildIOSDropdown(context, isDark);
    }
    return _buildAndroidDropdown(context, isDark);
  }

  Widget _buildIOSDropdown(BuildContext context, bool isDark) {
    final selectedLabel = items[value] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showIOSPicker(context, isDark),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.greyLight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedLabel,
                  style: TextStyle(
                    fontSize: 17,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 18,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showIOSPicker(BuildContext context, bool isDark) {
    final itemsList = items.entries.toList();
    int selectedIndex = itemsList.indexWhere((e) => e.key == value);
    if (selectedIndex < 0) selectedIndex = 0;

    HapticFeedback.selectionClick();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 280,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header mit Done-Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.greyLighter,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Abbrechen',
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.pop(context);
                      onChanged(itemsList[selectedIndex].key);
                    },
                    child: Text(
                      'Fertig',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.accent : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Picker
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: selectedIndex,
                ),
                magnification: 1.1,
                squeeze: 1.2,
                useMagnifier: true,
                itemExtent: 40,
                backgroundColor: Colors.transparent,
                onSelectedItemChanged: (index) {
                  HapticFeedback.selectionClick();
                  selectedIndex = index;
                },
                children: itemsList.map((entry) {
                  return Center(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 20,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidDropdown(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.greyLighter,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              dropdownColor:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
              style: TextStyle(
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontSize: 17,
              ),
              items: items.entries
                  .map((entry) => DropdownMenuItem<T>(
                        value: entry.key,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(entry.value),
                        ),
                      ))
                  .toList(),
              onChanged: (newValue) {
                HapticFeedback.selectionClick();
                onChanged(newValue);
              },
            ),
          ),
        ),
      ],
    );
  }
}
