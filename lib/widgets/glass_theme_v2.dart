import 'package:flutter/material.dart';

/// Enhanced glass morphism theme system with extended color palette,
/// elevation system, and glow effects for the cyberpunk admin interface.
/// 
/// This theme extends the original GlassTheme with:
/// - Extended color palette (cyan, blue, green, purple, pink)
/// - Semantic colors (success, warning, error, info)
/// - Three-level elevation system with shadows
/// - Glow effect configurations
/// - Surface colors for different elevation levels
class GlassThemeV2 {
  // ============================================================================
  // Extended Color Palette
  // ============================================================================
  
  /// Primary neon cyan color for cyberpunk theme
  static const Color neonCyan = Color(0xFF06B6D4);
  
  /// Primary neon blue color for cyberpunk theme
  static const Color neonBlue = Color(0xFF3B82F6);
  
  /// Accent neon green color
  static const Color neonGreen = Color(0xFF4ADE80);
  
  /// Accent neon purple color
  static const Color neonPurple = Color(0xFFA855F7);
  
  /// Accent neon pink color
  static const Color neonPink = Color(0xFFEC4899);
  
  // ============================================================================
  // Semantic Colors
  // ============================================================================
  
  /// Success state color (green)
  static const Color success = Color(0xFF10B981);
  
  /// Warning state color (amber)
  static const Color warning = Color(0xFFF59E0B);
  
  /// Error state color (red)
  static const Color error = Color(0xFFEF4444);
  
  /// Info state color (blue)
  static const Color info = Color(0xFF3B82F6);
  
  // ============================================================================
  // Surface Colors with Elevation Levels
  // ============================================================================
  
  /// Surface color for elevation level 1 (6% opacity)
  static const Color surface1 = Color(0x0FFFFFFF);
  
  /// Surface color for elevation level 2 (8% opacity)
  static const Color surface2 = Color(0x14FFFFFF);
  
  /// Surface color for elevation level 3 (12% opacity)
  static const Color surface3 = Color(0x1FFFFFFF);
  
  // ============================================================================
  // Elevation System - Shadow Presets
  // ============================================================================
  
  /// Low elevation shadow (2dp)
  static BoxShadow get elevation1 => BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 4,
    offset: const Offset(0, 2),
  );
  
  /// Medium elevation shadow (4dp)
  static BoxShadow get elevation2 => BoxShadow(
    color: Colors.black.withOpacity(0.15),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );
  
  /// High elevation shadow (8dp)
  static BoxShadow get elevation3 => BoxShadow(
    color: Colors.black.withOpacity(0.2),
    blurRadius: 16,
    offset: const Offset(0, 8),
  );
  
  // ============================================================================
  // Glow Effect Configurations
  // ============================================================================
  
  /// Cyan glow effect for primary elements
  static BoxShadow get glowCyan => BoxShadow(
    color: neonCyan.withOpacity(0.4),
    blurRadius: 20,
    spreadRadius: 2,
  );
  
  /// Blue glow effect
  static BoxShadow get glowBlue => BoxShadow(
    color: neonBlue.withOpacity(0.4),
    blurRadius: 20,
    spreadRadius: 2,
  );
  
  /// Green glow effect for success states
  static BoxShadow get glowGreen => BoxShadow(
    color: neonGreen.withOpacity(0.4),
    blurRadius: 20,
    spreadRadius: 2,
  );
  
  /// Purple glow effect
  static BoxShadow get glowPurple => BoxShadow(
    color: neonPurple.withOpacity(0.4),
    blurRadius: 20,
    spreadRadius: 2,
  );
  
  /// Pink glow effect
  static BoxShadow get glowPink => BoxShadow(
    color: neonPink.withOpacity(0.4),
    blurRadius: 20,
    spreadRadius: 2,
  );
  
  // ============================================================================
  // Gradient Presets
  // ============================================================================
  
  /// Primary gradient (cyan to blue)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonCyan, neonBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Secondary gradient (green to cyan)
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [neonGreen, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Accent gradient (purple to pink)
  static const LinearGradient accentGradient = LinearGradient(
    colors: [neonPurple, neonPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Success gradient (green shades)
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, neonGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Error gradient (red shades)
  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Glass surface gradient (subtle white gradient)
  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ============================================================================
  // Border Styles
  // ============================================================================
  
  /// Standard glass border with subtle white
  static Border get glassBorder => Border.all(
    color: Colors.white.withOpacity(0.1),
    width: 1,
  );
  
  /// Cyan neon border
  static Border get neonCyanBorder => Border.all(
    color: neonCyan.withOpacity(0.5),
    width: 1,
  );
  
  /// Green neon border
  static Border get neonGreenBorder => Border.all(
    color: neonGreen.withOpacity(0.5),
    width: 1,
  );
  
  /// Blue neon border
  static Border get neonBlueBorder => Border.all(
    color: neonBlue.withOpacity(0.5),
    width: 1,
  );
  
  // ============================================================================
  // Helper Methods
  // ============================================================================
  
  /// Get shadow list for specified elevation level
  static List<BoxShadow> getShadowsForElevation(int level) {
    switch (level) {
      case 1:
        return [elevation1];
      case 2:
        return [elevation2];
      case 3:
        return [elevation3];
      default:
        return [elevation2]; // Default to medium elevation
    }
  }
  
  /// Get surface color for specified elevation level
  static Color getSurfaceColor(int level) {
    switch (level) {
      case 1:
        return surface1;
      case 2:
        return surface2;
      case 3:
        return surface3;
      default:
        return surface2; // Default to medium surface
    }
  }
  
  /// Get glow effect by color name
  static BoxShadow getGlow(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'cyan':
        return glowCyan;
      case 'blue':
        return glowBlue;
      case 'green':
        return glowGreen;
      case 'purple':
        return glowPurple;
      case 'pink':
        return glowPink;
      default:
        return glowCyan; // Default to cyan glow
    }
  }
  
  /// Get semantic color by state name
  static Color getSemanticColor(String state) {
    switch (state.toLowerCase()) {
      case 'success':
        return success;
      case 'warning':
        return warning;
      case 'error':
        return error;
      case 'info':
        return info;
      default:
        return info; // Default to info color
    }
  }
}
