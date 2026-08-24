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

  static const Color _bgBlack = Color(0xFF07030F);
  static const Color _deepPurple = Color(0xFF4C1D95);
  static const Color _violet500 = Color(0xFF7C3AED);
  static const Color _cyanAccent = Color(0xFF4DE8E8);
  static const Color _magentaAccent = Color(0xFFE879F9);

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
      backgroundColor: _bgBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                    _deepPurple.withOpacity(0.3),
                    _violet500.withOpacity(0.2),
                    _bgBlack,
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
                          colors: [_deepPurple, _violet500],
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
                        color: _violet500.withOpacity(0.4),
                        fontSize: 12,
                        letterSpacing: 2,
                        fontFamily: 'Rajdhani',
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                      _violet500.withOpacity(0.1),
                      _cyanAccent.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

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
                    _bgBlack.withOpacity(0.5),
                    _bgBlack.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

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
                        _violet500.withOpacity(0.25),
                        _cyanAccent.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _violet500.withOpacity(0.3),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _violet500.withOpacity(0.15),
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
                          fontFamily: 'Rajdhani',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: _violet500.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

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
                    Image.asset(
                      'assets/images/Text.png',
                      width: MediaQuery.of(context).size.width * 0.9,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(height: 24),
                    Image.asset(
                      'assets/images/TextX.png',
                      width: MediaQuery.of(context).size.width * 0.6,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeSkip,
              child: Column(
                children: [
                  Text(
                    "Powered By @JustRxVz - @alannxd",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      color: _violet500.withOpacity(0.2),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "HOLLOW EXECUTION v14",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
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