import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

// ============================================================
// GRID PATTERN PAINTER
// ============================================================
class _ChatGridPatternPainter extends CustomPainter {
  final Color gridColor;
  final double spacing;
  
  const _ChatGridPatternPainter({
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

class ChatScreen extends StatefulWidget {
  final String deviceId;
  final String sessionKey;
  const ChatScreen({super.key, required this.deviceId, required this.sessionKey});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late RatApiService _api;
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _api = RatApiService(widget.sessionKey);
    _loadHistory();
  }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  Future<void> _loadHistory() async {
    try {
      final h = await _api.getChatHistory(widget.deviceId);
      setState(() { _messages = h; _isLoading = false; });
      _scrollToBottom();
    } catch (_) { setState(() => _isLoading = false); }
  }

  void _scrollToBottom() => Future.delayed(const Duration(milliseconds: 300), () {
    if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _messages.add({'sender': 'admin', 'message': text, 'timestamp': DateTime.now().toIso8601String()}); _msgCtrl.clear(); });
    _scrollToBottom();
    try { await _api.sendChatMessage(widget.deviceId, text); }
    catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
  }

  Widget _buildGridBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _ChatGridPatternPainter(
          gridColor: Colors.white.withOpacity(0.03),
          spacing: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
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
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: _kCard.withOpacity(0.95),
                  border: Border(bottom: BorderSide(color: _kBlue.withOpacity(0.2))),
                ),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                      child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Device Chat', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('Real-time messaging', style: TextStyle(color: _kSub, fontSize: 11)),
                  ]),
                ]),
              ),
              // Messages
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final m = _messages[i];
                        return _bubble(m['message'] ?? '', m['sender'] == 'admin', m['timestamp'] ?? '');
                      },
                    ),
              ),
              // Input
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kCard.withOpacity(0.95),
                  border: Border(top: BorderSide(color: _kBlue.withOpacity(0.15))),
                ),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                        filled: true, fillColor: Colors.black.withOpacity(0.3),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: _kBlue.withOpacity(0.2))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kBlue, _kCyan]), borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _bubble(String text, bool isAdmin, String ts) {
    final time = ts.length > 15 ? ts.split('T').last.substring(0, 5) : ts;
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          gradient: isAdmin
            ? const LinearGradient(colors: [_kBlue, _kCyan])
            : LinearGradient(colors: [_kCard, _kCard.withOpacity(0.8)]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isAdmin ? 14 : 0),
            bottomRight: Radius.circular(isAdmin ? 0 : 14),
          ),
          border: isAdmin ? null : Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
        ]),
      ),
    );
  }
}