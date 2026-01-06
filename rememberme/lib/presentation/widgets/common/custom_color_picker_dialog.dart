import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:rememberme/core/constants/app_colors.dart';

Future<String?> showColorPickerDialog({
  required BuildContext context,
  required String currentColor,
  String title = 'Farbe wählen',
}) async {
  final Color initialColor = _hexToColor(currentColor);

  if (Platform.isIOS) {
    return _showIOSColorPicker(
      context: context,
      initialColor: initialColor,
      title: title,
    );
  } else {
    return _showAndroidColorPicker(
      context: context,
      initialColor: initialColor,
      title: title,
    );
  }
}

/// iOS-spezifischer Color Picker als Modal Bottom Sheet
Future<String?> _showIOSColorPicker({
  required BuildContext context,
  required Color initialColor,
  required String title,
}) async {
  Color selectedColor = initialColor;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showCupertinoModalPopup<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDarkElevated
                : AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  child: Row(
                    children: [
                      // Farbvorschau
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.greyLight,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: selectedColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                            fontFamily: '.SF Pro Display',
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        onPressed: () => Navigator.pop(context, null),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.toastBackgroundDark
                                : AppColors.greyLighter,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 16,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Hex Code Anzeige
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.toastBackgroundDark
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.greyLighter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.number,
                          size: 18,
                          color: isDark ? AppColors.accent : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _colorToHex(selectedColor).toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Mono',
                            letterSpacing: 1.5,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(
                              text: _colorToHex(selectedColor).toUpperCase(),
                            ));
                            HapticFeedback.lightImpact();
                          },
                          child: Icon(
                            CupertinoIcons.doc_on_clipboard,
                            size: 18,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Color Wheel
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ColorPicker(
                      pickerColor: selectedColor,
                      onColorChanged: (color) {
                        HapticFeedback.selectionClick();
                        setState(() => selectedColor = color);
                      },
                      colorPickerWidth: 280,
                      pickerAreaHeightPercent: 0.7,
                      enableAlpha: false,
                      displayThumbColor: true,
                      paletteType: PaletteType.hueWheel,
                      labelTypes: const [],
                      pickerAreaBorderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                // Confirm Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: isDark ? AppColors.accent : AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context, _colorToHex(selectedColor));
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Farbe übernehmen',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.primary
                                  : AppColors.background,
                              fontFamily: '.SF Pro Text',
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Android-spezifischer Color Picker als Dialog
Future<String?> _showAndroidColorPicker({
  required BuildContext context,
  required Color initialColor,
  required String title,
}) async {
  Color selectedColor = initialColor;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          backgroundColor:
              isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              selectedColor,
                              selectedColor.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: selectedColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.palette_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textLight
                                    : AppColors.textPrimary,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Wähle eine Farbe aus',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.grey,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Hex Code Anzeige
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.toastBackgroundDark
                          : AppColors.greyLighter.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.greyLighter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.greyLight,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _colorToHex(selectedColor).toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                text: _colorToHex(selectedColor).toUpperCase(),
                              ));
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Hex-Code kopiert!'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 20,
                                color: AppColors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Color Wheel
                  ColorPicker(
                    pickerColor: selectedColor,
                    onColorChanged: (color) {
                      HapticFeedback.selectionClick();
                      setState(() => selectedColor = color);
                    },
                    colorPickerWidth: 260,
                    pickerAreaHeightPercent: 0.7,
                    enableAlpha: false,
                    displayThumbColor: true,
                    paletteType: PaletteType.hueWheel,
                    labelTypes: const [],
                    pickerAreaBorderRadius: BorderRadius.circular(16),
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      // Abbrechen
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.toastBackgroundDark
                                : AppColors.greyLighter.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.greyLight.withOpacity(0.5),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(context, null),
                              borderRadius: BorderRadius.circular(14),
                              child: Center(
                                child: Text(
                                  'Abbrechen',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textLight
                                        : AppColors.grey,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Übernehmen
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isDark ? AppColors.accent : AppColors.primary,
                                (isDark ? AppColors.accent : AppColors.primary)
                                    .withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark
                                        ? AppColors.accent
                                        : AppColors.primary)
                                    .withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(
                                    context, _colorToHex(selectedColor));
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: selectedColor,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Übernehmen',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.primary
                                          : AppColors.background,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Konvertiert einen Hex-String zu einer Color
Color _hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  return Color(int.parse(hex, radix: 16));
}

/// Konvertiert eine Color zu einem Hex-String
String _colorToHex(Color color) {
  return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
}
