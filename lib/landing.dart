// landing_page.dart
// DEATHTR4SH - Entry flow dengan tema merah gradien
// Stage 1: Splash (fade in reveal + progress bar)
// Stage 2: Welcome (info cards + scroll to enter langsung ke /login)
// Stage 3: Navigates to /login

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _Stage { splash, welcome }

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  _Stage _stage = _Stage.splash;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _goToWelcome() {
    if (mounted) setState(() => _stage = _Stage.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _stage == _Stage.splash
            ? _SplashStage(key: const ValueKey('splash'), onDone: _goToWelcome)
            : const _WelcomeStage(key: ValueKey('welcome')),
      ),
    );
  }
}

// ============================================================
// THEME COLORS - DEATHTR4SH
// ============================================================
class DeathTrashTheme {
  static const Color primaryRed = Color(0xFFDC143C);
  static const Color accentRed = Color(0xFFFF1744);
  static const Color darkRed = Color(0xFF8B0000);
  static const Color bloodRed = Color(0xFF4A0000);
  static const Color goldAccent = Color(0xFFFFD700);
}

// ============================================================
// STAGE 1: SPLASH (fade in reveal + progress)
// ============================================================
class _SplashStage extends StatefulWidget {
  final VoidCallback onDone;
  const _SplashStage({super.key, required this.onDone});

  @override
  State<_SplashStage> createState() => _SplashStageState();
}

