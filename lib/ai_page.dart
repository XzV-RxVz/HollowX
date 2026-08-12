// DEATHTRASH - AI ASSISTANT (RED & GOLD EDITION)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'constants.dart';

class AIPage extends StatefulWidget {
  final String username;
  final String sessionKey;

  const AIPage({
    Key? key,
    required this.username,
    required this.sessionKey,
  }) : super(key: key);

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isTyping = false;
  String _currentResponse = '';
  Timer? _typingTimer;
  int _typingIndex = 0;

  // ============================================================
  // ANIMATIONS
  // ============================================================
  late AnimationController _mainController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadChatHistory();
    _mainController.forward();
  }

  void _initAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );
    _scaleIn = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );
  }

  void _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('ai_chat_history_${widget.username}');
    
    if (history != null && history.isNotEmpty) {
      setState(() {
        _messages.clear();
        for (var json in history) {
          try {
            final message = jsonDecode(json);
            _messages.add(message);
          } catch (e) {
            debugPrint('Error loading message: $e');
          }
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = _messages.map((msg) => jsonEncode(msg)).toList();
    await prefs.setStringList('ai_chat_history_${widget.username}', history);
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add({
        'text': text,
        'isUser': isUser,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    _saveChatHistory();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startTypingAnimation(String text) {
    setState(() {
      _isTyping = true;
      _currentResponse = '';
      _typingIndex = 0;
    });

    const typingSpeed = 35;

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: typingSpeed), (timer) {
      if (_typingIndex < text.length) {
        setState(() {
          _currentResponse = text.substring(0, _typingIndex + 1);
          _typingIndex++;
        });
        _scrollToBottom();
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
        });
        _addMessage(text, false);
        _saveChatHistory();
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    _addMessage(text, true);
    _textController.clear();

    try {
      final response = await http.get(
        Uri.parse('https://api.deline.web.id/ai/copilot?text=${Uri.encodeComponent(text)}'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final aiResponse = data['result'];
          _startTypingAnimation(aiResponse);
        } else {
          _addMessage('Error: ${data['message']}', false);
        }
      } else {
        _addMessage('Error: Failed to connect to AI service. Status code: ${response.statusCode}', false);
      }
    } catch (e) {
      _addMessage('Error: ${e.toString()}', false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearChat() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kDeathDarkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: kDeathRed.withOpacity(0.3), width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kDeathRed, size: 22),
            const SizedBox(width: 10),
            Text(
              'Clear Chat',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                fontFamily: 'ShareTechMono',
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to clear all chat history?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: kDeathCardBg.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontWeight: FontWeight.w700,
                fontSize: 11,
                fontFamily: 'ShareTechMono',
                letterSpacing: 1,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _currentResponse = '';
                _isTyping = false;
                _typingTimer?.cancel();
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('ai_chat_history_${widget.username}');
            },
            style: TextButton.styleFrom(
              backgroundColor: kDeathRed.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: kDeathRed.withOpacity(0.15)),
              ),
            ),
            child: Text(
              'CLEAR',
              style: TextStyle(
                color: kDeathRed,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                fontFamily: 'ShareTechMono',
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE BUBBLES
  // ============================================================
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'];
    final text = message['text'];
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser)
              Container(
                margin: const EdgeInsets.only(right: 10, top: 4),
                child: CircleAvatar(
                  backgroundColor: kDeathRed.withOpacity(0.08),
                  radius: 16,
                  child: Icon(
                    FontAwesomeIcons.robot,
                    color: kDeathGold,
                    size: 16,
                  ),
                ),
              ),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUser 
                        ? [kDeathRed, kDeathRedDark]
                        : [kDeathCardBg, kDeathDarkBg],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: isUser 
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(4),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        )
                      : const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                  border: Border.all(
                    color: isUser 
                        ? kDeathRed.withOpacity(0.15)
                        : kDeathBorder,
                    width: isUser ? 0.8 : 1,
                  ),
                  boxShadow: isUser
                      ? [
                          BoxShadow(
                            color: kDeathRed.withOpacity(0.08),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: SelectableText(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ),
            if (isUser)
              Container(
                margin: const EdgeInsets.only(left: 10, top: 4),
                child: CircleAvatar(
                  backgroundColor: kDeathRed,
                  radius: 16,
                  child: Text(
                    widget.username[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 10, top: 4),
              child: CircleAvatar(
                backgroundColor: kDeathRed.withOpacity(0.08),
                radius: 16,
                child: Icon(
                  FontAwesomeIcons.robot,
                  color: kDeathGold,
                  size: 16,
                ),
              ),
            ),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kDeathCardBg, kDeathDarkBg],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: kDeathRed.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SelectableText(
                        _currentResponse,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: _mainController,
                      builder: (context, _) {
                        final pulse = (0.5 + 0.5 * (1 - (_mainController.value * 2 - 1).abs()));
                        return Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: kDeathRed.withOpacity(0.2 + 0.6 * pulse),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kDeathRed.withOpacity(0.1 * pulse),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kDeathRed, kDeathRedDark],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: kDeathRed.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                FontAwesomeIcons.robot,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [kDeathRed, kDeathGold],
              ).createShader(bounds),
              child: Text(
                'DEATHTRASH AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'ShareTechMono',
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
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_messages.isNotEmpty)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kDeathCardBg.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kDeathBorder),
              ),
              child: Icon(
                Icons.delete_sweep_rounded,
                color: kDeathRed.withOpacity(0.3),
                size: 18,
              ),
            ),
            onPressed: _clearChat,
          ),
      ],
    );
  }

  // ============================================================
  // INPUT BAR
  // ============================================================
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kDeathCardBg.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: kDeathRed.withOpacity(0.06), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: kDeathRed.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: kDeathDarkBg.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kDeathBorder,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.12),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  prefixIcon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: kDeathRed.withOpacity(0.3),
                    size: 18,
                  ),
                ),
                onSubmitted: (text) => _sendMessage(text),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isLoading ? [kDeathCardBg, kDeathBorder] : [kDeathRed, kDeathRedDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: _isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: kDeathRed.withOpacity(0.2),
                        blurRadius: 16,
                      ),
                    ],
            ),
            child: IconButton(
              icon: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
              onPressed: _isLoading
                  ? null
                  : () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeathDarkBg,
      body: Stack(
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
                  const Color(0xFF150A26),
                  kDeathDarkBg,
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),

          // Glow Orbs
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kDeathRed.withOpacity(0.04), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kDeathGold.withOpacity(0.02), Colors.transparent],
                ),
              ),
            ),
          ),

          // Grid
          CustomPaint(
            size: Size.infinite,
            painter: _AIGridPainter(accentColor: kDeathRed),
          ),

          // Main Content
          FadeTransition(
            opacity: _fadeIn,
            child: ScaleTransition(
              scale: _scaleIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _messages.length) {
                            return _buildMessageBubble(_messages[index]);
                          } else {
                            return _buildTypingBubble();
                          }
                        },
                      ),
                    ),
                    _buildInputBar(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _mainController.dispose();
    super.dispose();
  }
}

// ============================================================
// GRID PAINTER
// ============================================================
class _AIGridPainter extends CustomPainter {
  final Color accentColor;

  _AIGridPainter({required this.accentColor});

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