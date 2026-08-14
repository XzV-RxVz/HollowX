import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ====================================================
// MODEL PRESET WARNA
// ====================================================
class ColorPreset {
  final String name;
  final Color primary;
  final Color accent;
  final Color? secondary;
  final IconData? icon;
  final String description;

  const ColorPreset({
    required this.name,
    required this.primary,
    required this.accent,
    this.secondary,
    this.icon,
    this.description = '',
  });
}

// ====================================================
// THEME PROVIDER
// ====================================================
class ThemeProvider extends ChangeNotifier {
  // ========== DEFAULT COLOR ==========
  static const Color _defaultPrimary = Color(0xFF9D00FF);
  static const Color _defaultAccent = Color(0xFFCC66FF);
  static const Color _defaultSecondary = Color(0xFF7C4DFF);

  // ========== STATE ==========
  Color _primaryColor = _defaultPrimary;
  Color _accentColor = _defaultAccent;
  Color _secondaryColor = _defaultSecondary;
  bool _isDarkMode = true;
  int _currentPresetIndex = 0;
  bool _customGradientEnabled = true;
  double _glowIntensity = 0.5;

  // ========== GETTERS ==========
  Color get primaryColor => _primaryColor;
  Color get accentColor => _accentColor;
  Color get secondaryColor => _secondaryColor;
  bool get isDarkMode => _isDarkMode;
  bool get customGradientEnabled => _customGradientEnabled;
  double get glowIntensity => _glowIntensity;

  // ========== GETTER UNTUK KOMPATIBILITAS ==========
  Color get primaryColorLight => _accentColor;
  Color get primaryColorDark => _primaryColor;
  Color get textDim => _isDarkMode ? Colors.white.withOpacity(0.25) : Colors.black.withOpacity(0.25);

