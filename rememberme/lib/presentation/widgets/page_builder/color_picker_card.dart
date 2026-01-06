import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

import '../../../core/constants/app_colors.dart';

class ColorPickerCard extends StatelessWidget {
  /// Label das über dem Picker angezeigt wird
  final String label;

  /// Aktueller Hex-Farbwert (z.B. '#FF5733' oder 'FF5733')
  final String currentColor;

  /// Callback wenn eine neue Farbe ausgewählt wurde
  final ValueChanged<String> onColorChanged;

  /// Funktion die den Color Picker Dialog anzeigt und die ausgewählte Farbe zurückgibt
  final Future<String?> Function({
    required BuildContext context,
    required String currentColor,
    required String title,
  }) showColorPickerDialog;

  /// Optionaler Subtitle statt "Ausgewählte Farbe"
  final String? subtitle;

  const ColorPickerCard({
    super.key,
    required this.label,
    required this.currentColor,
    required this.onColorChanged,
    required this.showColorPickerDialog,
    this.subtitle,
  });

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _hexToColor(currentColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
            fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 12),

        // Color Preview Card
        GestureDetector(
          onTap: () async {
            final selectedColor = await showColorPickerDialog(
              context: context,
              currentColor: currentColor,
              title: label,
            );

            if (selectedColor != null) {
              onColorChanged(selectedColor);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Farbvorschau
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.greyLight,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Hex Code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle ?? 'Ausgewählte Farbe',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.grey,
                          fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentColor.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: Platform.isIOS ? 'SF Mono' : 'monospace',
                          letterSpacing: 1.5,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),

                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.accent.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Platform.isIOS
                        ? CupertinoIcons.color_filter
                        : Icons.palette_rounded,
                    size: 22,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
