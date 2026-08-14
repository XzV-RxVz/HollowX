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
// THEME PROVIDER (ULTIMATE EDITION - 150+ COLORS)
// ====================================================
class ThemeProvider extends ChangeNotifier {
  // ========== DEFAULT COLOR (UNGU - SxC ExecX) ==========
  static const Color _defaultPrimary = Color(0xFF7B2FBE);
  static const Color _defaultAccent = Color(0xFFD44BFF);

  Color _primaryColor = _defaultPrimary;
  Color _accentColor = _defaultAccent;
  bool _isDarkMode = true;
  int _currentPresetIndex = 0;

  // ========== GETTERS ==========
  Color get primaryColor => _primaryColor;
  Color get accentColor => _accentColor;
  bool get isDarkMode => _isDarkMode;

  Color get backgroundColor => _isDarkMode ? const Color(0xFF0D0015) : const Color(0xFFF5F0FF);
  Color get textPrimaryColor => _isDarkMode ? const Color(0xFFF3E8FF) : const Color(0xFF1A0035);
  Color get textSecondaryColor => _isDarkMode ? const Color(0xFF9D7BC0) : const Color(0xFF6B4E8A);
  Color get glassPrimary => _isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFF7B2FBE).withOpacity(0.05);
  Color get glassSecondary => _isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFF7B2FBE).withOpacity(0.08);
  Color get borderColor => _isDarkMode ? const Color(0x40C084FC) : const Color(0xFF9D4EDD).withOpacity(0.3);
  Color get surfaceColor => _isDarkMode ? const Color(0x1AB87FFF) : const Color(0xFF9D4EDD).withOpacity(0.08);
  
  // ===== FIX: GETTER bg UNTUK GLOBAL_CHAT_PAGE =====
  Color get bg => _isDarkMode ? const Color(0xFF0A0A0F) : const Color(0xFFF5F0FF);

  // ========== COLOR PRESETS (150+ WARNA UNIK) ==========
  static const List<ColorPreset> colorPresets = [
    // ==================== SIGNATURE COLLECTION ====================
    ColorPreset(name: '👑 Royal Purple', primary: Color(0xFF7B2FBE), accent: Color(0xFFD44BFF), description: 'Signature SxC ExecX'),
    ColorPreset(name: '🔥 Magma Core', primary: Color(0xFFFF4500), accent: Color(0xFFFFD700), description: 'Enerjik & Berapi-api'),
    ColorPreset(name: '🧊 Frost Bite', primary: Color(0xFF00BFFF), accent: Color(0xFFE0FFFF), description: 'Dingin & Mematikan'),
    ColorPreset(name: '🌿 Poison Ivy', primary: Color(0xFF00FF7F), accent: Color(0xFF006400), description: 'Beracun & Eksotis'),
    ColorPreset(name: '🌅 Sunset Vibes', primary: Color(0xFFFF6B35), accent: Color(0xFFFFB347), description: 'Nuansa Senja'),
    ColorPreset(name: '🌙 Midnight Galaxy', primary: Color(0xFF1A1A2E), accent: Color(0xFFE94560), description: 'Misterius & Elegan'),
    
    // ==================== NEON EXPLOSION ====================
    ColorPreset(name: '⚡ Neon Rave', primary: Color(0xFF00FF88), accent: Color(0xFFFF00FF), description: 'Party Mode ON!'),
    ColorPreset(name: '⚡ Cyberpunk 2077', primary: Color(0xFFFF007F), accent: Color(0xFF00F0FF), description: 'Futuristik'),
    ColorPreset(name: '⚡ Laser Beam', primary: Color(0xFF00FFFF), accent: Color(0xFFFF00FF), description: 'Cyan + Magenta'),
    ColorPreset(name: '⚡ Acid Trip', primary: Color(0xFFCCFF00), accent: Color(0xFFFF00CC), description: 'Psikedelik'),
    ColorPreset(name: '⚡ Vaporwave 88', primary: Color(0xFFFF71CE), accent: Color(0xFF01CDFE), description: 'Retro 80an'),
    ColorPreset(name: '⚡ Outrun Sunset', primary: Color(0xFFFF0055), accent: Color(0xFF00FFFF), description: 'Synthwave Style'),
    ColorPreset(name: '⚡ Matrix Code', primary: Color(0xFF00FF41), accent: Color(0xFF008F11), description: 'The One'),
    ColorPreset(name: '⚡ Electric Blue', primary: Color(0xFF0066FF), accent: Color(0xFF00D4FF), description: 'Menyala abangku'),
    ColorPreset(name: '⚡ Atomic Lime', primary: Color(0xFFBFFF00), accent: Color(0xFFFF00BF), description: 'Ledakan Energi'),
    ColorPreset(name: '⚡ Ultra Violet', primary: Color(0xFF5F00FF), accent: Color(0xFF00FF5F), description: 'Cahaya Ungu Misterius'),
    
    // ==================== UNGU & PINK (Purple/Pink Series) ====================
    ColorPreset(name: '💜 Deep Violet', primary: Color(0xFF4A148C), accent: Color(0xFF9C27B0), description: 'Mewah & Anggun'),
    ColorPreset(name: '💜 Soft Lavender', primary: Color(0xFFBF8FE8), accent: Color(0xFF9D4EDD), description: 'Lembut & Menenangkan'),
    ColorPreset(name: '💜 Neon Purple', primary: Color(0xFFAA00FF), accent: Color(0xFFE040FB), description: 'Mencolok'),
    ColorPreset(name: '💜 Dark Plum', primary: Color(0xFF3D0066), accent: Color(0xFF7B2FBE), description: 'Gelap & Misterius'),
    ColorPreset(name: '💜 Wisteria', primary: Color(0xFF9B59B6), accent: Color(0xFF8E44AD), description: 'Anggun'),
    ColorPreset(name: '💜 Grape Soda', primary: Color(0xFF6F2DA8), accent: Color(0xFFD291BC), description: 'Manis & Segar'),
    ColorPreset(name: '💜 Orchid', primary: Color(0xFFDA70D6), accent: Color(0xFFBA55D3), description: 'Eksotis'),
    ColorPreset(name: '💜 Purple Haze', primary: Color(0xFF8080FF), accent: Color(0xFFCC66FF), description: 'Mistik'),
    ColorPreset(name: '💜 Lavender', primary: Color(0xFFE6E6FA), accent: Color(0xFFDDA0DD), description: 'Lembut & Elegan'),
    ColorPreset(name: '💜 Periwinkle', primary: Color(0xFFCCCCFF), accent: Color(0xFF9999FF), description: 'Kalem & Menenangkan'),
    ColorPreset(name: '💜 Mulberry', primary: Color(0xFFC54B8C), accent: Color(0xFF8E3179), description: 'Manis & Eksotis'),
    ColorPreset(name: '💜 Fuchsia', primary: Color(0xFFE84989), accent: Color(0xFFAD1457), description: 'Berani & Mencolok'),
    ColorPreset(name: '💜 Magenta', primary: Color(0xFFFF00FF), accent: Color(0xFF8B008B), description: 'Vibrant & Enerjik'),
    
    // ==================== HOT PINK & RED (Red/Pink Series) ====================
    ColorPreset(name: '❤️ Hot Pink', primary: Color(0xFFFF69B4), accent: Color(0xFFFF1493), description: 'Berani & Seksi'),
    ColorPreset(name: '❤️ Crimson Red', primary: Color(0xFFDC143C), accent: Color(0xFFFF6B6B), description: 'Berani & Klasik'),
    ColorPreset(name: '❤️ Rose Gold', primary: Color(0xFFE91E63), accent: Color(0xFFF06292), description: 'Mewah & Glamor'),
    ColorPreset(name: '❤️ Ruby Red', primary: Color(0xFFD32F2F), accent: Color(0xFFB71C1C), description: 'Berharga & Elegan'),
    ColorPreset(name: '❤️ Bubblegum', primary: Color(0xFFFFC0CB), accent: Color(0xFFFF69B4), description: 'Imut & Ceria'),
    ColorPreset(name: '❤️ Blood Moon', primary: Color(0xFF800020), accent: Color(0xFFFF4444), description: 'Dramatis'),
    ColorPreset(name: '❤️ Strawberry', primary: Color(0xFFFC5A8D), accent: Color(0xFFFF9A9E), description: 'Manis & Segar'),
    ColorPreset(name: '❤️ Valentine', primary: Color(0xFFFF1493), accent: Color(0xFFFF69B4), description: 'Romantis'),
    ColorPreset(name: '❤️ Fire Engine', primary: Color(0xFFCE2029), accent: Color(0xFFFF4500), description: 'Berani & Garang'),
    ColorPreset(name: '❤️ Cherry Blossom', primary: Color(0xFFFFB7C5), accent: Color(0xFFFDA9C4), description: 'Lembut & Romantis'),
    ColorPreset(name: '❤️ Watermelon', primary: Color(0xFFFC4A75), accent: Color(0xFFE83A5A), description: 'Segar & Manis'),
    ColorPreset(name: '❤️ Brick Red', primary: Color(0xFFCB4154), accent: Color(0xFFB22222), description: 'Klasik & Berani'),
    
    // ==================== BLUE OCEAN (Blue Series) ====================
    ColorPreset(name: '💙 Ocean Deep', primary: Color(0xFF1A237E), accent: Color(0xFF3949AB), description: 'Dalam & Tenang'),
    ColorPreset(name: '💙 Sky High', primary: Color(0xFF87CEEB), accent: Color(0xFF4169E1), description: 'Cerlang & Bebas'),
    ColorPreset(name: '💙 Cobalt Blue', primary: Color(0xFF0047AB), accent: Color(0xFF6495ED), description: 'Solid & Kuat'),
    ColorPreset(name: '💙 Azure', primary: Color(0xFF007FFF), accent: Color(0xFF00BFFF), description: 'Segar'),
    ColorPreset(name: '💙 Sapphire', primary: Color(0xFF0F52BA), accent: Color(0xFF2E5A88), description: 'Mulia'),
    ColorPreset(name: '💙 Arctic', primary: Color(0xFF264653), accent: Color(0xFF2A9D8F), description: 'Dingin & Tenang'),
    ColorPreset(name: '💙 Electric Indigo', primary: Color(0xFF4B0082), accent: Color(0xFF6A0DAD), description: 'Misterius'),
    ColorPreset(name: '💙 Baby Blue', primary: Color(0xFF89CFF0), accent: Color(0xFFA0CFEE), description: 'Lembut & Ceria'),
    ColorPreset(name: '💙 Steel Blue', primary: Color(0xFF4682B4), accent: Color(0xFF5C91B6), description: 'Solid & Profesional'),
    ColorPreset(name: '💙 Navy', primary: Color(0xFF000080), accent: Color(0xFF0000CD), description: 'Klasik & Elegan'),
    ColorPreset(name: '💙 Teal', primary: Color(0xFF008080), accent: Color(0xFF20B2AA), description: 'Segar & Natural'),
    ColorPreset(name: '💙 Ice Blue', primary: Color(0xFFDBEAFF), accent: Color(0xFFB8D4FF), description: 'Dingin & Bersih'),
    
    // ==================== GREEN NATURE (Green Series) ====================
    ColorPreset(name: '💚 Emerald', primary: Color(0xFF00A86B), accent: Color(0xFF2DD4BF), description: 'Mewah & Asri'),
    ColorPreset(name: '💚 Forest', primary: Color(0xFF2E7D32), accent: Color(0xFF1B5E20), description: 'Alami & Teduh'),
    ColorPreset(name: '💚 Neon Mint', primary: Color(0xFF4ADE80), accent: Color(0xFF059669), description: 'Segar & Enerjik'),
    ColorPreset(name: '💚 Lime', primary: Color(0xFF32CD32), accent: Color(0xFF9ACD32), description: 'Ceria'),
    ColorPreset(name: '💚 Jungle', primary: Color(0xFF29AB87), accent: Color(0xFF228B22), description: 'Eksotis'),
    ColorPreset(name: '💚 Seaweed', primary: Color(0xFF2E8B57), accent: Color(0xFF3CB371), description: 'Natural'),
    ColorPreset(name: '💚 Matcha', primary: Color(0xFF8B9B5F), accent: Color(0xFFA3B18A), description: 'Hangat & Natural'),
    ColorPreset(name: '💚 Apple Green', primary: Color(0xFF8DB600), accent: Color(0xFF9ACD32), description: 'Segar & Ceria'),
    ColorPreset(name: '💚 Mint Cream', primary: Color(0xFFF5FFFA), accent: Color(0xFF98FB98), description: 'Lembut & Segar'),
    ColorPreset(name: '💚 Olive', primary: Color(0xFF808000), accent: Color(0xFFBDB76B), description: 'Natural & Hangat'),
    ColorPreset(name: '💚 Sage', primary: Color(0xFFBCB88A), accent: Color(0xFF9CAF88), description: 'Lembut & Elegan'),
    ColorPreset(name: '💚 Fern', primary: Color(0xFF4F7942), accent: Color(0xFF6B8E23), description: 'Alami & Teduh'),
    
    // ==================== ORANGE ENERGY (Orange/Yellow Series) ====================
    ColorPreset(name: '🧡 Tangerine', primary: Color(0xFFF28500), accent: Color(0xFFFFA500), description: 'Enerjik'),
    ColorPreset(name: '🧡 Pumpkin', primary: Color(0xFFFF7518), accent: Color(0xFFFFA559), description: 'Hangat'),
    ColorPreset(name: '🧡 Amber', primary: Color(0xFFFFBF00), accent: Color(0xFFFF8F00), description: 'Klasik & Hangat'),
    ColorPreset(name: '💛 Golden', primary: Color(0xFFFFD700), accent: Color(0xFFFFA500), description: 'Mewah & Berkilau'),
    ColorPreset(name: '💛 Lemon', primary: Color(0xFFF0E68C), accent: Color(0xFFFFFACD), description: 'Ceria & Cerah'),
    ColorPreset(name: '💛 Honey', primary: Color(0xFFDAA520), accent: Color(0xFFB8860B), description: 'Manis & Hangat'),
    ColorPreset(name: '🧡 Coral Reef', primary: Color(0xFFFF7F50), accent: Color(0xFFFF6B6B), description: 'Tropis'),
    ColorPreset(name: '🧡 Mango', primary: Color(0xFFFFA500), accent: Color(0xFFFF8C00), description: 'Tropis & Segar'),
    ColorPreset(name: '💛 Banana', primary: Color(0xFFFFE135), accent: Color(0xFFFFF000), description: 'Ceria & Cemerlang'),
    ColorPreset(name: '🧡 Papaya', primary: Color(0xFFFF6800), accent: Color(0xFFFF5000), description: 'Tropis & Enerjik'),
    ColorPreset(name: '💛 Mustard', primary: Color(0xFFE1AD01), accent: Color(0xFFC49102), description: 'Hangat & Unik'),
    ColorPreset(name: '🧡 Carrot', primary: Color(0xFFED7117), accent: Color(0xFFED5A00), description: 'Segar & Alami'),
    
    // ==================== CYAN & TEAL (Cool Series) ====================
    ColorPreset(name: '💎 Cyan', primary: Color(0xFF00FFFF), accent: Color(0xFF00CED1), description: 'Segar'),
    ColorPreset(name: '💎 Teal', primary: Color(0xFF008080), accent: Color(0xFF20B2AA), description: 'Elegan'),
    ColorPreset(name: '💎 Aqua', primary: Color(0xFF7FFFD4), accent: Color(0xFF40E0D0), description: 'Tropis'),
    ColorPreset(name: '💎 Turquoise', primary: Color(0xFF40E0D0), accent: Color(0xFF48D1CC), description: 'Ceria'),
    ColorPreset(name: '💎 Cerulean', primary: Color(0xFF007BA7), accent: Color(0xFF009ACD), description: 'Tenang'),
    ColorPreset(name: '💎 Aquamarine', primary: Color(0xFF7FFFD4), accent: Color(0xFF66CDAA), description: 'Segar & Menenangkan'),
    ColorPreset(name: '💎 Seafoam', primary: Color(0xFF9FE2BF), accent: Color(0xFFB2FFC2), description: 'Lembut & Alami'),
    ColorPreset(name: '💎 Caribbean', primary: Color(0xFF00CC99), accent: Color(0xFF00B386), description: 'Tropis & Eksotis'),
    
    // ==================== PASTEL DREAM (Soft Series) ====================
    ColorPreset(name: '🌸 Pastel Pink', primary: Color(0xFFFFB6C1), accent: Color(0xFFFFC0CB), description: 'Imut & Manis'),
    ColorPreset(name: '🌸 Pastel Blue', primary: Color(0xFFADD8E6), accent: Color(0xFFB0E0E6), description: 'Lembut & Tenang'),
    ColorPreset(name: '🌸 Pastel Green', primary: Color(0xFF98FB98), accent: Color(0xFF90EE90), description: 'Segar'),
    ColorPreset(name: '🌸 Pastel Purple', primary: Color(0xFFD8BFD8), accent: Color(0xFFDDA0DD), description: 'Anggun'),
    ColorPreset(name: '🌸 Pastel Yellow', primary: Color(0xFFFFFACD), accent: Color(0xFFFAFAD2), description: 'Ceria'),
    ColorPreset(name: '🌸 Pastel Orange', primary: Color(0xFFFFDAB9), accent: Color(0xFFFFE4B5), description: 'Hangat'),
    ColorPreset(name: '🌸 Pastel Mint', primary: Color(0xFFD0F0C0), accent: Color(0xFFC8E6C9), description: 'Segar & Natural'),
    ColorPreset(name: '🌸 Pastel Lavender', primary: Color(0xFFBDB5D5), accent: Color(0xFFCEC3E8), description: 'Lembut & Menenangkan'),
    ColorPreset(name: '🌸 Pastel Peach', primary: Color(0xFFFFD1BC), accent: Color(0xFFFFCBA4), description: 'Hangat & Lembut'),
    ColorPreset(name: '🌸 Pastel Lilac', primary: Color(0xFFC8A2C8), accent: Color(0xFFD291BC), description: 'Anggun & Lembut'),
    
    // ==================== DARK & MONOCHROME (Dark Series) ====================
    ColorPreset(name: '🖤 Shadow', primary: Color(0xFF1A1A1A), accent: Color(0xFF333333), description: 'Minimalis'),
    ColorPreset(name: '🖤 Dark Knight', primary: Color(0xFF1F1F2F), accent: Color(0xFF3A3A4A), description: 'Gelap & Berwibawa'),
    ColorPreset(name: '🖤 Slate', primary: Color(0xFF708090), accent: Color(0xFF778899), description: 'Netral'),
    ColorPreset(name: '🖤 Charcoal', primary: Color(0xFF36454F), accent: Color(0xFF4A5D6B), description: 'Maskulin'),
    ColorPreset(name: '🖤 Steel', primary: Color(0xFF4682B4), accent: Color(0xFF5F9EA0), description: 'Solid'),
    ColorPreset(name: '🖤 Ash', primary: Color(0xFF6C757D), accent: Color(0xFF8D99AE), description: 'Netral Modern'),
    ColorPreset(name: '🖤 Obsidian', primary: Color(0xFF000000), accent: Color(0xFF2C2C2C), description: 'Murni & Elegan'),
    ColorPreset(name: '🖤 Gunmetal', primary: Color(0xFF2C3539), accent: Color(0xFF455A64), description: 'Solid & Modern'),
    ColorPreset(name: '🖤 Graphite', primary: Color(0xFF383838), accent: Color(0xFF606060), description: 'Profesional & Elegan'),
    
    // ==================== METALLIC SHINE ====================
    ColorPreset(name: '✨ Silver', primary: Color(0xFFC0C0C0), accent: Color(0xFFE0E0E0), description: 'Mewah & Elegan'),
    ColorPreset(name: '✨ Gold', primary: Color(0xFFFFD700), accent: Color(0xFFFFC107), description: 'Berharga'),
    ColorPreset(name: '✨ Bronze', primary: Color(0xFFCD7F32), accent: Color(0xFFD2691E), description: 'Klasik'),
    ColorPreset(name: '✨ Copper', primary: Color(0xFFB87333), accent: Color(0xFFDA8A67), description: 'Hangat'),
    ColorPreset(name: '✨ Platinum', primary: Color(0xFFE5E4E2), accent: Color(0xFFCED0D0), description: 'Premium'),
    ColorPreset(name: '✨ Rose Gold', primary: Color(0xFFB76E79), accent: Color(0xFFD4A5A5), description: 'Glamor'),
    ColorPreset(name: '✨ Titanium', primary: Color(0xFF878681), accent: Color(0xFFA9A9A9), description: 'Modern & Kuat'),
    ColorPreset(name: '✨ Chrome', primary: Color(0xFFDBE2E9), accent: Color(0xFFECF0F1), description: 'Bersih & Modern'),
    
    // ==================== SPECIAL & UNIQUE ====================
    ColorPreset(name: '🌌 Galaxy', primary: Color(0xFF200B3F), accent: Color(0xFF9B59B6), description: 'Luar Angkasa'),
    ColorPreset(name: '🌈 Rainbow', primary: Color(0xFFFF006E), accent: Color(0xFF00D2FF), description: 'Colorful!'),
    ColorPreset(name: '🎨 Pastel Rainbow', primary: Color(0xFFFFB3BA), accent: Color(0xFFBAFFC9), description: 'Ceria & Lembut'),
    ColorPreset(name: '🌊 Sunset Beach', primary: Color(0xFFFF6B6B), accent: Color(0xFF4ECDC4), description: 'Tropis'),
    ColorPreset(name: '🏔️ Mountain View', primary: Color(0xFF2C3E50), accent: Color(0xFFE74C3C), description: 'Alami'),
    ColorPreset(name: '🍷 Wine', primary: Color(0xFF722F37), accent: Color(0xFFA52A2A), description: 'Klasik & Mewah'),
    ColorPreset(name: '☕ Coffee', primary: Color(0xFF6F4E37), accent: Color(0xFFD2691E), description: 'Hangat & Nyaman'),
    ColorPreset(name: '🍫 Chocolate', primary: Color(0xFF3E2723), accent: Color(0xFF795548), description: 'Manis & Hangat'),
    ColorPreset(name: '🍀 Lucky Green', primary: Color(0xFF00695C), accent: Color(0xFF00BFA5), description: 'Keberuntungan'),
    ColorPreset(name: '🐉 Dragon Fire', primary: Color(0xFFD32F2F), accent: Color(0xFFFF9800), description: 'Berani & Garang'),
    ColorPreset(name: '🦄 Unicorn', primary: Color(0xFFB38BFF), accent: Color(0xFFFFB8FF), description: 'Imajinatif & Manis'),
    ColorPreset(name: '🌅 Aurora', primary: Color(0xFF00FF87), accent: Color(0xFF00B2FF), description: 'Alami & Magis'),
    ColorPreset(name: '🏝️ Tropical', primary: Color(0xFFFF6B6B), accent: Color(0xFF00D2D3), description: 'Tropis & Ceria'),
    ColorPreset(name: '🌿 Sage Green', primary: Color(0xFF9CAF88), accent: Color(0xFF8FBC8F), description: 'Alami & Menenangkan'),
    ColorPreset(name: '🪸 Coral', primary: Color(0xFFFF7F50), accent: Color(0xFFFF6B6B), description: 'Tropis & Hangat'),
    
    // ==================== CONTRAST POP (High Contrast) ====================
    ColorPreset(name: '🎯 Black & Yellow', primary: Color(0xFF000000), accent: Color(0xFFFFEB3B), description: 'Berani & Kontras'),
    ColorPreset(name: '🎯 White & Blue', primary: Color(0xFFFFFFFF), accent: Color(0xFF2196F3), description: 'Bersih & Profesional'),
    ColorPreset(name: '🎯 Red & White', primary: Color(0xFFF44336), accent: Color(0xFFFFFFFF), description: 'Berani & Bersih'),
    ColorPreset(name: '🎯 Green & Black', primary: Color(0xFF00E676), accent: Color(0xFF000000), description: 'Berani & Enerjik'),
    ColorPreset(name: '🎯 Purple & Gold', primary: Color(0xFF7B2FBE), accent: Color(0xFFFFD700), description: 'Mewah & Anggun'),
    ColorPreset(name: '🎯 Orange & Blue', primary: Color(0xFFFF6B35), accent: Color(0xFF2196F3), description: 'Dinamis & Kontras'),
    
    // ==================== GRADIENT STYLE ====================
    ColorPreset(name: '🎨 Sunset Gradient', primary: Color(0xFFFF512F), accent: Color(0xFFDD2476), description: 'Gradien Sunset'),
    ColorPreset(name: '🎨 Ocean Gradient', primary: Color(0xFF00C9FF), accent: Color(0xFF92FE9D), description: 'Gradien Ocean'),
    ColorPreset(name: '🎨 Midnight Gradient', primary: Color(0xFF4A00E0), accent: Color(0xFF8E2DE2), description: 'Gradien Midnight'),
    ColorPreset(name: '🎨 Fire Gradient', primary: Color(0xFFFF6B35), accent: Color(0xFFF09819), description: 'Gradien Fire'),
    ColorPreset(name: '🎨 Forest Gradient', primary: Color(0xFF11998E), accent: Color(0xFF38EF7D), description: 'Gradien Hutan'),
    ColorPreset(name: '🎨 Berry Gradient', primary: Color(0xFFB224EF), accent: Color(0xFF7579FF), description: 'Gradien Berry'),
    ColorPreset(name: '🎨 Peach Gradient', primary: Color(0xFFED213A), accent: Color(0xFF93291E), description: 'Gradien Peach'),
    
    // ==================== MULTICOLOR (Multi Color Combinations) ====================
    ColorPreset(name: '🌈 Pride', primary: Color(0xFFFF0000), accent: Color(0xFF9400D3), description: 'Rainbow Vibes'),
    ColorPreset(name: '🌈 Cotton Candy', primary: Color(0xFFFFB7B2), accent: Color(0xFFB5F0FF), description: 'Manis & Lembut'),
    ColorPreset(name: '🌈 Autumn', primary: Color(0xFFD2691E), accent: Color(0xFFB8860B), description: 'Nuansa Autumn'),
    ColorPreset(name: '🌈 Spring', primary: Color(0xFF98FB98), accent: Color(0xFFFFB6C1), description: 'Nuansa Spring'),
    ColorPreset(name: '🌈 Summer', primary: Color(0xFFFFD700), accent: Color(0xFFFF6347), description: 'Nuansa Summer'),
    ColorPreset(name: '🌈 Winter', primary: Color(0xFF00BFFF), accent: Color(0xFFE0FFFF), description: 'Nuansa Winter'),
    ColorPreset(name: '🌈 Sunset', primary: Color(0xFFFF7E5F), accent: Color(0xFFFEB47B), description: 'Nuansa Sunset'),
    ColorPreset(name: '🌈 Sunrise', primary: Color(0xFFFFA17A), accent: Color(0xFFFF7E5F), description: 'Nuansa Sunrise'),
    
    // ==================== JEWEL TONES (Batu Mulia) ====================
    ColorPreset(name: '💎 Ruby', primary: Color(0xFFE0115F), accent: Color(0xFF9B111E), description: 'Berharga & Elegan'),
    ColorPreset(name: '💎 Sapphire', primary: Color(0xFF0F52BA), accent: Color(0xFF0A1172), description: 'Mulia & Anggun'),
    ColorPreset(name: '💎 Emerald', primary: Color(0xFF50C878), accent: Color(0xFF2E8B57), description: 'Mewah & Asri'),
    ColorPreset(name: '💎 Amethyst', primary: Color(0xFF9966CC), accent: Color(0xFF7B2FBE), description: 'Mistik & Elegan'),
    ColorPreset(name: '💎 Topaz', primary: Color(0xFFFFC87C), accent: Color(0xFFFFA500), description: 'Cerah & Berkilau'),
    ColorPreset(name: '💎 Citrine', primary: Color(0xFFE4C484), accent: Color(0xFFD4AF37), description: 'Hangat & Berkilau'),
    ColorPreset(name: '💎 Peridot', primary: Color(0xFFB4E664), accent: Color(0xFF9ACD32), description: 'Segar & Natural'),
    ColorPreset(name: '💎 Aquamarine', primary: Color(0xFF7FFFD4), accent: Color(0xFF00CED1), description: 'Segar & Menenangkan'),
    
    // ==================== EARTH TONES (Warna Bumi) ====================
    ColorPreset(name: '🏔️ Terracotta', primary: Color(0xFFE2725B), accent: Color(0xFFCC5533), description: 'Hangat & Alami'),
    ColorPreset(name: '🏔️ Sand', primary: Color(0xFFC2B280), accent: Color(0xFFD2B48C), description: 'Natural & Tenang'),
    ColorPreset(name: '🏔️ Clay', primary: Color(0xFFB66A50), accent: Color(0xFFA0522D), description: 'Alami & Hangat'),
    ColorPreset(name: '🏔️ Stone', primary: Color(0xFFA89F91), accent: Color(0xFF8D867D), description: 'Netral & Elegan'),
    ColorPreset(name: '🏔️ Moss', primary: Color(0xFF8A9A5B), accent: Color(0xFF6B8E23), description: 'Alami & Teduh'),
    ColorPreset(name: '🏔️ Dirt', primary: Color(0xFF9B7653), accent: Color(0xFF8B5A2B), description: 'Alami & Hangat'),
  ];

  // Get all presets
  static List<ColorPreset> get allPresets => colorPresets;
  
  // Get by category
  static List<ColorPreset> getPresetsByCategory(String category) {
    switch (category) {
      case 'signature':
        return colorPresets.where((p) => p.name.contains('Royal') || p.name.contains('Magma') || p.name.contains('Frost') || p.name.contains('Poison') || p.name.contains('Sunset') || p.name.contains('Midnight')).toList();
      case 'neon':
        return colorPresets.where((p) => p.name.contains('⚡')).toList();
      case 'purple':
        return colorPresets.where((p) => p.name.contains('💜') || p.name.contains('Violet') || p.name.contains('Lavender') || p.name.contains('Purple') || p.name.contains('Amethyst')).toList();
      case 'pink':
        return colorPresets.where((p) => p.name.contains('❤️') || p.name.contains('Pink') || p.name.contains('Rose') || p.name.contains('Magenta')).toList();
      case 'blue':
        return colorPresets.where((p) => p.name.contains('💙') || p.name.contains('Blue') || p.name.contains('Navy') || p.name.contains('Sapphire')).toList();
      case 'green':
        return colorPresets.where((p) => p.name.contains('💚') || p.name.contains('Green') || p.name.contains('Emerald') || p.name.contains('Mint')).toList();
      case 'orange':
        return colorPresets.where((p) => p.name.contains('🧡') || p.name.contains('💛') || p.name.contains('Orange') || p.name.contains('Yellow') || p.name.contains('Gold')).toList();
      case 'cyan':
        return colorPresets.where((p) => p.name.contains('💎') && !p.name.contains('Ruby') && !p.name.contains('Sapphire')).toList();
      case 'pastel':
        return colorPresets.where((p) => p.name.contains('🌸')).toList();
      case 'dark':
        return colorPresets.where((p) => p.name.contains('🖤') || p.name.contains('Dark') || p.name.contains('Shadow') || p.name.contains('Charcoal')).toList();
      case 'metallic':
        return colorPresets.where((p) => p.name.contains('✨') || p.name.contains('Silver') || p.name.contains('Gold') || p.name.contains('Platinum')).toList();
      case 'special':
        return colorPresets.where((p) => p.name.contains('🌌') || p.name.contains('🌈') || p.name.contains('🌊') || p.name.contains('🍷') || p.name.contains('🍫') || p.name.contains('🦄') || p.name.contains('🌅')).toList();
      case 'contrast':
        return colorPresets.where((p) => p.name.contains('🎯')).toList();
      case 'gradient':
        return colorPresets.where((p) => p.name.contains('🎨') && p.name.contains('Gradient')).toList();
      case 'multicolor':
        return colorPresets.where((p) => p.name.contains('🌈') && !p.name.contains('Pride')).toList();
      case 'jewel':
        return colorPresets.where((p) => p.name.contains('💎') && (p.name.contains('Ruby') || p.name.contains('Sapphire') || p.name.contains('Emerald') || p.name.contains('Amethyst') || p.name.contains('Topaz') || p.name.contains('Citrine') || p.name.contains('Peridot') || p.name.contains('Aquamarine'))).toList();
      case 'earth':
        return colorPresets.where((p) => p.name.contains('🏔️')).toList();
      default:
        return colorPresets;
    }
  }

  // Get random preset
  static ColorPreset getRandomPreset() {
    final random = DateTime.now().millisecondsSinceEpoch % colorPresets.length;
    return colorPresets[random.toInt()];
  }

  // Get random by category
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
    _applyPresetByIndex(_currentPresetIndex);
    notifyListeners();
  }

  // ========== SAVE THEME ==========
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_preset_index', _currentPresetIndex);
    await prefs.setBool('theme_dark_mode', _isDarkMode);
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

  void resetToDefault() {
    _currentPresetIndex = 0;
    _primaryColor = _defaultPrimary;
    _accentColor = _defaultAccent;
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
  
  Color getLightPrimary() => _primaryColor;
  Color getLightAccent() => _accentColor;

  ColorPreset get currentPreset => colorPresets[_currentPresetIndex];
  String get currentPresetName => colorPresets[_currentPresetIndex].name;
  int get currentPresetIndex => _currentPresetIndex;
  int get totalPresets => colorPresets.length;
}

