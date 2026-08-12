// DEATHTR4SH V1 GEN 2 - ULTIMATE TOOLS EDITION

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'theme_provider.dart';
import 'constants.dart';
import 'youtube_tool.dart';
import 'instagram_tool.dart';
import 'minibrowser_tool.dart';
import 'testfunc.dart';
import 'anime.dart';
import 'spambot.dart';
import 'comic.dart';
import 'netflix_page.dart';
import 'kalkulator.dart';

class ToolsPage extends StatefulWidget {
  final String username;
  final String role;
  final String sessionKey;
  final String expiredDate;
  final VoidCallback onBack;

  const ToolsPage({
    super.key,
    required this.username,
    required this.role,
    required this.sessionKey,
    required this.expiredDate,
    required this.onBack,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ============================================================
  // ANIMATIONS V1 GEN 2
  // ============================================================
  late AnimationController _mainController;
  late AnimationController _glowController;
  late AnimationController _scanController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _glowPulse;
  late Animation<double> _scanLine;

  // ============================================================
  // STATE
  // ============================================================
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategory = 0;
  final List<String> _categories = ['ALL', 'STREAMING', 'UTILITY', 'SOCIAL', 'FUNNY', 'COMIC', 'VIDEO'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();
    _mainController.forward();
    _glowController.forward();
    _scanController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mainController.dispose();
    _glowController.dispose();
    _scanController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _fadeIn = CurvedAnimation(parent: _mainController, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack));
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic));
    _glowPulse = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _scanLine = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _scanController, curve: Curves.linear));
  }

  // ============================================================
  // TOOLS DATA V1 GEN 2
  // ============================================================
  List<Map<String, dynamic>> _getAllTools(ThemeProvider theme) {
    return [
      {
        'id': 'kalkulator',
        'title': 'Kalkulator',
        'subtitle': 'Hitung cepat & akurat',
        'emoji': '🧮',
        'icon': Icons.calculate_rounded,
        'color': kDeathRed,
        'accentColor': kDeathGold,
        'tag': 'UTILITY',
        'page': const KalkulatorApp(),
        'isNew': false,
        'isPremium': false,
      },
      {
        'id': 'netflix',
        'title': 'Netflix',
        'subtitle': 'Streaming film & series',
        'emoji': '🎬',
        'icon': Icons.movie_rounded,
        'color': kDeathRed,
        'accentColor': kDeathGold,
        'tag': 'STREAMING',
        'page': const NetflixPage(),
        'isNew': true,
        'isPremium': false,
      },
      {
        'id': 'anime',
        'title': 'Anime Stream',
        'subtitle': 'Anime subtitle Indonesia',
        'emoji': '🎌',
        'icon': Icons.live_tv_rounded,
        'color': kDeathRed,
        'accentColor': kDeathGold,
        'tag': 'STREAMING',
        'page': const HomeAnimePage(),
        'isNew': true,
        'isPremium': false,
      },
      {
        'id': 'spambot',
        'title': 'Spam Bot',
        'subtitle': 'Kirim spam ke Telegram',
        'emoji': '🤖',
        'icon': FontAwesomeIcons.telegram,
        'color': kDeathRed,
        'accentColor': kDeathGold,
        'tag': 'FUNNY',
        'page': SpamBotPage(sessionKey: widget.sessionKey),
        'isNew': false,
        'isPremium': false,
      },
      {
        'id': 'comic',
        'title': 'Baca Comic',
        'subtitle': 'Manga & komik favorit',
        'emoji': '📚',
        'icon': Icons.book_rounded,
        'color': kDeathRed,
        'accentColor': kDeathGold,
        'tag': 'COMIC',
        'page': const ComicPage(),
        'isNew': false,
        'isPremium': false,
      },
      {
        'id': 'instagram',
        'title': 'Instagram',
        'subtitle': 'Explore IG langsung',
        'emoji': '📸',
        'icon': FontAwesomeIcons.instagram,
        'color': kDeathRed,
        'accentColor': kDeathGold,
        'tag': 'SOCIAL',
        'page': const InstagramToolPage(),
        'isNew': false,
        'isPremium': false,
      },
      {
        'id': 'youtube',
        'title': 'YouTube',
        'subtitle': 'Nonton YouTube di apk',
        'emoji': '▶️',
        'icon': FontAwesomeIcons.youtube,
        'color': kDeathRed,
        'accentColor': kDeathGold,
        'tag': 'VIDEO',
        'page': const YouTubeToolPage(),
        'isNew': false,
        'isPremium': false,
      },
      {
        'id': 'browser',
        'title': 'Mini Browser',
        'subtitle': 'Browser dengan URL bar',
        'emoji': '🌐',
        'icon': Icons.public_rounded,
        'color': kDeathRed,
        'accentColor': kDeathGold,
        'tag': 'UTILITY',
        'page': const MiniBrowserToolPage(),
        'isNew': false,
        'isPremium': false,
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredTools {
    final all = _getAllTools(Provider.of<ThemeProvider>(context, listen: false));
    final filteredByCategory = _selectedCategory == 0
        ? all
        : all.where((tool) => tool['tag'] == _categories[_selectedCategory]).toList();
    
    if (_searchQuery.isEmpty) return filteredByCategory;
    return filteredByCategory.where((tool) {
      final title = (tool['title'] as String).toLowerCase();
      final subtitle = (tool['subtitle'] as String).toLowerCase();
      final tag = (tool['tag'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || subtitle.contains(query) || tag.contains(query);
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final tools = _filteredTools;

    return Scaffold(
      backgroundColor: kDeathDarkBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.8,
            colors: [
              kDeathRed.withOpacity(0.06),
              kDeathDarkBg.withOpacity(0.8),
              kDeathDarkBg,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleIn,
            child: SlideTransition(
              position: _slideUp,
              child: Column(
                children: [
                  _buildAppBar(theme),
                  _buildSearchAndCategory(theme),
                  Expanded(
                    child: _buildToolsGrid(theme, tools),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR V1 GEN 2
  // ============================================================
  Widget _buildAppBar(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kDeathRed.withOpacity(0.08),
            Colors.transparent,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: kDeathRed.withOpacity(0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kDeathRed.withOpacity(0.1), kDeathRedDark.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: kDeathRed.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kDeathRed,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [kDeathRed, kDeathGold],
                      ).createShader(bounds),
                      child: Text(
                        'DEATHTR4SH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'FontX',
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kDeathRed, kDeathRedDark],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'V1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'FontX',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kDeathGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: kDeathGold.withOpacity(0.1)),
                      ),
                      child: Text(
                        'GEN 2',
                        style: TextStyle(
                          color: kDeathGold.withOpacity(0.5),
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'FontX',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${_filteredTools.length} Tools',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.15),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: _glowPulse,
                      builder: (context, _) => Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: kDeathRed.withOpacity(0.2 * _glowPulse.value),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kDeathRed.withOpacity(0.1 * _glowPulse.value),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SYSTEM READY',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.08),
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kDeathRed.withOpacity(0.1), kDeathRedDark.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: kDeathRed.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: kDeathRed,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH & CATEGORY
  // ============================================================
  Widget _buildSearchAndCategory(ThemeProvider theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: kDeathCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kDeathBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  Icons.search_rounded,
                  color: Colors.white.withOpacity(0.1),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search tools...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.08),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withOpacity(0.1),
                        size: 16,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedCategory == index;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = index);
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [kDeathRed, kDeathRedDark],
                          )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : kDeathBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                        fontSize: 9,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TOOLS GRID V1 GEN 2
  // ============================================================
  Widget _buildToolsGrid(ThemeProvider theme, List<Map<String, dynamic>> tools) {
    if (tools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: Colors.white.withOpacity(0.02),
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              'NO TOOLS FOUND',
              style: TextStyle(
                color: Colors.white.withOpacity(0.06),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'FontX',
                letterSpacing: 2,
              ),
            ),
            Text(
              'Try a different search or category',
              style: TextStyle(
                color: Colors.white.withOpacity(0.03),
                fontSize: 9,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildToolCard(tool, theme, index);
      },
    );
  }

  // ============================================================
  // TOOL CARD V1 GEN 2
  // ============================================================
  Widget _buildToolCard(Map<String, dynamic> tool, ThemeProvider theme, int index) {
    final bool isNew = tool['isNew'] as bool;
    final bool isPremium = tool['isPremium'] as bool;
    final String tag = tool['tag'] as String;

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 40)),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          final page = tool['page'] as Widget;
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => page,
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 350),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kDeathCardBg.withOpacity(0.8),
                kDeathDarkBg,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: kDeathBorder,
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: kDeathRed.withOpacity(0.02),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Scan line animation
              if (isNew)
                AnimatedBuilder(
                  animation: _scanLine,
                  builder: (context, _) => Positioned(
                    top: _scanLine.value * 160,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            kDeathRed.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kDeathRed.withOpacity(0.12),
                                kDeathGold.withOpacity(0.04),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: kDeathRed.withOpacity(0.08),
                              width: 0.8,
                            ),
                          ),
                          child: Center(
                            child: tool['icon'] is IconData
                                ? Icon(
                                    tool['icon'] as IconData,
                                    color: kDeathRed,
                                    size: 22,
                                  )
                                : tool['icon'] is FaIconData
                                    ? FaIcon(
                                        tool['icon'] as FaIconData,
                                        color: kDeathRed,
                                        size: 22,
                                      )
                                    : Text(
                                        tool['emoji'] as String,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                          ),
                        ),
                        if (isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [kDeathRed, kDeathGold],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: kDeathRed.withOpacity(0.2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 6,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'FontX',
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tool['title'] as String,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'FontX',
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tool['subtitle'] as String,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.15),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kDeathRed.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: kDeathRed.withOpacity(0.03),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: kDeathRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tag,
                                style: TextStyle(
                                  color: kDeathRed.withOpacity(0.2),
                                  fontSize: 7,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: kDeathGold.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: kDeathGold.withOpacity(0.05)),
                            ),
                            child: Icon(
                              Icons.star_rounded,
                              color: kDeathGold.withOpacity(0.2),
                              size: 10,
                            ),
                          ),
                      ],
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

  // ============================================================
  // FOOTER V1 GEN 2
  // ============================================================
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: kDeathRed.withOpacity(0.03),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: kDeathRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'DEATHTR4SH V1 GEN 2',
            style: TextStyle(
              color: Colors.white.withOpacity(0.04),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              fontFamily: 'FontX',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: kDeathRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}