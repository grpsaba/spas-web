import 'package:flutter/material.dart';

/// Design system constants for the Pointage System
/// Provides consistent colors, typography, spacing, and other design tokens

/// Color palette for the pointage system
class PointageColors {
  PointageColors._();

  // Primary colors
  static const primary = Color(0xFF3F51B5); // Indigo
  static const secondary = Color(0xFF00BCD4); // Cyan
  
  // Status colors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  
  // Background colors
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  
  // Text colors
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  
  // Additional UI colors
  static const divider = Color(0xFFE0E0E0);
  static const disabled = Color(0xFFBDBDBD);
  static const hover = Color(0xFFF5F5F5);
  
  // Chart colors
  static const chartGreen = Color(0xFF4CAF50);
  static const chartRed = Color(0xFFF44336);
  static const chartBlue = Color(0xFF2196F3);
  static const chartOrange = Color(0xFFFF9800);
  static const chartPurple = Color(0xFF9C27B0);
}

/// Typography styles for the pointage system
class PointageTextStyles {
  PointageTextStyles._();

  // Headings
  static const headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: PointageColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: PointageColors.textPrimary,
    letterSpacing: -0.25,
  );

  static const headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: PointageColors.textPrimary,
  );

  static const headline4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: PointageColors.textPrimary,
  );

  // Body text
  static const body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: PointageColors.textPrimary,
    height: 1.5,
  );

  static const body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: PointageColors.textPrimary,
    height: 1.5,
  );

  // Caption and labels
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: PointageColors.textSecondary,
    height: 1.4,
  );

  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: PointageColors.textPrimary,
  );

  // Button text
  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Overline (small labels)
  static const overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: PointageColors.textSecondary,
    letterSpacing: 1.5,
  );
}

/// Spacing constants for consistent layout
class PointageSpacing {
  PointageSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

/// Border radius constants
class PointageBorderRadius {
  PointageBorderRadius._();

  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  
  // Predefined border radius
  static final BorderRadius small = BorderRadius.circular(sm);
  static final BorderRadius medium = BorderRadius.circular(md);
  static final BorderRadius large = BorderRadius.circular(lg);
  static final BorderRadius extraLarge = BorderRadius.circular(xl);
  static final BorderRadius extraExtraLarge = BorderRadius.circular(xxl);
}

/// Shadow constants for elevation
class PointageShadows {
  PointageShadows._();

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 8),
      blurRadius: 16,
    ),
  ];
}

/// Animation durations
class PointageAnimations {
  PointageAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  
  // Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve emphasizedCurve = Curves.easeOutCubic;
}

/// Icon sizes
class PointageIconSizes {
  PointageIconSizes._();

  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
}

/// Common button styles
class PointageButtonStyles {
  PointageButtonStyles._();

  static ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: PointageColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: PointageSpacing.lg,
      vertical: PointageSpacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: PointageBorderRadius.medium,
    ),
    elevation: 2,
  );

  static ButtonStyle secondary = ElevatedButton.styleFrom(
    backgroundColor: PointageColors.secondary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: PointageSpacing.lg,
      vertical: PointageSpacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: PointageBorderRadius.medium,
    ),
    elevation: 2,
  );

  static ButtonStyle outlined = OutlinedButton.styleFrom(
    foregroundColor: PointageColors.primary,
    padding: const EdgeInsets.symmetric(
      horizontal: PointageSpacing.lg,
      vertical: PointageSpacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: PointageBorderRadius.medium,
    ),
    side: const BorderSide(color: PointageColors.primary, width: 1.5),
  );

  static ButtonStyle text = TextButton.styleFrom(
    foregroundColor: PointageColors.primary,
    padding: const EdgeInsets.symmetric(
      horizontal: PointageSpacing.md,
      vertical: PointageSpacing.sm,
    ),
  );
}

/// Input decoration theme
class PointageInputDecorations {
  PointageInputDecorations._();

  static InputDecoration standard({
    String? labelText,
    String? hintText,
    String? helperText,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: PointageBorderRadius.medium,
        borderSide: const BorderSide(color: PointageColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: PointageBorderRadius.medium,
        borderSide: const BorderSide(color: PointageColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: PointageBorderRadius.medium,
        borderSide: const BorderSide(color: PointageColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: PointageBorderRadius.medium,
        borderSide: const BorderSide(color: PointageColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: PointageBorderRadius.medium,
        borderSide: const BorderSide(color: PointageColors.error, width: 2),
      ),
      filled: true,
      fillColor: PointageColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.md,
        vertical: PointageSpacing.md,
      ),
    );
  }
}

/// Card decoration
class PointageCardDecorations {
  PointageCardDecorations._();

  static BoxDecoration standard = BoxDecoration(
    color: PointageColors.surface,
    borderRadius: PointageBorderRadius.large,
    boxShadow: PointageShadows.md,
  );

  static BoxDecoration elevated = BoxDecoration(
    color: PointageColors.surface,
    borderRadius: PointageBorderRadius.large,
    boxShadow: PointageShadows.lg,
  );

  static BoxDecoration outlined = BoxDecoration(
    color: PointageColors.surface,
    borderRadius: PointageBorderRadius.large,
    border: Border.all(color: PointageColors.divider),
  );
}
