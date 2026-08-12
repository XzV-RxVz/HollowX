// DEATHTR4SH V1 GEN 2 - WEATHER PAGE

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'constants.dart';

class WeatherPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final VoidCallback? onBack;

  const WeatherPage({
    super.key,
    required this.sessionKey,
    required this.username,
    this.onBack,
  });

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _cityController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _weatherData;
  String? _errorMessage;

  late AnimationController _mainController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _mainController.forward();
  }

  void _initAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _mainController, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack));
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
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
      _weatherData = null;
    });

    try {
      final url = Uri.parse("https://api.siputzx.my.id/api/info/cuaca?q=$city");
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            _weatherData = data['data'];
          });
        } else {
          setState(() {
            _errorMessage = "Kota tidak ditemukan";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal mengambil data cuaca";
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

  IconData _getWeatherIconData(String weatherDesc) {
    if (weatherDesc.contains("Cerah")) return Icons.wb_sunny_rounded;
    if (weatherDesc.contains("Berawan")) return Icons.cloud_rounded;
    if (weatherDesc.contains("Hujan")) return Icons.beach_access_rounded;
    if (weatherDesc.contains("Petir")) return Icons.flash_on_rounded;
    if (weatherDesc.contains("Kabut")) return Icons.cloud_queue_rounded;
    if (weatherDesc.contains("Angin")) return Icons.air_rounded;
    return Icons.help_outline_rounded;
  }

  IconData _getWindDirectionIcon(String wd) {
    if (wd == "U") return Icons.navigation_rounded;
    if (wd == "S") return Icons.south_rounded;
    if (wd == "T") return Icons.east_rounded;
    if (wd == "B") return Icons.west_rounded;
    if (wd == "TL") return Icons.north_east_rounded;
    if (wd == "TG") return Icons.south_east_rounded;
    if (wd == "BL") return Icons.north_west_rounded;
    if (wd == "BG") return Icons.south_west_rounded;
    return Icons.compass_calibration_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    
    Map<dynamic, dynamic>? currentWeather;
    String? locationName;
    String? provinsi;
    String? kotkab;

    if (_weatherData != null) {
      final weatherList = _weatherData!['weather'] as List?;
      if (weatherList != null && weatherList.isNotEmpty) {
        final firstWeather = weatherList[0];
        final lokasi = firstWeather['lokasi'] as Map?;
        if (lokasi != null) {
          provinsi = lokasi['provinsi'];
          kotkab = lokasi['kotkab'];
          locationName = lokasi['desa'] ?? lokasi['kecamatan'];
        }
        
        final cuacaList = firstWeather['cuaca'] as List?;
        if (cuacaList != null && cuacaList.isNotEmpty) {
          final firstCuaca = cuacaList[0] as List?;
          if (firstCuaca != null && firstCuaca.isNotEmpty) {
            currentWeather = firstCuaca[0] as Map?;
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: kDeathDarkBg,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.8,
            colors: [
              kDeathRed.withOpacity(0.04),
              kDeathDarkBg,
            ],
          ),
        ),
        child: CustomPaint(
          painter: _GridPainter(accentColor: kDeathRed),
          child: FadeTransition(
            opacity: _fadeIn,
            child: ScaleTransition(
              scale: _scaleIn,
              child: SlideTransition(
                position: _slideUp,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 20),
                      if (_isLoading) _buildLoadingIndicator(),
                      if (_errorMessage != null) _buildErrorWidget(),
                      if (_weatherData != null && currentWeather != null) ...[
                        _buildLocationCard(locationName, provinsi, kotkab),
                        const SizedBox(height: 16),
                        _buildCurrentWeatherCard(currentWeather),
                        const SizedBox(height: 16),
                        _buildWeatherDetails(currentWeather),
                        const SizedBox(height: 16),
                        _buildForecast(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wb_sunny_rounded, color: kDeathRed, size: 16),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [kDeathRed, kDeathGold],
              ).createShader(bounds),
              child: Text(
                'WEATHER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kDeathCardBg.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kDeathBorder),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: kDeathRed,
            size: 16,
          ),
        ),
        onPressed: () {
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: kDeathCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDeathBorder),
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
              controller: _cityController,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'ShareTechMono',
              ),
              decoration: InputDecoration(
                hintText: "Cari kota...",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.08),
                  fontSize: 12,
                  fontFamily: 'ShareTechMono',
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onSubmitted: (_) => _fetchWeather(),
            ),
          ),
          GestureDetector(
            onTap: _fetchWeather,
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kDeathRed, kDeathRedDark],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kDeathRed.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING INDICATOR
  // ============================================================
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            child: CircularProgressIndicator(
              color: kDeathRed,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'LOADING WEATHER...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.04),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              fontFamily: 'FontX',
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR WIDGET
  // ============================================================
  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDeathRed.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDeathRed.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: kDeathRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: kDeathRed.withOpacity(0.3),
                fontSize: 12,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION CARD
  // ============================================================
  Widget _buildLocationCard(String? locationName, String? provinsi, String? kotkab) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kDeathCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kDeathBorder),
        boxShadow: [
          BoxShadow(
            color: kDeathRed.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kDeathRed.withOpacity(0.04),
              shape: BoxShape.circle,
              border: Border.all(color: kDeathRed.withOpacity(0.04)),
            ),
            child: Icon(Icons.location_on_rounded, color: kDeathRed, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            locationName ?? "Tidak diketahui",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'FontX',
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (provinsi != null)
            Text(
              "$provinsi, $kotkab",
              style: TextStyle(
                color: Colors.white.withOpacity(0.15),
                fontSize: 11,
                fontFamily: 'ShareTechMono',
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CURRENT WEATHER CARD
  // ============================================================
  Widget _buildCurrentWeatherCard(Map<dynamic, dynamic> currentWeather) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kDeathRed, kDeathRedDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kDeathRed.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(
              _getWeatherIconData(currentWeather['weather_desc'] ?? ""),
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${currentWeather['t']?.toString() ?? "?"}°C",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'FontX',
                  letterSpacing: 1,
                ),
              ),
              Text(
                currentWeather['weather_desc'] ?? "Tidak diketahui",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WEATHER DETAILS
  // ============================================================
  Widget _buildWeatherDetails(Map<dynamic, dynamic> currentWeather) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kDeathCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kDeathBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.water_drop_rounded,
                  label: "Kelembaban",
                  value: "${currentWeather['hu'] ?? "?"}%",
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.air_rounded,
                  label: "Kecepatan Angin",
                  value: "${currentWeather['ws'] ?? "?"} km/h",
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: _getWindDirectionIcon(currentWeather['wd'] ?? ""),
                  label: "Arah Angin",
                  value: currentWeather['wd'] ?? "?",
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.visibility_rounded,
                  label: "Visibilitas",
                  value: currentWeather['vs_text'] ?? "?",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: kDeathRed, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'FontX',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.15),
            fontSize: 10,
            fontFamily: 'ShareTechMono',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FORECAST
  // ============================================================
  Widget _buildForecast() {
    final forecast = _getNext5Weather();
    if (forecast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: kDeathRed.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kDeathRed.withOpacity(0.04)),
          ),
          child: Text(
            'PRAKIRAAN 5 JAM',
            style: TextStyle(
              color: kDeathRed.withOpacity(0.2),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              fontFamily: 'FontX',
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: forecast.length,
            itemBuilder: (context, index) {
              final weather = forecast[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kDeathCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kDeathBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weather['time'] ?? "",
                      style: TextStyle(
                        color: kDeathRed.withOpacity(0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'FontX',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      _getWeatherIconData(weather['weather_desc'] ?? ""),
                      color: Colors.white.withOpacity(0.2),
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${weather['t']?.toString() ?? "?"}°C",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'FontX',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getNext5Weather() {
    if (_weatherData == null) return [];
    
    final weatherList = _weatherData!['weather'] as List?;
    if (weatherList == null || weatherList.isEmpty) return [];
    
    final firstWeather = weatherList[0];
    final cuacaList = firstWeather['cuaca'] as List?;
    if (cuacaList == null || cuacaList.isEmpty) return [];
    
    final firstCuaca = cuacaList[0] as List?;
    if (firstCuaca == null) return [];
    
    final List<Map<String, dynamic>> result = [];
    for (int i = 0; i < firstCuaca.length && i < 5; i++) {
      final item = firstCuaca[i] as Map;
      result.add({
        'time': _formatTime(item['local_datetime']),
        't': item['t'],
        'weather_desc': item['weather_desc'],
      });
    }
    return result;
  }

  String _formatTime(String? datetime) {
    if (datetime == null) return "";
    try {
      final parts = datetime.split(' ');
      if (parts.length > 1) {
        return parts[1].substring(0, 5);
      }
      return datetime;
    } catch (e) {
      return datetime;
    }
  }
}

// ============================================================
// GRID PAINTER
// ============================================================
class _GridPainter extends CustomPainter {
  final Color accentColor;

  _GridPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const gridSize = 30.0;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final accentPaint = Paint()
      ..color = accentColor.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += gridSize * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }

    for (double y = 0; y <= size.height; y += gridSize * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }

    final dotPaint = Paint()
      ..color = accentColor.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    for (double x = 0; x <= size.width; x += gridSize) {
      for (double y = 0; y <= size.height; y += gridSize) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}