// ====================================================
// MODEL PRESET WARNA
// ====================================================
class ColorPreset {
  final String name;
  final Color primary;
  final Color accent;

  const ColorPreset({
    required this.name,
    required this.primary,
    required this.accent,
  });
}

// ====================================================
// THEME PROVIDER DENGAN SEMUA FITUR
// ====================================================
class ThemeProvider extends ChangeNotifier {
  // Default colors
  static const Color _defaultPrimary = Color(0xFF9D00FF);
  static const Color _defaultAccent = Color(0xFFCC66FF);
  static const Color _defaultSecondary = Color(0xFF7C4DFF);
  
  // State
  Color _primaryColor = _defaultPrimary;
  Color _accentColor = _defaultAccent;
  Color _secondaryColor = _defaultSecondary;
  bool _isDarkMode = true;
  int _currentPresetIndex = 41;
  bool _customGradientEnabled = true;
  double _glowIntensity = 0.5;

  // ========== COLOR PRESETS (30+ presets) ==========
  static const List<ColorPreset> colorPresets = [
    // Standard Presets
    ColorPreset(name: 'Pure White', primary: Color(0xFFFFFFFF), accent: Color(0xFFCFD8DC)),
    ColorPreset(name: 'Silver', primary: Color(0xFFECEFF1), accent: Color(0xFFB0BEC5)),
    ColorPreset(name: 'Gray', primary: Color(0xFF9E9E9E), accent: Color(0xFF616161)),
    ColorPreset(name: 'Black', primary: Color(0xFF607D8B), accent: Color(0xFF263238)),
    ColorPreset(name: 'Red', primary: Color(0xFFF44336), accent: Color(0xFFB71C1C)),
    ColorPreset(name: 'Pink', primary: Color(0xFFE91E63), accent: Color(0xFF880E4F)),
    ColorPreset(name: 'Purple', primary: Color(0xFF9C27B0), accent: Color(0xFF4A148C)),
    ColorPreset(name: 'Indigo', primary: Color(0xFF3F51B5), accent: Color(0xFF1A237E)),
    ColorPreset(name: 'Blue', primary: Color(0xFF2196F3), accent: Color(0xFF0D47A1)),
    ColorPreset(name: 'Cyan', primary: Color(0xFF00BCD4), accent: Color(0xFF006064)),
    ColorPreset(name: 'Teal', primary: Color(0xFF009688), accent: Color(0xFF004D40)),
    ColorPreset(name: 'Green', primary: Color(0xFF4CAF50), accent: Color(0xFF1B5E20)),
    ColorPreset(name: 'Lime', primary: Color(0xFFCDDC39), accent: Color(0xFF827717)),
    ColorPreset(name: 'Yellow', primary: Color(0xFFFFEB3B), accent: Color(0xFFF57F17)),
    ColorPreset(name: 'Orange', primary: Color(0xFFFF9800), accent: Color(0xFFE65100)),
    ColorPreset(name: 'Brown', primary: Color(0xFF795548), accent: Color(0xFF3E2723)),
    ColorPreset(name: 'Gold', primary: Color(0xFFFFD700), accent: Color(0xFF8B6914)),
    
    // Cyberpunk Presets - UNGU NEON UTAMA
    ColorPreset(name: 'Neon Ice', primary: Color(0xFF00E5FF), accent: Color(0xFF18FFFF)),
    ColorPreset(name: 'Matrix', primary: Color(0xFF00FF41), accent: Color(0xFF008F11)),
    ColorPreset(name: 'Cyber Purple', primary: Color(0xFF9C27B0), accent: Color(0xFFE040FB)),
    ColorPreset(name: 'Blood Neon', primary: Color(0xFFFF1744), accent: Color(0xFFFF5252)),
    ColorPreset(name: 'Sunset Flame', primary: Color(0xFFFF6D00), accent: Color(0xFFFFAB40)),
    ColorPreset(name: 'Golden Lux', primary: Color(0xFFFFD700), accent: Color(0xFFFFB300)),
    ColorPreset(name: 'Pink Plasma', primary: Color(0xFFFF4081), accent: Color(0xFFF50057)),
    ColorPreset(name: 'Blue Aurora', primary: Color(0xFF2979FF), accent: Color(0xFF00B0FF)),
    ColorPreset(name: 'Electric Lime', primary: Color(0xFF76FF03), accent: Color(0xFFC6FF00)),
    ColorPreset(name: 'Neon Emerald', primary: Color(0xFF00E676), accent: Color(0xFF69F0AE)),
    ColorPreset(name: 'Toxic Acid', primary: Color(0xFFB2FF59), accent: Color(0xFFEEFF41)),
    ColorPreset(name: 'Cyber Rose', primary: Color(0xFFFF80AB), accent: Color(0xFFF50057)),
    ColorPreset(name: 'Violet Storm', primary: Color(0xFF7C4DFF), accent: Color(0xFFB388FF)),
    ColorPreset(name: 'Neon Lavender', primary: Color(0xFFB388FF), accent: Color(0xFFEA80FC)),
    ColorPreset(name: 'Electric Magenta', primary: Color(0xFFFF00FF), accent: Color(0xFFFF5CFF)),
    ColorPreset(name: 'Frozen Blue', primary: Color(0xFF00B8FF), accent: Color(0xFF82B1FF)),
    ColorPreset(name: 'Galaxy', primary: Color(0xFF512DA8), accent: Color(0xFF7C4DFF)),
    ColorPreset(name: 'Ocean Pulse', primary: Color(0xFF00ACC1), accent: Color(0xFF18FFFF)),
    ColorPreset(name: 'Firestorm', primary: Color(0xFFFF3D00), accent: Color(0xFFFF6E40)),
    ColorPreset(name: 'Ruby Neon', primary: Color(0xFFD50000), accent: Color(0xFFFF1744)),
    ColorPreset(name: 'Dark Void', primary: Color(0xFF455A64), accent: Color(0xFF263238)),
    ColorPreset(name: 'Midnight Cyber', primary: Color(0xFF0F172A), accent: Color(0xFF334155)),
    ColorPreset(name: 'Holographic', primary: Color(0xFF00E5FF), accent: Color(0xFFFF00FF)),
    ColorPreset(name: 'RGB Fusion', primary: Color(0xFF00E676), accent: Color(0xFFFF1744)),
    ColorPreset(name: 'Synthwave', primary: Color(0xFFFF0080), accent: Color(0xFF7928CA)),
    ColorPreset(name: 'RetroWave', primary: Color(0xFFFF6EC7), accent: Color(0xFF7A5FFF)),
    ColorPreset(name: 'HyperBlue', primary: Color(0xFF00C6FF), accent: Color(0xFF0072FF)),
    ColorPreset(name: 'Dragon Fire', primary: Color(0xFFFF512F), accent: Color(0xFFDD2476)),
    ColorPreset(name: 'Aurora Borealis', primary: Color(0xFF00F260), accent: Color(0xFF0575E6)),
    ColorPreset(name: 'Cyber Gold', primary: Color(0xFFF7971E), accent: Color(0xFFFFD200)),
  ];

