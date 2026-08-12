import 'package:flutter/material.dart';

/// Typography system for consistent text styling throughout the application.
/// 
/// This system defines:
/// - Heading styles (H1-H6) using Orbitron font
/// - Body text styles using ShareTechMono font
/// - Letter spacing and line height for optimal readability
/// - Text color variants for different emphasis levels
class TypographySystem {
  // ============================================================================
  // Heading Styles (Orbitron Font)
  // ============================================================================
  
  /// H1 heading style - largest heading
  static const TextStyle h1 = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    height: 1.2,
    color: Colors.white,
  );
  
  /// H2 heading style
  static const TextStyle h2 = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    height: 1.3,
    color: Colors.white,
  );
  
  /// H3 heading style
  static const TextStyle h3 = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    height: 1.4,
    color: Colors.white,
  );
  
  /// H4 heading style
  static const TextStyle h4 = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.4,
    color: Colors.white,
  );
  
  /// H5 heading style
  static const TextStyle h5 = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
    height: 1.5,
    color: Colors.white,
  );
  
  /// H6 heading style - smallest heading
  static const TextStyle h6 = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.5,
    color: Colors.white,
  );
  
  // ============================================================================
  // Body Text Styles (ShareTechMono Font)
  // ============================================================================
  
  /// Large body text style
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'ShareTechMono',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    height: 1.5,
    color: Colors.white,
  );
  
  /// Medium body text style (default)
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'ShareTechMono',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.5,
    color: Color(0xFFB3B3B3), // white70
  );
  
  /// Small body text style
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'ShareTechMono',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.4,
    color: Color(0xFF999999), // white60
  );
  
  /// Caption text style - smallest body text
  static const TextStyle caption = TextStyle(
    fontFamily: 'ShareTechMono',
    fontSize: 11,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.3,
    color: Color(0xFF8A8A8A), // white54
  );
  
  // ============================================================================
  // Text Color Variants for Emphasis Levels
  // ============================================================================
  
  /// Primary text color (full white)
  static const Color textPrimary = Colors.white;
  
  /// Secondary text color (70% opacity)
  static const Color textSecondary = Color(0xFFB3B3B3);
  
  /// Tertiary text color (60% opacity)
  static const Color textTertiary = Color(0xFF999999);
  
  /// Disabled text color (40% opacity)
  static const Color textDisabled = Color(0xFF666666);
  
  /// Hint text color (54% opacity)
  static const Color textHint = Color(0xFF8A8A8A);
  
  // ============================================================================
  // Helper Methods
  // ============================================================================
  
  /// Get heading style by level (1-6)
  static TextStyle getHeadingStyle(int level) {
    switch (level) {
      case 1:
        return h1;
      case 2:
        return h2;
      case 3:
        return h3;
      case 4:
        return h4;
      case 5:
        return h5;
      case 6:
        return h6;
      default:
        return h3; // Default to H3
    }
  }
  
  /// Get body style by size name
  static TextStyle getBodyStyle(String size) {
    switch (size.toLowerCase()) {
      case 'large':
        return bodyLarge;
      case 'medium':
        return bodyMedium;
      case 'small':
        return bodySmall;
      case 'caption':
        return caption;
      default:
        return bodyMedium; // Default to medium
    }
  }
  
  /// Get text color by emphasis level
  static Color getTextColor(String emphasis) {
    switch (emphasis.toLowerCase()) {
      case 'primary':
        return textPrimary;
      case 'secondary':
        return textSecondary;
      case 'tertiary':
        return textTertiary;
      case 'disabled':
        return textDisabled;
      case 'hint':
        return textHint;
      default:
        return textPrimary; // Default to primary
    }
  }
}
