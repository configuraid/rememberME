import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../constants/app_colors.dart';
import 'text_styles.dart';

class AppTheme {
  // ===== MATERIAL LIGHT THEME (Android optimiert) =====
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor:
          const Color(0xFFFAFAFA), // Material Design 3 Background
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: Color(0xFFE3F2FD), // Helleres Primary Container
        secondary: AppColors.secondary,
        secondaryContainer: Color(0xFFFCE4EC),
        surface: Colors.white,
        surfaceContainerHighest: Color(0xFFF5F5F5), // Elevated Surface
        error: AppColors.error,
        errorContainer: Color(0xFFFFEBEE),
        onPrimary: Colors.white,
        onPrimaryContainer: Color(0xFF002171),
        onSecondary: Colors.white,
        onSecondaryContainer: Color(0xFF31111D),
        onSurface: Color(0xFF1C1B1F),
        onSurfaceVariant: Color(0xFF49454F),
        onError: Colors.white,
        onErrorContainer: Color(0xFF410E0B),
        outline: Color(0xFF79747E),
        outlineVariant: Color(0xFFCAC4D0),
        shadow: Colors.black,
        inverseSurface: Color(0xFF313033),
        onInverseSurface: Color(0xFFF4EFF4),
        inversePrimary: Color(0xFFAAC7FF),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 3,
        shadowColor: Colors.black26,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black26,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: Color(0xFF49454F),
          hoverColor: AppColors.primary.withOpacity(0.08),
          highlightColor: AppColors.primary.withOpacity(0.12),
        ),
      ),

      // Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCAC4D0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCAC4D0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF49454F),
          fontSize: 16,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF79747E),
          fontSize: 16,
        ),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontSize: 12,
        ),
      ),

      // FAB Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Color(0xFF79747E),
        type: BottomNavigationBarType.fixed,
        elevation: 3,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE3F2FD),
        elevation: 3,
        height: 80,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: Color(0xFF79747E),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: 24,
            );
          }
          return const IconThemeData(
            color: Color(0xFF79747E),
            size: 24,
          );
        }),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF5F5F5),
        selectedColor: const Color(0xFFE3F2FD),
        disabledColor: const Color(0xFFE0E0E0),
        labelStyle: const TextStyle(
          color: Color(0xFF1C1B1F),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFCAC4D0)),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: AppColors.primary,
        elevation: 6,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1C1B1F),
          letterSpacing: 0,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFF49454F),
          height: 1.5,
          letterSpacing: 0.25,
        ),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF313033),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actionTextColor: const Color(0xFFAAC7FF),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return const Color(0xFF79747E);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.5);
          }
          return const Color(0xFFE0E0E0);
        }),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: AppColors.primary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFCAC4D0),
        thickness: 1,
        space: 1,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyles.displayLarge,
        displayMedium: TextStyles.displayMedium,
        displaySmall: TextStyles.displaySmall,
        headlineLarge: TextStyles.headlineLarge,
        headlineMedium: TextStyles.headlineMedium,
        headlineSmall: TextStyles.headlineSmall,
        titleLarge: TextStyles.titleLarge,
        titleMedium: TextStyles.titleMedium,
        titleSmall: TextStyles.titleSmall,
        bodyLarge: TextStyles.bodyLarge,
        bodyMedium: TextStyles.bodyMedium,
        bodySmall: TextStyles.bodySmall,
        labelLarge: TextStyles.labelLarge,
        labelMedium: TextStyles.labelMedium,
        labelSmall: TextStyles.labelSmall,
      ),
    );
  }

  // ===== MATERIAL DARK THEME (Android optimiert) =====
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFAAC7FF), // Light Primary für Dark Mode
      scaffoldBackgroundColor:
          const Color(0xFF1C1B1F), // Material Design 3 Dark Background
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFAAC7FF), // Helleres Primary für Dark Mode
        primaryContainer: Color(0xFF004494), // Dunkleres Primary Container
        secondary: Color(0xFFF2B8B5),
        secondaryContainer: Color(0xFF633B48),
        surface: Color(0xFF1C1B1F), // Basis Surface
        surfaceContainerHighest: Color(0xFF36343B), // Elevated Surface
        error: Color(0xFFFFB4AB),
        errorContainer: Color(0xFF93000A),
        onPrimary: Color(0xFF003062),
        onPrimaryContainer: Color(0xFFD6E3FF),
        onSecondary: Color(0xFF4A2532),
        onSecondaryContainer: Color(0xFFFFD9E2),
        onSurface: Color(0xFFE6E1E5),
        onSurfaceVariant: Color(0xFFC9C5CA),
        onError: Color(0xFF690005),
        onErrorContainer: Color(0xFFFFDAD6),
        outline: Color(0xFF938F94),
        outlineVariant: Color(0xFF49454F),
        shadow: Colors.black,
        inverseSurface: Color(0xFFE6E1E5),
        onInverseSurface: Color(0xFF313033),
        inversePrimary: Color(0xFF0061A4),
      ),

      // AppBar Theme (Dark)
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C1B1F),
        foregroundColor: Color(0xFFE6E1E5),
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 3,
        surfaceTintColor: Color(0xFFAAC7FF),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE6E1E5),
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFE6E1E5),
          size: 24,
        ),
      ),

      // Card Theme (Dark)
      cardTheme: CardThemeData(
        color: const Color(0xFF2B2930), // Elevated surface
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.3),
        surfaceTintColor: const Color(0xFFAAC7FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button Themes (Dark)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFAAC7FF),
          foregroundColor: const Color(0xFF003062),
          elevation: 2,
          shadowColor: Colors.black45,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFAAC7FF),
          foregroundColor: const Color(0xFF003062),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFAAC7FF),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: Color(0xFFAAC7FF), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFAAC7FF),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFFC9C5CA),
          hoverColor: const Color(0xFFAAC7FF).withOpacity(0.08),
          highlightColor: const Color(0xFFAAC7FF).withOpacity(0.12),
        ),
      ),

      // Input Theme (Dark)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2B2930),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF49454F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF49454F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFAAC7FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 2),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFC9C5CA),
          fontSize: 16,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF938F94),
          fontSize: 16,
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFFFB4AB),
          fontSize: 12,
        ),
      ),

      // FAB Theme (Dark)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFAAC7FF),
        foregroundColor: Color(0xFF003062),
        elevation: 3,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Bottom Navigation (Dark)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1C1B1F),
        selectedItemColor: Color(0xFFAAC7FF),
        unselectedItemColor: Color(0xFF938F94),
        type: BottomNavigationBarType.fixed,
        elevation: 3,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),

      // Navigation Bar (Dark)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1C1B1F),
        indicatorColor: const Color(0xFF004494),
        elevation: 3,
        height: 80,
        surfaceTintColor: const Color(0xFFAAC7FF),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Color(0xFFAAC7FF),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: Color(0xFF938F94),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: Color(0xFFAAC7FF),
              size: 24,
            );
          }
          return const IconThemeData(
            color: Color(0xFF938F94),
            size: 24,
          );
        }),
      ),

      // Chip Theme (Dark)
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2B2930),
        selectedColor: const Color(0xFF004494),
        disabledColor: const Color(0xFF36343B),
        labelStyle: const TextStyle(
          color: Color(0xFFE6E1E5),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Color(0xFFAAC7FF),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF49454F)),
        ),
      ),

      // Dialog Theme (Dark)
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2B2930),
        surfaceTintColor: const Color(0xFFAAC7FF),
        elevation: 6,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE6E1E5),
          letterSpacing: 0,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFFC9C5CA),
          height: 1.5,
          letterSpacing: 0.25,
        ),
      ),

      // SnackBar Theme (Dark)
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFFE6E1E5),
        contentTextStyle: const TextStyle(
          color: Color(0xFF1C1B1F),
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actionTextColor: const Color(0xFF0061A4),
      ),

      // Switch Theme (Dark)
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFAAC7FF);
          }
          return const Color(0xFF938F94);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF004494);
          }
          return const Color(0xFF36343B);
        }),
      ),

      // Bottom Sheet Theme (Dark)
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF2B2930),
        surfaceTintColor: Color(0xFFAAC7FF),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Divider Theme (Dark)
      dividerTheme: const DividerThemeData(
        color: Color(0xFF49454F),
        thickness: 1,
        space: 1,
      ),

      // Text Theme (Dark)
      textTheme: TextTheme(
        displayLarge:
            TextStyles.displayLarge.copyWith(color: const Color(0xFFE6E1E5)),
        displayMedium:
            TextStyles.displayMedium.copyWith(color: const Color(0xFFE6E1E5)),
        displaySmall:
            TextStyles.displaySmall.copyWith(color: const Color(0xFFE6E1E5)),
        headlineLarge:
            TextStyles.headlineLarge.copyWith(color: const Color(0xFFE6E1E5)),
        headlineMedium:
            TextStyles.headlineMedium.copyWith(color: const Color(0xFFE6E1E5)),
        headlineSmall:
            TextStyles.headlineSmall.copyWith(color: const Color(0xFFE6E1E5)),
        titleLarge:
            TextStyles.titleLarge.copyWith(color: const Color(0xFFE6E1E5)),
        titleMedium:
            TextStyles.titleMedium.copyWith(color: const Color(0xFFE6E1E5)),
        titleSmall:
            TextStyles.titleSmall.copyWith(color: const Color(0xFFE6E1E5)),
        bodyLarge:
            TextStyles.bodyLarge.copyWith(color: const Color(0xFFE6E1E5)),
        bodyMedium:
            TextStyles.bodyMedium.copyWith(color: const Color(0xFFC9C5CA)),
        bodySmall:
            TextStyles.bodySmall.copyWith(color: const Color(0xFF938F94)),
        labelLarge:
            TextStyles.labelLarge.copyWith(color: const Color(0xFFE6E1E5)),
        labelMedium:
            TextStyles.labelMedium.copyWith(color: const Color(0xFFC9C5CA)),
        labelSmall:
            TextStyles.labelSmall.copyWith(color: const Color(0xFF938F94)),
      ),
    );
  }

  // ===== CUPERTINO THEME (iOS - unverändert) =====
  static CupertinoThemeData get cupertinoTheme {
    return const CupertinoThemeData(
      primaryColor: AppColors.primary,
      barBackgroundColor: AppColors.surface,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.textPrimary,
        textStyle: TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          inherit: false,
        ),
        actionTextStyle: TextStyle(
          fontSize: 16,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          inherit: false,
        ),
        navTitleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          inherit: false,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          inherit: false,
        ),
        tabLabelTextStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          inherit: false,
        ),
      ),
    );
  }

  // ===== HELPER DECORATIONS =====
  static BoxDecoration get gradientContainer {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.primaryGradient,
      ),
    );
  }

  static BoxDecoration get accentGradientContainer {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.accentGradient,
      ),
    );
  }

  static BoxShadow get cardShadow {
    return BoxShadow(
      color: AppColors.shadow,
      blurRadius: 8,
      offset: const Offset(0, 2),
    );
  }

  static BoxShadow get elevatedShadow {
    return BoxShadow(
      color: AppColors.shadow,
      blurRadius: 16,
      offset: const Offset(0, 4),
    );
  }

  // Dark Mode Shadows
  static BoxShadow get cardShadowDark {
    return BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    );
  }

  static BoxShadow get elevatedShadowDark {
    return BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 16,
      offset: const Offset(0, 4),
    );
  }
}