  // ========== CONSTRUCTOR ==========
  ThemeProvider() {
    _loadSavedTheme();
  }

  // ========== GETTERS ==========
  Color get primaryColor => _primaryColor;
  Color get accentColor => _accentColor;
  Color get secondaryColor => _secondaryColor;
  bool get isDarkMode => _isDarkMode;
  bool get customGradientEnabled => _customGradientEnabled;
  double get glowIntensity => _glowIntensity;

  // ========== ADDED: primaryColorLight untuk konsistensi ==========
  Color get primaryColorLight => _accentColor;
  Color get primaryColorDark => _primaryColor;

  // ========== ADDED: textDim untuk bug_sender ==========
  Color get textDim => _isDarkMode ? Colors.white.withOpacity(0.25) : Colors.black.withOpacity(0.25);

  // ========== DYNAMIC UI COLORS ==========
  Color get backgroundColor => _isDarkMode ? const Color(0xFF0A0F1A) : const Color(0xFFF5F5F5);
  Color get surfaceColor => _isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFFFFFFF);
  Color get cardColor => _isDarkMode ? const Color(0xFF111C30) : const Color(0xFFFAFAFA);
  Color get textPrimaryColor => _isDarkMode ? Colors.white : Colors.black87;
  Color get textSecondaryColor => _isDarkMode ? Colors.white70 : Colors.black54;
  Color get textHintColor => _isDarkMode ? Colors.white38 : Colors.black38;
  
  // Glassmorphism colors
  Color get glassPrimary => _isDarkMode 
      ? Colors.white.withOpacity(0.05) 
      : Colors.black.withOpacity(0.05);
  Color get glassSecondary => _isDarkMode 
      ? Colors.white.withOpacity(0.08) 
      : Colors.black.withOpacity(0.08);
  Color get glassBorder => _isDarkMode 
      ? Colors.white.withOpacity(0.08) 
      : Colors.black.withOpacity(0.08);
  
  // Glow colors
  Color get primaryGlow => primaryColor.withOpacity(0.3 * _glowIntensity);
  Color get accentGlow => accentColor.withOpacity(0.3 * _glowIntensity);
  Color get strongGlow => primaryColor.withOpacity(0.6 * _glowIntensity);
  
  // Status colors
  Color get successColor => const Color(0xFF00E676);
  Color get errorColor => const Color(0xFFFF2D55);
  Color get warningColor => const Color(0xFFFF9F0A);
  Color get infoColor => const Color(0xFF0A84FF);

  // Gradient backgrounds
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

  // Box decorations dengan glassmorphism + neon glow
  BoxDecoration get glassCardDecoration => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: primaryColor.withOpacity(0.15), width: 1),
    boxShadow: [
      BoxShadow(
        color: primaryGlow,
        blurRadius: 16,
        spreadRadius: 1,
      ),
    ],
  );
  
  BoxDecoration get neonBorderDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: primaryColor.withOpacity(0.4), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: strongGlow,
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ],
  );

  // ========== SAVE/LOAD THEME ==========
  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _currentPresetIndex = prefs.getInt('theme_preset_index') ?? 41;
    _isDarkMode = prefs.getBool('theme_dark_mode') ?? true;
    _customGradientEnabled = prefs.getBool('theme_custom_gradient') ?? true;
    _glowIntensity = prefs.getDouble('theme_glow_intensity') ?? 0.5;
    _applyPresetByIndex(_currentPresetIndex);
    notifyListeners();
  }

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
        Shadow(
          color: primaryGlow,
          blurRadius: 8,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }
}