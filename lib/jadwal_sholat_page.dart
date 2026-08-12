// jadwal_sholat_page.dart
// SxC ExecX - v13 Gen 2 (FULLY ENHANCED)
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class JadwalSholatPage extends StatefulWidget {
  final String sessionKey;
  final String username;

  const JadwalSholatPage({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<JadwalSholatPage> createState() => _JadwalSholatPageState();
}

class _JadwalSholatPageState extends State<JadwalSholatPage> with SingleTickerProviderStateMixin {
  final TextEditingController _cityController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _sholatData;
  String? _errorMessage;
  
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  // Daftar kota populer untuk rekomendasi
  final List<String> _popularCities = [
    "Jakarta", "Surabaya", "Bandung", "Medan", "Semarang",
    "Yogyakarta", "Malang", "Makassar", "Denpasar", "Palembang"
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchJadwalSholat() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      setState(() {
        _errorMessage = "Masukkan nama kota";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _sholatData = null;
    });

    try {
      final url = Uri.parse("https://api.deline.web.id/info/jadwalsholat?kota=$city");
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            _sholatData = data['result'];
          });
        } else {
          setState(() {
            _errorMessage = "Kota '$city' tidak ditemukan";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal mengambil data jadwal sholat";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Koneksi gagal: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectPopularCity(String city) {
    _cityController.text = city;
    _fetchJadwalSholat();
  }

  IconData _getSholatIcon(String name) {
    switch (name) {
      case 'Imsak':
        return Icons.bedtime_rounded;
      case 'Subuh':
        return Icons.brightness_5_rounded;
      case 'Terbit':
        return Icons.wb_sunny_rounded;
      case 'Dzuhur':
        return Icons.sunny_snowing;
      case 'Ashar':
        return Icons.brightness_6_rounded;
      case 'Terbenam':
        return Icons.nightlight_round;
      case 'Maghrib':
        return Icons.nightlight_round;
      case 'Isya':
        return Icons.nights_stay_rounded;
      case 'Tengah Malam':
        return Icons.bedtime_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  String _formatSholatName(String name) {
    switch (name) {
      case 'Fajr': return 'Subuh';
      case 'Sunrise': return 'Terbit';
      case 'Dhuhr': return 'Dzuhur';
      case 'Asr': return 'Ashar';
      case 'Sunset': return 'Terbenam';
      case 'Maghrib': return 'Maghrib';
      case 'Isha': return 'Isya';
      case 'Imsak': return 'Imsak';
      case 'Midnight': return 'Tengah Malam';
      default: return name;
    }
  }

  String _getNextPrayerTime(Map<String, dynamic> waktu) {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    
    final prayerOrder = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];
    final prayerKeyMap = {
      'Subuh': 'Fajr',
      'Dzuhur': 'Dhuhr',
      'Ashar': 'Asr',
      'Maghrib': 'Maghrib',
      'Isya': 'Isha'
    };
    
    for (var prayer in prayerOrder) {
      final key = prayerKeyMap[prayer];
      if (waktu.containsKey(key)) {
        final timeStr = waktu[key].toString();
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          if (hour > currentHour || (hour == currentHour && minute >= currentMinute)) {
            return prayer;
          }
        }
      }
    }
    return 'Subuh';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Scaffold(
          backgroundColor: theme.backgroundColor,
          body: Stack(
            children: [
              // Background
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.5,
                    colors: [theme.primaryColor.withOpacity(0.15), theme.backgroundColor, theme.backgroundColor],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
              CustomPaint(
                size: Size.infinite,
                painter: _SholatGridPainter(accentColor: theme.primaryColor),
              ),
              // Glow orbs
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [theme.primaryColor.withOpacity(0.15), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                left: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [theme.accentColor.withOpacity(0.1), Colors.transparent],
                    ),
                  ),
                ),
              ),
              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom Header
                      _buildHeader(theme),
                      const SizedBox(height: 20),
                      
                      // Search Bar
                      _buildSearchBar(theme),
                      const SizedBox(height: 16),
                      
                      // Popular Cities
                      _buildPopularCities(theme),
                      const SizedBox(height: 20),
                      
                      // Loading
                      if (_isLoading)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 40, height: 40,
                                child: CircularProgressIndicator(color: theme.primaryColor, strokeWidth: 2.5),
                              ),
                              const SizedBox(height: 12),
                              Text('Mengambil data jadwal sholat...', style: TextStyle(color: theme.textSecondaryColor, fontSize: 12)),
                            ],
                          ),
                        ),
                      
                      // Error Message
                      if (_errorMessage != null)
                        _buildErrorCard(theme),
                      
                      // Jadwal Sholat Data
                      if (_sholatData != null) ...[
                        _buildLocationCard(theme),
                        const SizedBox(height: 20),
                        _buildNextPrayerCard(theme),
                        const SizedBox(height: 20),
                        _buildPrayerTimeGrid(theme),
                        const SizedBox(height: 16),
                        _buildInfoNote(theme),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider theme) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.glassPrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.borderColor),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, theme.accentColor]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.4), blurRadius: 14)],
          ),
          child: const Text(
            "JADWAL SHOLAT",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildSearchBar(ThemeProvider theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.glassPrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderColor),
      ),
      child: TextField(
        controller: _cityController,
        style: TextStyle(color: theme.textPrimaryColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: "Cari kota... (contoh: Jakarta, Bandung, Surabaya)",
          hintStyle: TextStyle(color: theme.textSecondaryColor.withOpacity(0.5), fontSize: 12),
          prefixIcon: Icon(Icons.search_rounded, color: theme.primaryColor, size: 20),
          suffixIcon: GestureDetector(
            onTap: _fetchJadwalSholat,
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primaryColor, theme.accentColor]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onSubmitted: (_) => _fetchJadwalSholat(),
      ),
    );
  }

  Widget _buildPopularCities(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "KOTA POPULER",
          style: TextStyle(
            color: theme.textSecondaryColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _popularCities.map((city) {
            return GestureDetector(
              onTap: () => _selectPopularCity(city),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.glassSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Text(
                  city,
                  style: TextStyle(
                    color: theme.textSecondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildErrorCard(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(ThemeProvider theme) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.glassPrimary, theme.glassSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.borderColor),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primaryColor, theme.accentColor]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 15)],
              ),
              child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              _sholatData!['lokasi'] ?? "Tidak diketahui",
              style: TextStyle(
                color: theme.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: theme.glassSecondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 12, color: theme.textSecondaryColor),
                  const SizedBox(width: 6),
                  Text(
                    _sholatData!['tanggal'] ?? "",
                    style: TextStyle(color: theme.textSecondaryColor, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Text(
                _sholatData!['hijri'] ?? "",
                style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextPrayerCard(ThemeProvider theme) {
    final waktu = _sholatData!['waktu'] as Map<String, dynamic>;
    final nextPrayer = _getNextPrayerTime(waktu);
    
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 550),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.primaryColor.withOpacity(0.15), theme.accentColor.withOpacity(0.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primaryColor, theme.accentColor]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.alarm_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "WAKTU SHOLAT BERIKUTNYA",
                    style: TextStyle(
                      color: theme.textSecondaryColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextPrayer,
                    style: TextStyle(
                      color: theme.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.glassPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.borderColor),
              ),
              child: Text(
                _getPrayerTime(waktu, nextPrayer),
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPrayerTime(Map<String, dynamic> waktu, String prayerName) {
    final prayerKeyMap = {
      'Subuh': 'Fajr',
      'Dzuhur': 'Dhuhr',
      'Ashar': 'Asr',
      'Maghrib': 'Maghrib',
      'Isya': 'Isha'
    };
    final key = prayerKeyMap[prayerName];
    if (key != null && waktu.containsKey(key)) {
      return waktu[key].toString();
    }
    return '--:--';
  }

  Widget _buildPrayerTimeGrid(ThemeProvider theme) {
    final waktu = _sholatData!['waktu'] as Map<String, dynamic>;
    final List<String> order = [
      'Imsak', 'Fajr', 'Sunrise', 'Dhuhr', 'Asr', 
      'Sunset', 'Maghrib', 'Isha', 'Midnight'
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "WAKTU SHOLAT",
          style: TextStyle(
            color: theme.textSecondaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.8,
          children: order.where((key) => waktu.containsKey(key)).map((key) {
            return _buildSholatCard(
              name: _formatSholatName(key),
              time: waktu[key].toString(),
              theme: theme,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSholatCard({
    required String name,
    required String time,
    required ThemeProvider theme,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.95 + (value * 0.05), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.glassPrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primaryColor, theme.accentColor]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getSholatIcon(name),
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: theme.textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoNote(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.glassSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.info_outline_rounded, color: theme.primaryColor, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Jadwal sholat berdasarkan lokasi yang dipilih. Waktu menggunakan zona waktu setempat.",
              style: TextStyle(color: theme.textSecondaryColor, fontSize: 10, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Grid Painter
class _SholatGridPainter extends CustomPainter {
  final Color accentColor;
  
  _SholatGridPainter({required this.accentColor});
  
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const step = 28.0;
    
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    final accentPaint = Paint()
      ..color = accentColor.withOpacity(0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double x = 0; x <= size.width; x += step * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }
    for (double y = 0; y <= size.height; y += step * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }
    
    final dotPaint = Paint()
      ..color = accentColor.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    for (double x = 0; x <= size.width; x += step) {
      for (double y = 0; y <= size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SholatGridPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}