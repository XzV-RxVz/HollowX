// splash_screen.dart
// DEATHTR4SH - Splash Screen Premium Edition

import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'dashboard_page.dart';
import 'login_page.dart';
import 'theme_provider.dart';

class SplashScreen extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String sessionKey;
  final String expiredDate;
  final List<Map<String, dynamic>> listBug;
  final List<dynamic> news;

  const SplashScreen({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.sessionKey,
    required this.expiredDate,
    required this.listBug,
    required this.news,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _fadeSkip;
  late Animation<double> _fadeQuote;
  late Animation<double> _fadeSubtitle;

  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  bool _navigated = false;

  // DEATHTR4SH Colors
  static const Color _primaryRed = Color(0xFFDC143C);
  static const Color _accentRed = Color(0xFFFF1744);
  static const Color _darkRed = Color(0xFF8B0000);
  static const Color _goldAccent = Color(0xFFFFD700);
  static const Color _darkBg = Color(0xFF000000);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _initAnimations();
    _initVideo();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    
    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );

    _fadeSkip = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.5, 0.85, curve: Curves.easeOut)),
    );

    _fadeQuote = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.25, 0.6, curve: Curves.easeOut)),
    );

    _fadeSubtitle = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.15, 0.45, curve: Curves.easeOut)),
    );

    _animationController.forward();
  }

  void _initVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/splash.mp4');
    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() => _videoInitialized = true);
      _videoController.setLooping(false);
      _videoController.setVolume(0.8);
      _videoController.play();

      _videoController.addListener(_onVideoListener);
    }).catchError((e) {
      debugPrint('Video error: $e');
      Future.delayed(const Duration(seconds: 2), () => _goToDashboard());
    });
  }

  void _onVideoListener() {
    if (!mounted || _navigated) return;
    final pos = _videoController.value.position;
    final dur = _videoController.value.duration;
    if (dur.inMilliseconds > 0 && pos >= dur - const Duration(milliseconds: 200)) {
      _goToDashboard();
    }
  }

  void _goToDashboard() {
    if (_navigated || !mounted) return;
    _navigated = true;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => DashboardPage(
          username: widget.username,
          password: widget.password,
          role: widget.role,
          expiredDate: widget.expiredDate,
          listBug: widget.listBug,
          sessionKey: widget.sessionKey,
          news: widget.news,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _videoController.removeListener(_onVideoListener);
    _videoController.dispose();
    _animationController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ===== VIDEO BACKGROUND =====
          if (_videoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    _primaryRed.withOpacity(0.15),
                    _darkRed.withOpacity(0.2),
                    _darkBg,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [_primaryRed, _accentRed],
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Loading...",
                      style: TextStyle(
                        color: _primaryRed.withOpacity(0.4),
                        fontSize: 12,
                        letterSpacing: 2,
                        fontFamily: 'FontX',
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ===== GLOW EFFECT =====
          Positioned(
            top: size.height * 0.15,
            left: size.width * 0.1,
            right: size.width * 0.1,
            child: IgnorePointer(
              child: Container(
                height: size.height * 0.4,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      _primaryRed.withOpacity(0.1),
                      _accentRed.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===== OVERLAY =====
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.35,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _darkBg.withOpacity(0.5),
                    _darkBg.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          // ===== SKIP BUTTON =====
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeSkip,
              child: GestureDetector(
                onTap: _goToDashboard,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryRed.withOpacity(0.25),
                        _accentRed.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _primaryRed.withOpacity(0.3),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryRed.withOpacity(0.15),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "SKIP",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 1.8,
                          fontFamily: 'FontX',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: _primaryRed.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===== TEXT CONTENT =====
          Positioned(
            top: size.height * 0.35,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeIn,
              child: ScaleTransition(
                scale: _scaleIn,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ===== DEATHTR4SH DENGAN GLOW MERAH =====
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _primaryRed,
                          _accentRed,
                          _goldAccent,
                          _primaryRed,
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ).createShader(bounds),
                      child: Text(
                        "DEATHTR4SH",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'FontX',
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 6,
                          height: 1.1,
                          shadows: [
                            // ===== OUTLINE TEBAL =====
                            Shadow(
                              blurRadius: 12,
                              color: Colors.black.withOpacity(0.95),
                            ),
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black.withOpacity(0.8),
                            ),
                            // ===== GLOW MERAH =====
                            Shadow(
                              blurRadius: 40,
                              color: _primaryRed.withOpacity(0.5),
                            ),
                            Shadow(
                              blurRadius: 80,
                              color: _primaryRed.withOpacity(0.3),
                            ),
                            Shadow(
                              blurRadius: 120,
                              color: _accentRed.withOpacity(0.15),
                            ),
                            // ===== GLOW EMAS =====
                            Shadow(
                              blurRadius: 60,
                              color: _goldAccent.withOpacity(0.1),
                            ),
                            // ===== GLOW PUTIH =====
                            Shadow(
                              blurRadius: 20,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ===== SUBTITLE =====
                    FadeTransition(
                      opacity: _fadeSubtitle,
                      child: Text(
                        "THE NEW GENERATION",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'FontX',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _primaryRed.withOpacity(0.6),
                          letterSpacing: 8,
                          shadows: [
                            Shadow(
                              blurRadius: 15,
                              color: _primaryRed.withOpacity(0.3),
                            ),
                            Shadow(
                              blurRadius: 30,
                              color: _primaryRed.withOpacity(0.15),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== DIVIDER =====
                    Container(
                      width: 100,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primaryRed.withOpacity(0.1),
                            _primaryRed,
                            _goldAccent,
                            _primaryRed,
                            _primaryRed.withOpacity(0.1),
                          ],
                          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryRed.withOpacity(0.4),
                            blurRadius: 12,
                          ),
                          BoxShadow(
                            color: _goldAccent.withOpacity(0.2),
                            blurRadius: 25,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== QUOTE =====
                    FadeTransition(
                      opacity: _fadeQuote,
                      child: Text(
                        "meninggi tanpa merendahkan orang lain",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 2.5,
                          height: 1.6,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black.withOpacity(0.9),
                            ),
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.7),
                            ),
                            Shadow(
                              blurRadius: 25,
                              color: _primaryRed.withOpacity(0.2),
                            ),
                            Shadow(
                              blurRadius: 50,
                              color: _accentRed.withOpacity(0.1),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ===== DECORATIVE DOTS =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _primaryRed.withOpacity(
                              index == 2 ? 0.6 : 0.2,
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: index == 2
                                ? [
                                    BoxShadow(
                                      color: _primaryRed.withOpacity(0.4),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===== VERSION =====
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeSkip,
              child: Column(
                children: [
                  Text(
                    "Thanks For Join And Support DeathTr4sh",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      color: _primaryRed.withOpacity(0.2),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "This is DeathTr4sh",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      color: Colors.white.withOpacity(0.12),
                      fontSize: 8,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}