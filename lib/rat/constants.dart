import 'package:flutter/material.dart';
import '../services/api_config.dart';

class RatConstants {
  static String get baseUrl => ApiConfig.baseUrl; 
  static String get wsUrl => ApiConfig.wsUrl;

  
  // RAT Theme Colors
  static const Color primaryColor = Color(0xFFEF4444); // Red
  static const Color backgroundColor = Color(0xFF000000); // Black
  static const Color cardColor = Color(0xFF111111); // Dark Gray
  static const Color errorColor = Color(0xFFFF0000); // Red
  
  static const TextStyle terminalStyle = TextStyle(
    color: primaryColor,
    fontFamily: 'Rajdhani', // Using the font already available in ADMIN
    fontWeight: FontWeight.bold,
  );
}
