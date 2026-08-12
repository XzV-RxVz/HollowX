import 'package:flutter/material.dart';

class GlassTheme {
  // Key Colors
  static const Color neonGreen = Color(0xFF4ADE80);
  static const Color neonBlue = Color(0xFF3B82F6);
  static const Color neonRed = Color(0xFFEF4444);
  static const Color glassWhite = Color(0x1FFFFFFF);
  static const Color glassBlack = Color(0x99000000);
  
  // Gradients
  static const LinearGradient greenGradient = LinearGradient(
    colors: [neonGreen, Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white10, Colors.white12],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static const TextStyle header = TextStyle(
    fontFamily: 'Orbitron',
    fontWeight: FontWeight.w900, // Black weight for maximum impact
    color: Colors.white,
    letterSpacing: 2.0, // Increased spacing for a firmer look
  );

  static const TextStyle body = TextStyle(
    // Removed ShareTechMono for a more professional, "tegas" look
    fontWeight: FontWeight.w600, 
    color: Colors.white70,
    fontSize: 14,
    letterSpacing: 0.5,
  );

  // Borders
  static Border glassBorder = Border.all(
    color: Colors.white.withOpacity(0.1),
    width: 1,
  );
  
  static Border neonBorder = Border.all(
    color: neonGreen.withOpacity(0.5),
    width: 1,
  );

  static InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: body.copyWith(color: Colors.white.withOpacity(0.3)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: neonRed, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
