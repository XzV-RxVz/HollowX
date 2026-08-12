// color_settings.dart
// SxC ExecX - v13 Gen 2 (UPGRADED - WITH CATEGORIES & LIVE PREVIEW)
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:flutter/services.dart';

// ─── Shared Purple Palette ────────────────────────────────────────────────────
class SxCColors {
  static const Color deepViolet    = Color(0xFF0D0015);
  static const Color corePurple    = Color(0xFF7B2FBE);
  static const Color vibrantPurple = Color(0xFF9D4EDD);
  static const Color softLavender  = Color(0xFFBF8FE8);
  static const Color accentViolet  = Color(0xFF5E00BB);
  static const Color glowPink      = Color(0xFFD44BFF);
  static const Color surfaceGlass  = Color(0x1AB87FFF);
  static const Color surfaceDark   = Color(0x0FD4B8FF);
  static const Color borderGlow    = Color(0x40C084FC);
  static const Color borderSoft    = Color(0x1AC084FC);
  static const Color textPrimary   = Color(0xFFF3E8FF);
  static const Color textSecondary = Color(0xFF9D7BC0);
  static const Color successGreen  = Color(0xFF00E676);
  static const Color warningOrange = Color(0xFFFFB74D);

  static const LinearGradient primaryGrad = LinearGradient(
    colors: [corePurple, glowPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient deepGrad = LinearGradient(
    colors: [accentViolet, corePurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Category Data ────────────────────────────────────────────────────────────
class ColorCategory {
  final String name;
  final String icon;
  final List<String> presetNames;
  
  const ColorCategory({
    required this.name,
    required this.icon,
    required this.presetNames,
  });
}

const List<ColorCategory> categories = [
  ColorCategory(name: 'SIGNATURE', icon: '👑', presetNames: ['Royal Purple', 'Magma Core', 'Frost Bite', 'Poison Ivy', 'Sunset Vibes', 'Midnight Galaxy']),
  ColorCategory(name: 'NEON', icon: '⚡', presetNames: ['Neon Rave', 'Cyberpunk 2077', 'Laser Beam', 'Acid Trip', 'Vaporwave 88', 'Outrun Sunset', 'Matrix Code', 'Electric Blue']),
  ColorCategory(name: 'PURPLE', icon: '💜', presetNames: ['Deep Violet', 'Soft Lavender', 'Neon Purple', 'Dark Plum', 'Wisteria', 'Grape Soda', 'Orchid', 'Purple Haze']),
  ColorCategory(name: 'PINK & RED', icon: '❤️', presetNames: ['Hot Pink', 'Crimson Red', 'Rose Gold', 'Ruby Red', 'Bubblegum', 'Blood Moon', 'Strawberry', 'Valentine']),
  ColorCategory(name: 'BLUE', icon: '💙', presetNames: ['Ocean Deep', 'Sky High', 'Cobalt Blue', 'Azure', 'Sapphire', 'Arctic', 'Electric Indigo']),
  ColorCategory(name: 'GREEN', icon: '💚', presetNames: ['Emerald', 'Forest', 'Neon Mint', 'Lime', 'Jungle', 'Seaweed', 'Matcha']),
  ColorCategory(name: 'ORANGE & YELLOW', icon: '🧡', presetNames: ['Tangerine', 'Pumpkin', 'Amber', 'Golden', 'Lemon', 'Honey', 'Coral Reef']),
  ColorCategory(name: 'CYAN & TEAL', icon: '💎', presetNames: ['Cyan', 'Teal', 'Aqua', 'Turquoise', 'Cerulean']),
  ColorCategory(name: 'PASTEL', icon: '🌸', presetNames: ['Pastel Pink', 'Pastel Blue', 'Pastel Green', 'Pastel Purple', 'Pastel Yellow', 'Pastel Orange', 'Pastel Mint']),
  ColorCategory(name: 'DARK', icon: '🖤', presetNames: ['Shadow', 'Dark Knight', 'Slate', 'Charcoal', 'Steel', 'Ash']),
  ColorCategory(name: 'METALLIC', icon: '✨', presetNames: ['Silver', 'Gold', 'Bronze', 'Copper', 'Platinum', 'Rose Gold']),
  ColorCategory(name: 'SPECIAL', icon: '🎨', presetNames: ['Galaxy', 'Rainbow', 'Pastel Rainbow', 'Sunset Beach', 'Mountain View', 'Wine', 'Coffee', 'Chocolate', 'Lucky Green', 'Dragon Fire']),
  ColorCategory(name: 'CONTRAST', icon: '🎯', presetNames: ['Black & Yellow', 'White & Blue', 'Red & White', 'Green & Black']),
  ColorCategory(name: 'GRADIENT', icon: '🌊', presetNames: ['Sunset Gradient', 'Ocean Gradient', 'Midnight Gradient', 'Fire Gradient']),
  ColorCategory(name: 'MULTICOLOR', icon: '🌈', presetNames: ['Pride', 'Cotton Candy', 'Autumn', 'Spring', 'Summer', 'Winter']),
];

// ─── Show Helper ─────────────────────────────────────────────────────────────
void showColorSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _ColorSettingsSheet(),
  ).then((_) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    theme.notifyListeners();
  });
}

// ─── Bottom Sheet (UPGRADED) ─────────────────────────────────────────────────
class _ColorSettingsSheet extends StatefulWidget {
  const _ColorSettingsSheet();

  @override
  State<_ColorSettingsSheet> createState() => _ColorSettingsSheetState();
}

class _ColorSettingsSheetState extends State<_ColorSettingsSheet> with SingleTickerProviderStateMixin {
  String _selectedCategory = 'ALL';
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _mainCategories = ['ALL', 'SIGNATURE', 'NEON', 'PURPLE', 'PINK & RED', 'BLUE', 'GREEN', 'ORANGE & YELLOW', 'CYAN & TEAL', 'PASTEL', 'DARK', 'METALLIC', 'SPECIAL', 'CONTRAST', 'GRADIENT', 'MULTICOLOR'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _mainCategories.length, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic);
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = _mainCategories[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<ColorPreset> _getFilteredPresets() {
    if (_selectedCategory == 'ALL') {
      return ThemeProvider.colorPresets;
    }
    final category = categories.firstWhere(
      (c) => c.name == _selectedCategory,
      orElse: () => categories.first,
    );
    return ThemeProvider.colorPresets.where((p) => 
      category.presetNames.contains(p.name) || 
      category.presetNames.any((n) => p.name.contains(n))
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final filteredPresets = _getFilteredPresets();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1C0040), Color(0xFF0D0020)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: SxCColors.borderGlow, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: SxCColors.corePurple.withOpacity(0.4),
                blurRadius: 50,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle bar ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 48, height: 5,
                  decoration: BoxDecoration(
                    gradient: SxCColors.primaryGrad,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: SxCColors.corePurple.withOpacity(0.5), blurRadius: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Header with live preview ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: SxCColors.deepGrad,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: SxCColors.corePurple.withOpacity(0.5), blurRadius: 12),
                        ],
                      ),
                      child: const Icon(Icons.palette_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (b) => SxCColors.primaryGrad.createShader(b),
                            child: const Text(
                              "COLOR SETTINGS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Pilih gaya warna favoritmu",
                            style: TextStyle(
                              color: SxCColors.textSecondary.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Live preview badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.primaryColor, theme.accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SxCColors.borderGlow),
                        boxShadow: [
                          BoxShadow(color: theme.primaryColor.withOpacity(0.4), blurRadius: 12),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Gradient Preview Bar ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.primaryColor, theme.accentColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.color_lens_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            theme.currentPresetName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PREVIEW WARNA AKTIF',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Indicator dot
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Category Tabs ───────────────────────────────────────────
              SizedBox(
                height: 42,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  indicator: BoxDecoration(
                    gradient: SxCColors.primaryGrad,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: SxCColors.corePurple.withOpacity(0.4), blurRadius: 8),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: Colors.white,
                  unselectedLabelColor: SxCColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: _mainCategories.map((category) {
                    final icon = categories.firstWhere(
                      (c) => c.name == category,
                      orElse: () => const ColorCategory(name: 'ALL', icon: '🎨', presetNames: []),
                    ).icon;
                    return Tab(
                      child: Row(
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(category == 'ALL' ? 'ALL' : category),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // ── Divider ─────────────────────────────────────────────────
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, SxCColors.borderGlow, Colors.transparent],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Color Grid ──────────────────────────────────────────────
              Flexible(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: filteredPresets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.palette_outlined, color: SxCColors.textSecondary.withOpacity(0.3), size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada warna di kategori ini',
                                style: TextStyle(color: SxCColors.textSecondary.withOpacity(0.5), fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1,
                          ),
                          itemCount: filteredPresets.length,
                          itemBuilder: (ctx, i) {
                            final preset = filteredPresets[i];
                            final isActive = theme.isActivePreset(preset);
                            return TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 150 + (i * 20)),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutBack,
                              builder: (ctx, scale, child) {
                                return Transform.scale(
                                  scale: 0.8 + (scale * 0.2),
                                  child: child,
                                );
                              },
                              child: GestureDetector(
                                onTap: () {
                                  theme.applyPreset(preset);
                                  HapticFeedback.lightImpact();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [preset.primary, preset.accent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isActive ? Colors.white : Colors.transparent,
                                      width: isActive ? 2.5 : 0,
                                    ),
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: preset.primary.withOpacity(0.65),
                                              blurRadius: 16,
                                              spreadRadius: 3,
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: preset.primary.withOpacity(0.2),
                                              blurRadius: 8,
                                            ),
                                          ],
                                  ),
                                  child: isActive
                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                      : Tooltip(
                                          message: preset.name,
                                          child: Container(),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Action Buttons ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Random button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          theme.applyRandomPreset();
                          HapticFeedback.mediumImpact();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2D1B69), Color(0xFF1A0F3D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: SxCColors.borderSoft),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shuffle_rounded, size: 16, color: SxCColors.vibrantPurple),
                              const SizedBox(width: 8),
                              Text(
                                'RANDOM',
                                style: TextStyle(
                                  color: SxCColors.vibrantPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Reset button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          theme.resetToDefault();
                          HapticFeedback.mediumImpact();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: SxCColors.surfaceGlass,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: SxCColors.borderSoft),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.refresh_rounded, size: 16, color: SxCColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                'RESET',
                                style: TextStyle(
                                  color: SxCColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
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

              const SizedBox(height: 16),

              // ── Footer ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                        color: SxCColors.successGreen,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: SxCColors.successGreen.withOpacity(0.5), blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${ThemeProvider.colorPresets.length}+ Color Presets Available",
                      style: TextStyle(
                        color: SxCColors.textSecondary.withOpacity(0.4),
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                        color: SxCColors.warningOrange,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: SxCColors.warningOrange.withOpacity(0.5), blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── FAB (UPGRADED) ──────────────────────────────────────────────────────────
class ColorSettingsFAB extends StatelessWidget {
  const ColorSettingsFAB({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return GestureDetector(
      onTap: () => showColorSettingsSheet(context),
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.primaryColor, theme.accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SxCColors.borderGlow, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.palette_outlined, color: Colors.white, size: 24),
      ),
    );
  }
}