  // ========== DYNAMIC UI COLORS ==========
  Color get backgroundColor => _isDarkMode ? const Color(0xFF0A0F1A) : const Color(0xFFF5F5F5);
  Color get surfaceColor => _isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFFFFFFF);
  Color get cardColor => _isDarkMode ? const Color(0xFF111C30) : const Color(0xFFFAFAFA);
  Color get textPrimaryColor => _isDarkMode ? Colors.white : Colors.black87;
  Color get textSecondaryColor => _isDarkMode ? Colors.white70 : Colors.black54;
  Color get textHintColor => _isDarkMode ? Colors.white38 : Colors.black38;
  
  // ========== BORDER COLOR (TAMBAHKAN INI) ==========
  Color get borderColor => _isDarkMode 
      ? Colors.white.withOpacity(0.12) 
      : Colors.black.withOpacity(0.12);
  
  // ========== GLASSMORPHISM ==========
  Color get glassPrimary => _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
  Color get glassSecondary => _isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
  Color get glassBorder => _isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
  
  // ========== GLOW ==========
  Color get primaryGlow => primaryColor.withOpacity(0.3 * _glowIntensity);
  Color get accentGlow => accentColor.withOpacity(0.3 * _glowIntensity);
  Color get strongGlow => primaryColor.withOpacity(0.6 * _glowIntensity);
  
  // ========== STATUS COLORS ==========
  Color get successColor => const Color(0xFF00E676);
  Color get errorColor => const Color(0xFFFF2D55);
  Color get warningColor => const Color(0xFFFF9F0A);
  Color get infoColor => const Color(0xFF0A84FF);

  // ========== GRADIENTS ==========
  LinearGradient get primaryGradient => LinearGradient(
    colors: [primaryColor, accentColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _isDarkMode
        ? [
            primaryColor.withOpacity(0.14),
            const Color(0xFF090C12),
            const Color(0xFF050608),
          ]
        : [
            primaryColor.withOpacity(0.08),
            const Color(0xFFF0F0F0),
            const Color(0xFFE0E0E0),
          ],
    stops: const [0.0, 0.5, 1.0],
  );
  
  LinearGradient get cardGradient => LinearGradient(
    colors: [glassPrimary, glassSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  LinearGradient get buttonGradient => LinearGradient(
    colors: [primaryColor, accentColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========== DECORATIONS ==========
  BoxDecoration get glassCardDecoration => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: primaryColor.withOpacity(0.15), width: 1),
    boxShadow: [
      BoxShadow(color: primaryGlow, blurRadius: 16, spreadRadius: 1),
    ],
  );
  
  BoxDecoration get neonBorderDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: primaryColor.withOpacity(0.4), width: 1.5),
    boxShadow: [
      BoxShadow(color: strongGlow, blurRadius: 12, spreadRadius: 0),
    ],
  );

  // ========== COLOR PRESETS ==========
  static const List<ColorPreset> colorPresets = [
    // Signature Collection
    ColorPreset(name: '👑 Royal Purple', primary: Color(0xFF7B2FBE), accent: Color(0xFFD44BFF), description: 'Signature SxC ExecX'),
    ColorPreset(name: '🔥 Magma Core', primary: Color(0xFFFF4500), accent: Color(0xFFFFD700), description: 'Enerjik & Berapi-api'),
    ColorPreset(name: '🧊 Frost Bite', primary: Color(0xFF00BFFF), accent: Color(0xFFE0FFFF), description: 'Dingin & Mematikan'),
    ColorPreset(name: '🌿 Poison Ivy', primary: Color(0xFF00FF7F), accent: Color(0xFF006400), description: 'Beracun & Eksotis'),
    ColorPreset(name: '🌅 Sunset Vibes', primary: Color(0xFFFF6B35), accent: Color(0xFFFFB347), description: 'Nuansa Senja'),
    ColorPreset(name: '🌙 Midnight Galaxy', primary: Color(0xFF1A1A2E), accent: Color(0xFFE94560), description: 'Misterius & Elegan'),
    
    // Neon Explosion
    ColorPreset(name: '⚡ Neon Rave', primary: Color(0xFF00FF88), accent: Color(0xFFFF00FF), description: 'Party Mode ON!'),
    ColorPreset(name: '⚡ Cyberpunk 2077', primary: Color(0xFFFF007F), accent: Color(0xFF00F0FF), description: 'Futuristik'),
    ColorPreset(name: '⚡ Laser Beam', primary: Color(0xFF00FFFF), accent: Color(0xFFFF00FF), description: 'Cyan + Magenta'),
    ColorPreset(name: '⚡ Acid Trip', primary: Color(0xFFCCFF00), accent: Color(0xFFFF00CC), description: 'Psikedelik'),
    ColorPreset(name: '⚡ Vaporwave 88', primary: Color(0xFFFF71CE), accent: Color(0xFF01CDFE), description: 'Retro 80an'),
    ColorPreset(name: '⚡ Outrun Sunset', primary: Color(0xFFFF0055), accent: Color(0xFF00FFFF), description: 'Synthwave Style'),
    ColorPreset(name: '⚡ Matrix Code', primary: Color(0xFF00FF41), accent: Color(0xFF008F11), description: 'The One'),
    ColorPreset(name: '⚡ Electric Blue', primary: Color(0xFF0066FF), accent: Color(0xFF00D4FF), description: 'Menyala abangku'),
    ColorPreset(name: '⚡ Atomic Lime', primary: Color(0xFFBFFF00), accent: Color(0xFFFF00BF), description: 'Ledakan Energi'),
    
    // Purple Series
    ColorPreset(name: '💜 Deep Violet', primary: Color(0xFF4A148C), accent: Color(0xFF9C27B0), description: 'Mewah & Anggun'),
    ColorPreset(name: '💜 Soft Lavender', primary: Color(0xFFBF8FE8), accent: Color(0xFF9D4EDD), description: 'Lembut & Menenangkan'),
    ColorPreset(name: '💜 Neon Purple', primary: Color(0xFFAA00FF), accent: Color(0xFFE040FB), description: 'Mencolok'),
    ColorPreset(name: '💜 Dark Plum', primary: Color(0xFF3D0066), accent: Color(0xFF7B2FBE), description: 'Gelap & Misterius'),
    
    // Pink Series
    ColorPreset(name: '❤️ Hot Pink', primary: Color(0xFFFF69B4), accent: Color(0xFFFF1493), description: 'Berani & Seksi'),
    ColorPreset(name: '❤️ Crimson Red', primary: Color(0xFFDC143C), accent: Color(0xFFFF6B6B), description: 'Berani & Klasik'),
    ColorPreset(name: '❤️ Rose Gold', primary: Color(0xFFE91E63), accent: Color(0xFFF06292), description: 'Mewah & Glamor'),
    
    // Blue Series
    ColorPreset(name: '💙 Ocean Deep', primary: Color(0xFF1A237E), accent: Color(0xFF3949AB), description: 'Dalam & Tenang'),
    ColorPreset(name: '💙 Sky High', primary: Color(0xFF87CEEB), accent: Color(0xFF4169E1), description: 'Cerlang & Bebas'),
    ColorPreset(name: '💙 Cobalt Blue', primary: Color(0xFF0047AB), accent: Color(0xFF6495ED), description: 'Solid & Kuat'),
    
    // Green Series
    ColorPreset(name: '💚 Emerald', primary: Color(0xFF00A86B), accent: Color(0xFF2DD4BF), description: 'Mewah & Asri'),
    ColorPreset(name: '💚 Forest', primary: Color(0xFF2E7D32), accent: Color(0xFF1B5E20), description: 'Alami & Teduh'),
    ColorPreset(name: '💚 Neon Mint', primary: Color(0xFF4ADE80), accent: Color(0xFF059669), description: 'Segar & Enerjik'),
    
    // Orange/Yellow Series
    ColorPreset(name: '🧡 Tangerine', primary: Color(0xFFF28500), accent: Color(0xFFFFA500), description: 'Enerjik'),
    ColorPreset(name: '🧡 Pumpkin', primary: Color(0xFFFF7518), accent: Color(0xFFFFA559), description: 'Hangat'),
    ColorPreset(name: '💛 Golden', primary: Color(0xFFFFD700), accent: Color(0xFFFFA500), description: 'Mewah & Berkilau'),
    
    // Dark Series
    ColorPreset(name: '🖤 Shadow', primary: Color(0xFF1A1A1A), accent: Color(0xFF333333), description: 'Minimalis'),
    ColorPreset(name: '🖤 Dark Knight', primary: Color(0xFF1F1F2F), accent: Color(0xFF3A3A4A), description: 'Gelap & Berwibawa'),
    ColorPreset(name: '🖤 Charcoal', primary: Color(0xFF36454F), accent: Color(0xFF4A5D6B), description: 'Maskulin'),
    
    // Metallic
    ColorPreset(name: '✨ Silver', primary: Color(0xFFC0C0C0), accent: Color(0xFFE0E0E0), description: 'Mewah & Elegan'),
    ColorPreset(name: '✨ Gold', primary: Color(0xFFFFD700), accent: Color(0xFFFFC107), description: 'Berharga'),
    ColorPreset(name: '✨ Platinum', primary: Color(0xFFE5E4E2), accent: Color(0xFFCED0D0), description: 'Premium'),
    
    // Special
    ColorPreset(name: '🌌 Galaxy', primary: Color(0xFF200B3F), accent: Color(0xFF9B59B6), description: 'Luar Angkasa'),
    ColorPreset(name: '🌈 Rainbow', primary: Color(0xFFFF006E), accent: Color(0xFF00D2FF), description: 'Colorful!'),
    ColorPreset(name: '🌊 Sunset Beach', primary: Color(0xFFFF6B6B), accent: Color(0xFF4ECDC4), description: 'Tropis'),
    ColorPreset(name: '🍷 Wine', primary: Color(0xFF722F37), accent: Color(0xFFA52A2A), description: 'Klasik & Mewah'),
    ColorPreset(name: '🦄 Unicorn', primary: Color(0xFFB38BFF), accent: Color(0xFFFFB8FF), description: 'Imajinatif & Manis'),
    
    // Contrast
    ColorPreset(name: '🎯 Black & Yellow', primary: Color(0xFF000000), accent: Color(0xFFFFEB3B), description: 'Berani & Kontras'),
    ColorPreset(name: '🎯 Purple & Gold', primary: Color(0xFF7B2FBE), accent: Color(0xFFFFD700), description: 'Mewah & Anggun'),
    
    // Gradient Style
    ColorPreset(name: '🎨 Sunset Gradient', primary: Color(0xFFFF512F), accent: Color(0xFFDD2476), description: 'Gradien Sunset'),
    ColorPreset(name: '🎨 Ocean Gradient', primary: Color(0xFF00C9FF), accent: Color(0xFF92FE9D), description: 'Gradien Ocean'),
    ColorPreset(name: '🎨 Midnight Gradient', primary: Color(0xFF4A00E0), accent: Color(0xFF8E2DE2), description: 'Gradien Midnight'),
    
    // Jewel Tones
    ColorPreset(name: '💎 Ruby', primary: Color(0xFFE0115F), accent: Color(0xFF9B111E), description: 'Berharga & Elegan'),
    ColorPreset(name: '💎 Sapphire', primary: Color(0xFF0F52BA), accent: Color(0xFF0A1172), description: 'Mulia & Anggun'),
    ColorPreset(name: '💎 Emerald', primary: Color(0xFF50C878), accent: Color(0xFF2E8B57), description: 'Mewah & Asri'),
    ColorPreset(name: '💎 Amethyst', primary: Color(0xFF9966CC), accent: Color(0xFF7B2FBE), description: 'Mistik & Elegan'),
    
    // Earth Tones
    ColorPreset(name: '🏔️ Terracotta', primary: Color(0xFFE2725B), accent: Color(0xFFCC5533), description: 'Hangat & Alami'),
    ColorPreset(name: '🏔️ Sand', primary: Color(0xFFC2B280), accent: Color(0xFFD2B48C), description: 'Natural & Tenang'),
  ];

  // ========== GET ALL PRESETS ==========
  static List<ColorPreset> get allPresets => colorPresets;

  // ========== GET BY CATEGORY ==========
  static List<ColorPreset> getPresetsByCategory(String category) {
    switch (category) {
      case 'signature':
        return colorPresets.where((p) => 
          p.name.contains('Royal') || p.name.contains('Magma') || p.name.contains('Frost') || 
          p.name.contains('Poison') || p.name.contains('Sunset') || p.name.contains('Midnight')
        ).toList();
      case 'neon':
        return colorPresets.where((p) => p.name.contains('⚡')).toList();
      case 'purple':
        return colorPresets.where((p) => 
          p.name.contains('💜') || p.name.contains('Violet') || p.name.contains('Lavender') || 
          p.name.contains('Purple') || p.name.contains('Amethyst')
        ).toList();
      case 'pink':
        return colorPresets.where((p) => 
          p.name.contains('❤️') || p.name.contains('Pink') || p.name.contains('Rose') || p.name.contains('Magenta')
        ).toList();
      case 'blue':
        return colorPresets.where((p) => 
          p.name.contains('💙') || p.name.contains('Blue') || p.name.contains('Navy') || p.name.contains('Sapphire')
        ).toList();
      case 'green':
        return colorPresets.where((p) => 
          p.name.contains('💚') || p.name.contains('Green') || p.name.contains('Emerald') || p.name.contains('Mint')
        ).toList();
      case 'orange':
        return colorPresets.where((p) => 
          p.name.contains('🧡') || p.name.contains('💛') || p.name.contains('Orange') || 
          p.name.contains('Yellow') || p.name.contains('Gold')
        ).toList();
      case 'dark':
        return colorPresets.where((p) => 
          p.name.contains('🖤') || p.name.contains('Dark') || p.name.contains('Shadow') || p.name.contains('Charcoal')
        ).toList();
      case 'metallic':
        return colorPresets.where((p) => 
          p.name.contains('✨') || p.name.contains('Silver') || p.name.contains('Gold') || p.name.contains('Platinum')
        ).toList();
      case 'special':
        return colorPresets.where((p) => 
          p.name.contains('🌌') || p.name.contains('🌈') || p.name.contains('🌊') || 
          p.name.contains('🍷') || p.name.contains('🦄') || p.name.contains('🌅')
        ).toList();
      case 'jewel':
        return colorPresets.where((p) => 
          p.name.contains('💎') && (
            p.name.contains('Ruby') || p.name.contains('Sapphire') || p.name.contains('Emerald') || 
            p.name.contains('Amethyst') || p.name.contains('Topaz') || p.name.contains('Citrine')
          )
        ).toList();
      case 'earth':
        return colorPresets.where((p) => p.name.contains('🏔️')).toList();
      default:
        return colorPresets;
    }
  }

  // ========== RANDOM PRESET ==========
  static ColorPreset getRandomPreset() {
    final random = DateTime.now().millisecondsSinceEpoch % colorPresets.length;
    return colorPresets[random.toInt()];
  }

  static ColorPreset getRandomByCategory(String category) {
    final list = getPresetsByCategory(category);
    if (list.isEmpty) return colorPresets[0];
    final random = DateTime.now().millisecondsSinceEpoch % list.length;
    return list[random.toInt()];
  }

  // ========== CONSTRUCTOR ==========
  ThemeProvider() {
    _loadSavedTheme();
  }

  // ========== LOAD SAVED THEME ==========
  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _currentPresetIndex = prefs.getInt('theme_preset_index') ?? 0;
    _isDarkMode = prefs.getBool('theme_dark_mode') ?? true;
    _customGradientEnabled = prefs.getBool('theme_custom_gradient') ?? true;
    _glowIntensity = prefs.getDouble('theme_glow_intensity') ?? 0.5;
    _applyPresetByIndex(_currentPresetIndex);
    notifyListeners();
  }

  // ========== SAVE THEME ==========
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_preset_index', _currentPresetIndex);
    await prefs.setBool('theme_dark_mode', _isDarkMode);
    await prefs.setBool('theme_custom_gradient', _customGradientEnabled);
    await prefs.setDouble('theme_glow_intensity', _glowIntensity);
  }

  // ========== APPLY PRESET ==========
  void applyPreset(ColorPreset preset) {
    final index = colorPresets.indexWhere((p) => p.name == preset.name);
    if (index != -1) {
      _applyPresetByIndex(index);
      _saveTheme();
      notifyListeners();
    }
  }

  void _applyPresetByIndex(int index) {
    if (index >= 0 && index < colorPresets.length) {
      _currentPresetIndex = index;
      _primaryColor = colorPresets[index].primary;
      _accentColor = colorPresets[index].accent;
      _secondaryColor = Color.lerp(_primaryColor, _accentColor, 0.5)!;
    }
  }

  void applyPresetByName(String name) {
    final index = colorPresets.indexWhere((p) => p.name.contains(name) || p.name == name);
    if (index != -1) {
      _applyPresetByIndex(index);
      _saveTheme();
      notifyListeners();
    }
  }

  void applyRandomPreset() {
    final random = DateTime.now().millisecondsSinceEpoch % colorPresets.length;
    _applyPresetByIndex(random.toInt());
    _saveTheme();
    notifyListeners();
  }

  void applyRandomByCategory(String category) {
    final preset = getRandomByCategory(category);
    applyPreset(preset);
  }

  bool isActivePreset(ColorPreset preset) {
    return _primaryColor == preset.primary && _accentColor == preset.accent;
  }

  // ========== THEME ACTIONS ==========
  void resetToDefault() {
    _currentPresetIndex = 0;
    _primaryColor = _defaultPrimary;
    _accentColor = _defaultAccent;
    _secondaryColor = _defaultSecondary;
    _saveTheme();
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveTheme();
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    _saveTheme();
    notifyListeners();
  }

  void toggleCustomGradient() {
    _customGradientEnabled = !_customGradientEnabled;
    _saveTheme();
    notifyListeners();
  }

  void setGlowIntensity(double value) {
    _glowIntensity = value;
    _saveTheme();
    notifyListeners();
  }

  // ========== GETTERS LANJUTAN ==========
  ColorPreset get currentPreset => colorPresets[_currentPresetIndex];
  String get currentPresetName => colorPresets[_currentPresetIndex].name;
  int get currentPresetIndex => _currentPresetIndex;
  int get totalPresets => colorPresets.length;

  // ========== HELPER METHODS ==========
  TextStyle getHeadingStyle({double fontSize = 20, FontWeight fontWeight = FontWeight.bold, Color? color}) {
    return TextStyle(
      color: color ?? textPrimaryColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: 'Rajdhani',
      letterSpacing: 1,
    );
  }

  TextStyle getBodyStyle({double fontSize = 14, FontWeight fontWeight = FontWeight.normal, Color? color}) {
    return TextStyle(
      color: color ?? textSecondaryColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: 'Rajdhani',
    );
  }

  TextStyle getNeonTextStyle({double fontSize = 16, FontWeight fontWeight = FontWeight.bold}) {
    return TextStyle(
      color: primaryColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: 'Rajdhani',
      letterSpacing: 2,
      shadows: [
        Shadow(color: primaryGlow, blurRadius: 8, offset: const Offset(0, 0)),
      ],
    );
  }
}