class _SplashStageState extends State<_SplashStage>
    with SingleTickerProviderStateMixin {
  static const String _fullText = "DEATHTR4SH";

  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  late Animation<double> _letterSpacing;
  late Animation<double> _progress;
  late Animation<double> _glow;
  late Animation<double> _subtitleFade;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _letterSpacing = Tween<double>(begin: 30.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_navigated) {
        _navigated = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) widget.onDone();
        });
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background hitam
        Positioned.fill(
          child: Container(
            color: Colors.black,
          ),
        ),
        // Efek bintang/partikel merah
        Positioned.fill(
          child: CustomPaint(
            painter: _DeathParticlesPainter(),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main Title dengan efek reveal
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          DeathTrashTheme.primaryRed,
                          DeathTrashTheme.accentRed,
                          DeathTrashTheme.goldAccent,
                          DeathTrashTheme.primaryRed,
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ).createShader(bounds),
                      child: Opacity(
                        opacity: _fadeIn.value,
                        child: Transform.scale(
                          scale: _scale.value,
                          child: Text(
                            _fullText,
                            style: TextStyle(
                              fontFamily: 'FontX',
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: _letterSpacing.value,
                              shadows: [
                                Shadow(
                                  blurRadius: 40 * _glow.value,
                                  color: DeathTrashTheme.primaryRed
                                      .withOpacity(0.8 * _glow.value),
                                ),
                                Shadow(
                                  blurRadius: 80 * _glow.value,
                                  color: DeathTrashTheme.accentRed
                                      .withOpacity(0.4 * _glow.value),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    Opacity(
                      opacity: _subtitleFade.value,
                      child: Text(
                        "THE NEW GENERATION",
                        style: TextStyle(
                          fontFamily: 'FontX',
                          color: DeathTrashTheme.primaryRed.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Progress Bar
                    SizedBox(
                      width: 220,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Container(
                              height: 2,
                              color: Colors.white.withOpacity(0.05),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: _progress.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          DeathTrashTheme.primaryRed,
                                          DeathTrashTheme.accentRed,
                                          DeathTrashTheme.goldAccent,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: DeathTrashTheme.primaryRed
                                              .withOpacity(0.4),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "INITIALIZING",
                                style: TextStyle(
                                  fontFamily: 'FontX',
                                  color: Colors.white.withOpacity(0.15),
                                  fontSize: 8,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "${(_progress.value * 100).toInt()}%",
                                style: TextStyle(
                                  fontFamily: 'FontX',
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "DEATHTR4SH V1 GEN 2",
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                color: Colors.white.withOpacity(0.04),
                fontSize: 9,
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STAGE 2: WELCOME - SCROLL TO ENTER (langsung ke /login)
// ============================================================
class _WelcomeStage extends StatefulWidget {
  const _WelcomeStage({super.key});

  @override
  State<_WelcomeStage> createState() => _WelcomeStageState();
}

class _WelcomeStageState extends State<_WelcomeStage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp1;
  late Animation<Offset> _slideUp2;

  final ScrollController _scrollController = ScrollController();
  bool _hasEntered = false;
  bool _showSnackbar = false;
  String _snackbarMessage = "";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideUp1 = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    _slideUp2 = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
    ));

    _controller.forward();

    // Scroll listener
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_hasEntered) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final scrollPercent = maxScroll > 0 ? (currentScroll / maxScroll) * 100 : 0;

    setState(() {
      if (scrollPercent > 50) {
        _showSnackbar = true;
        _snackbarMessage = "Scroll ke atas untuk masuk";
      } else {
        _showSnackbar = false;
      }
    });

    if (scrollPercent >= 85 && !_hasEntered) {
      _hasEntered = true;
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    HapticFeedback.heavyImpact();
    setState(() {
      _snackbarMessage = "Authenticating...";
      _showSnackbar = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed("/login");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background hitam
        Positioned.fill(
          child: Container(
            color: Colors.black,
          ),
        ),
        // Efek partikel merah
        Positioned.fill(
          child: CustomPaint(
            painter: _DeathParticlesPainter2(),
          ),
        ),
        // Scroll Container
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Panel: Welcome Info (full height)
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        FadeTransition(
                          opacity: _fadeIn,
                          child: SlideTransition(
                            position: _slideUp1,
                            child: Column(
                              children: [
                                // Text "WELCOME TO"
                                Text(
                                  "WELCOME TO",
                                  style: TextStyle(
                                    fontFamily: 'FontX',
                                    color: Colors.white.withOpacity(0.2),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Main Title dengan gradien merah
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      DeathTrashTheme.primaryRed,
                                      DeathTrashTheme.accentRed,
                                      DeathTrashTheme.goldAccent,
                                      DeathTrashTheme.primaryRed,
                                    ],
                                    stops: const [0.0, 0.3, 0.6, 1.0],
                                  ).createShader(bounds),
                                  child: const Text(
                                    "DEATHTR4SH",
                                    style: TextStyle(
                                      fontFamily: 'FontX',
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "THE NEW GENERATION",
                                  style: TextStyle(
                                    fontFamily: 'FontX',
                                    color: DeathTrashTheme.primaryRed
                                        .withOpacity(0.5),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        // Info Cards
                        FadeTransition(
                          opacity: _fadeIn,
                          child: SlideTransition(
                            position: _slideUp2,
                            child: Column(
                              children: [
                                _InfoCard(
                                  icon: Icons.security_rounded,
                                  title: "NEW UI AND UX",
                                  subtitle: "update for the deathtr4sh apk display",
                                  color: DeathTrashTheme.primaryRed,
                                ),
                                const SizedBox(height: 12),
                                _InfoCard(
                                  icon: Icons.bolt_rounded,
                                  title: "NEW UPDATE AND OPTIMIZATION",
                                  subtitle: "new function bug new engine",
                                  color: DeathTrashTheme.accentRed,
                                ),
                                const SizedBox(height: 12),
                                _InfoCard(
                                  icon: Icons.devices_rounded,
                                  title: "THANKS FOR",
                                  subtitle: "all user deathtr4sh",
                                  color: DeathTrashTheme.goldAccent,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Scroll Indicator
                        FadeTransition(
                          opacity: _fadeIn,
                          child: Column(
                            children: [
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: DeathTrashTheme.primaryRed
                                    .withOpacity(0.3),
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "SCROLL TO ENTER",
                                style: TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  color: Colors.white.withOpacity(0.12),
                                  fontSize: 8,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Panel kosong untuk trigger scroll (hanya sedikit)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black,
                          DeathTrashTheme.bloodRed.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "Scroll ke atas untuk masuk",
                        style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Snackbar
        Positioned(
          bottom: 40,
          left: 24,
          right: 24,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _showSnackbar ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DeathTrashTheme.bloodRed.withOpacity(0.8),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DeathTrashTheme.primaryRed.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: DeathTrashTheme.primaryRed.withOpacity(0.6),
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _snackbarMessage,
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Footer
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "DEATHTR4SH v1 Gen 2",
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                color: Colors.white.withOpacity(0.03),
                fontSize: 7,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// WIDGETS
// ============================================================
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.03),
            Colors.white.withOpacity(0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAINTERS
// ============================================================
class _DeathParticlesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 0.5 + random.nextDouble() * 1.5;
      final opacity = 0.02 + random.nextDouble() * 0.06;
      final paint = Paint()
        ..color = DeathTrashTheme.primaryRed.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DeathParticlesPainter oldDelegate) => false;
}

class _DeathParticlesPainter2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(123);
    
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 1 + random.nextDouble() * 2;
      final opacity = 0.02 + random.nextDouble() * 0.05;
      final paint = Paint()
        ..color = DeathTrashTheme.primaryRed.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
    
    final linePaint = Paint()
      ..color = DeathTrashTheme.primaryRed.withOpacity(0.02)
      ..strokeWidth = 0.5;
    
    for (int i = 0; i < 6; i++) {
      final random2 = math.Random(i + 100);
      final x = random2.nextDouble() * size.width;
      final y = random2.nextDouble() * size.height;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 50, y - 50),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DeathParticlesPainter2 oldDelegate) => false;
}