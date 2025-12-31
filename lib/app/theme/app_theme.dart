import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF25D366); // WhatsApp green
  static const Color secondaryColor = Color(0xFF128C7E); // Darker green
  static const Color accentColor = Color(0xFF34B7F1); // Light blue
  static const Color backgroundColor = Color(0xFFF0F2F5); // Light gray background
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF111B21); // Dark text
  static const Color textSecondary = Color(0xFF667781); // Gray text
  static const Color errorColor = Color(0xFFE53E3E); // Red for errors

  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      surface: cardColor,
      surfaceContainerHighest: backgroundColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(4),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
    ),
    iconTheme: const IconThemeData(color: textSecondary),
    dividerColor: Colors.grey[300],
    useMaterial3: true,
  );

  // Add dark theme if needed in the future
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    colorScheme: const ColorScheme.dark().copyWith(
      primary: primaryColor,
      secondary: accentColor,
    ),
  );
}

// Custom text styles
class AppTextStyles {
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppTheme.textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12,
    color: AppTheme.textSecondary,
  );
}
