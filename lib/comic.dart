// comic_page.dart
// DEATHTRASH - COMIC ARSENAL (RED & GOLD EDITION)

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'constants.dart';

class ComicPage extends StatefulWidget {
  const ComicPage({super.key});

  @override
  State<ComicPage> createState() => _ComicPageState();
}

class _ComicPageState extends State<ComicPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _comicList = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _headingText = "HOT COMIC";

  late AnimationController _mainAnimCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchTopManga();
  }

  void _initAnimations() {
    _mainAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _mainAnimCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimCtrl, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _fetchTopManga() async {
    setState(() {
      _isLoading = true;
      _isSearching = false;
      _headingText = "HOT COMIC";
    });
    try {
      final response = await http.get(
        Uri.parse('https://api.jikan.moe/v4/top/manga?limit=20'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _comicList = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching manga: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchManga(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _isSearching = true;
      _headingText = "SEARCH RESULT";
    });
    try {
      final response = await http.get(
        Uri.parse('https://api.jikan.moe/v4/manga?q=$query&limit=20'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _comicList = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error searching manga: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _mainAnimCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: kDeathDarkBg,
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(),
          body: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Stack(
                children: [
                  // Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          kDeathDarkBg,
                          kDeathCardBg,
                          Color(0xFF150A26),
                          kDeathDarkBg,
                        ],
                        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                      ),
                    ),
                  ),

                  // Glow Orbs
                  Positioned(
                    top: -80,
                    right: -60,
                    child: IgnorePointer(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [kDeathRed.withOpacity(0.06), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    left: -80,
                    child: IgnorePointer(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [kDeathGold.withOpacity(0.03), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Grid
                  CustomPaint(
                    size: Size.infinite,
                    painter: _ComicGridPainter(accentColor: kDeathRed),
                  ),

                  // Main Content
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 100),

                        // Header Card
                        _buildHeaderCard(),

                        const SizedBox(height: 20),

                        // Search Bar
                        _buildSearchBar(),

                        const SizedBox(height: 14),

                        // Recommendation Chips
                        _buildRecommendationChips(),

                        const SizedBox(height: 24),

                        // Title Section
                        _buildTitleSection(),

                        const SizedBox(height: 14),

                        // Grid List Comic
                        _isLoading
                            ? _buildLoadingShimmer()
                            : _comicList.isEmpty
                                ? _buildEmptyState()
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.7,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: _comicList.length,
                                    itemBuilder: (context, index) {
                                      final manga = _comicList[index];
                                      return _buildComicCard(manga);
                                    },
                                  ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // APP BAR - DEATHTRASH THEME
  // ============================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kDeathCardBg.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kDeathBorder),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kDeathRed,
            size: 16,
          ),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kDeathRed.withOpacity(0.15), kDeathRedDark.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: kDeathRed.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [kDeathRed, kDeathGold],
          ).createShader(bounds),
          child: Text(
            "COMIC DEATHTR4SH",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFamily: 'FontX',
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
      centerTitle: true,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.black.withOpacity(0.3)),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER CARD
  // ============================================================
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kDeathCardBg.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDeathBorder),
        boxShadow: [
          BoxShadow(
            color: kDeathRed.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kDeathRed, kDeathRedDark],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kDeathRed.withOpacity(0.2),
                  blurRadius: 16,
                ),
              ],
            ),
            child: FaIcon(
              FontAwesomeIcons.bookOpenReader,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [kDeathRed, kDeathGold],
            ).createShader(bounds),
            child: Text(
              "COMIC DEATHTR4SH",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: 'FontX',
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Discover & Read Your Favorite Manga",
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: kDeathCardBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDeathBorder),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          hintText: "Search manga / comic...",
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.12),
            fontSize: 12,
            fontFamily: 'monospace',
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: kDeathRed.withOpacity(0.3),
            size: 20,
          ),
          suffixIcon: GestureDetector(
            onTap: () => _searchManga(_searchController.text),
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kDeathRed, kDeathRedDark],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: kDeathRed.withOpacity(0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "GO",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      fontFamily: 'FontX',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        onSubmitted: (value) => _searchManga(value),
      ),
    );
  }

  // ============================================================
  // RECOMMENDATION CHIPS
  // ============================================================
  Widget _buildRecommendationChips() {
    final List<String> recs = ["One Piece", "Naruto", "Solo Leveling", "Berserk", "Chainsaw Man"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "QUICK SEARCH",
          style: TextStyle(
            color: Colors.white.withOpacity(0.08),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            fontFamily: 'FontX',
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: recs.map((text) => _buildRecChip(text)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          _searchController.text = text;
          _searchManga(text);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: kDeathCardBg.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kDeathRed.withOpacity(0.06)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TITLE SECTION
  // ============================================================
  Widget _buildTitleSection() {
    return Row(
      children: [
        Container(
          height: 18,
          width: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kDeathRed, kDeathGold],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _headingText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'FontX',
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        if (_isSearching)
          GestureDetector(
            onTap: _fetchTopManga,
            child: Text(
              "RESET",
              style: TextStyle(
                color: kDeathRed,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                fontFamily: 'FontX',
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // LOADING SHIMMER
  // ============================================================
  Widget _buildLoadingShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: kDeathCardBg.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kDeathBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: kDeathCardBg.withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      color: kDeathCardBg.withOpacity(0.3),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 8,
                      width: 60,
                      color: kDeathCardBg.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: Colors.white.withOpacity(0.05),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            "No comics found",
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMIC CARD
  // ============================================================
  Widget _buildComicCard(dynamic manga) {
    String imageUrl = manga['images']['jpg']['image_url'] ?? '';
    String title = manga['title'] ?? 'Unknown';
    String score = manga['score'] != null ? manga['score'].toString() : 'N/A';
    String type = manga['type'] ?? 'Manga';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComicDetailPage(mangaData: manga),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: kDeathCardBg.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kDeathBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: kDeathCardBg.withOpacity(0.3),
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    // Badge Score
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: kDeathGold.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: kDeathGold,
                              size: 8,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              score,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Badge Type
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kDeathRed.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "▶ READ",
                    style: TextStyle(
                      color: kDeathRed.withOpacity(0.3),
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'FontX',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// COMIC DETAIL PAGE - DEATHTRASH THEME
// ============================================================
class ComicDetailPage extends StatelessWidget {
  final Map<String, dynamic> mangaData;

  const ComicDetailPage({super.key, required this.mangaData});

  @override
  Widget build(BuildContext context) {
    String imageUrl = mangaData['images']['jpg']['large_image_url'] ??
        mangaData['images']['jpg']['image_url'] ?? '';
    String title = mangaData['title'] ?? 'Unknown';
    String synopsis = mangaData['synopsis'] ?? 'No synopsis available.';
    String status = mangaData['status'] ?? 'Unknown';
    String chapters = mangaData['chapters'] != null ? mangaData['chapters'].toString() : '?';
    String url = mangaData['url'] ?? '';

    return Scaffold(
      backgroundColor: kDeathDarkBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 380,
            floating: false,
            pinned: true,
            backgroundColor: kDeathDarkBg,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: kDeathCardBg.withOpacity(0.3),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          kDeathDarkBg.withOpacity(0.7),
                          kDeathDarkBg,
                          kDeathDarkBg,
                        ],
                        stops: const [0.4, 0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: kDeathRed.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [kDeathRed, kDeathGold],
                    ).createShader(bounds),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'FontX',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Info Badges
                  Row(
                    children: [
                      _buildDetailBadge(Icons.timelapse_rounded, status, kDeathRed),
                      const SizedBox(width: 8),
                      _buildDetailBadge(Icons.book_rounded, "$chapters Ch", kDeathGold),
                      const SizedBox(width: 8),
                      _buildDetailBadge(
                        Icons.star_rounded,
                        "${mangaData['score'] ?? 'N/A'}",
                        kDeathGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          kDeathRed.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Synopsis
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kDeathRed, kDeathRedDark],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "SYNOPSIS",
                        style: TextStyle(
                          color: kDeathRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'FontX',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kDeathCardBg.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kDeathBorder),
                    ),
                    child: Text(
                      synopsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontFamily: 'monospace',
                        height: 1.6,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Read Button
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Could not launch URL"),
                            backgroundColor: kDeathRed,
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kDeathRed, kDeathRedDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: kDeathRed.withOpacity(0.3),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.open_in_browser_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "READ ONLINE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              fontFamily: 'FontX',
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GRID PAINTER
// ============================================================
class _ComicGridPainter extends CustomPainter {
  final Color accentColor;

  _ComicGridPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const step = 30.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final accentPaint = Paint()
      ..color = accentColor.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double x = 0; x <= size.width; x += step * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }
    for (double y = 0; y <= size.height; y += step * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }

    final dotPaint = Paint()
      ..color = accentColor.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    for (double x = 0; x <= size.width; x += step) {
      for (double y = 0; y <= size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}