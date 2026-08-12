// DEATHTR4SH V1 GEN 2 - GLOBAL CHAT

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'models/chat_model.dart';
import 'theme_provider.dart';
import 'constants.dart';

class GlobalChatPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const GlobalChatPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<GlobalChatPage> createState() => _GlobalChatPageState();
}

class _GlobalChatPageState extends State<GlobalChatPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ============================================================
  // ANIMASI
  // ============================================================
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _pulseAnimation;

  // ============================================================
  // CONTROLLERS & STATE
  // ============================================================
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

  List<ChatMessage> _messages = [];
  List<ChatUser> _onlineUsers = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isPlayingVoice = false;
  bool _isUploadingImage = false;
  bool _isRecording = false;
  String? _currentPlayingId;
  String? _recordingPath;
  int _recordingDuration = 0;
  WebSocketChannel? _channel;
  bool _wsConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();
    _initializeChat();
    _connectWebSocket();
    _messageController.addListener(_onTextChanged);
    _mainController.forward();
    _pulseController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.closeRecorder();
    _channel?.sink.close();
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _mainController, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack));
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic));
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  void _onTextChanged() => setState(() {});

  void _initializeChat() async {
    await _loadMessages();
    await _loadOnlineUsers();
    _scrollToBottom();
  }

  // ============================================================
  // WEBSOCKET
  // ============================================================
  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(ApiConfig.wsUrl));

      _channel!.sink.add(jsonEncode({
        'type': 'register',
        'key': widget.sessionKey,
        'username': widget.username,
      }));

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'chat_message') {
              final chatMessage = ChatMessage.fromJson(data['data']);
              if (mounted) {
                setState(() {
                  final exists = _messages.any((m) => m.id == chatMessage.id);
                  if (!exists) {
                    _messages.add(chatMessage);
                  }
                });
                _scrollToBottom();
              }
            }
            if (data['type'] == 'chat_history') {
              final msgs = (data['messages'] as List?)
                      ?.map((e) => ChatMessage.fromJson(e))
                      .toList() ??
                  [];
              if (mounted && msgs.isNotEmpty) {
                setState(() {
                  _messages = msgs;
                  _isLoading = false;
                });
                _scrollToBottom();
              }
            }
          } catch (_) {}
        },
        onError: (error) {
          _wsConnected = false;
          _channel = null;
          _scheduleReconnect();
        },
        onDone: () {
          _wsConnected = false;
          _channel = null;
          _scheduleReconnect();
        },
      );

      _wsConnected = true;
    } catch (e) {
      _wsConnected = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _connectWebSocket();
        _loadMessages();
      }
    });
  }

  // ============================================================
  // API
  // ============================================================
  Future<void> _loadMessages() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.getChatMessagesEndpoint}?key=${widget.sessionKey}&roomId=global&limit=50',
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          if (mounted) {
            setState(() {
              _messages = (data['messages'] as List)
                  .map((e) => ChatMessage.fromJson(e))
                  .toList();
              _isLoading = false;
            });
            _scrollToBottom();
          }
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOnlineUsers() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.getChatUsersEndpoint}?key=${widget.sessionKey}&roomId=global',
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true && mounted) {
          setState(() {
            _onlineUsers = (data['users'] as List)
                .map((e) => ChatUser.fromJson(e))
                .toList();
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();
    _focusNode.unfocus();

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = ChatMessage(
      id: tempId,
      senderId: widget.username,
      senderName: widget.username,
      senderRole: widget.role,
      content: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );

    if (mounted) {
      setState(() => _messages.add(tempMsg));
      _scrollToBottom();
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendChatMessageEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': widget.sessionKey,
          'roomId': 'global',
          'content': text,
          'type': 'text',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          final realMsg = ChatMessage.fromJson(data['data']);
          if (mounted) {
            setState(() {
              final idx = _messages.indexWhere((m) => m.id == tempId);
              if (idx != -1) {
                _messages[idx] = realMsg;
              }
            });
          }
        } else {
          if (mounted) {
            setState(() => _messages.removeWhere((m) => m.id == tempId));
            _showError('Gagal mengirim: ${data['message'] ?? 'Error'}');
          }
        }
      } else {
        if (mounted) {
          setState(() => _messages.removeWhere((m) => m.id == tempId));
          _showError('Gagal mengirim pesan');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m.id == tempId));
        _showError('Gagal mengirim pesan: timeout/jaringan');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final caption = _messageController.text.trim();
    setState(() => _isUploadingImage = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.uploadChatMediaEndpoint),
      );

      request.fields['key'] = widget.sessionKey;
      request.fields['roomId'] = 'global';
      request.fields['type'] = 'image';
      request.fields['caption'] = caption;

      final imageFile = await http.MultipartFile.fromPath('media', image.path);
      request.files.add(imageFile);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          _messageController.clear();
          _showSuccess('Foto berhasil dikirim');
          await _loadMessages();
          _scrollToBottom();
        } else {
          _showError('Gagal mengupload gambar: ${data['message'] ?? ''}');
        }
      }
    } catch (e) {
      _showError('Gagal mengirim gambar');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ============================================================
  // RECORDING
  // ============================================================
  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _showError('Izin mikrofon diperlukan');
      return;
    }
    await _audioRecorder.openRecorder();
  }

  Future<void> _startRecording() async {
    try {
      await _initRecorder();
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _audioRecorder.startRecorder(toFile: path, codec: Codec.aacADTS);

      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _recordingDuration = 0;
      });
      _startRecordingTimer();
    } catch (e) {
      _showError('Gagal memulai rekaman');
    }
  }

  void _startRecordingTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() => _recordingDuration++);
        _startRecordingTimer();
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stopRecorder();
      setState(() => _isRecording = false);

      if (_recordingPath != null) {
        await _uploadVoiceNote(_recordingPath!);
      }
    } catch (e) {
      _showError('Gagal menghentikan rekaman');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _uploadVoiceNote(String path) async {
    try {
      setState(() => _isSending = true);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.uploadChatMediaEndpoint),
      );

      request.fields['key'] = widget.sessionKey;
      request.fields['roomId'] = 'global';
      request.fields['type'] = 'voice';
      request.fields['duration'] = _recordingDuration.toString();

      final voiceFile = await http.MultipartFile.fromPath('media', path);
      request.files.add(voiceFile);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          _showSuccess('Voice note berhasil dikirim');
          await _loadMessages();
          _scrollToBottom();
        }
      }
    } catch (e) {
      _showError('Gagal mengirim voice note');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _recordingDuration = 0;
          _recordingPath = null;
        });
      }
    }
  }

  Future<void> _playVoiceNote(String url, String messageId) async {
    try {
      if (_currentPlayingId == messageId && _isPlayingVoice) {
        await _audioPlayer.stop();
        setState(() {
          _isPlayingVoice = false;
          _currentPlayingId = null;
        });
      } else {
        await _audioPlayer.play(UrlSource(url));
        setState(() {
          _isPlayingVoice = true;
          _currentPlayingId = messageId;
        });

        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isPlayingVoice = false;
              _currentPlayingId = null;
            });
          }
        });
      }
    } catch (e) {
      _showError('Gagal memutar voice note');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: kDeathRed.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: kDeathRed.withOpacity(0.2)),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: kDeathGreen.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: kDeathGreen.withOpacity(0.2)),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showImageViewer(String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.black.withOpacity(0.92),
                ),
              ),
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: Hero(
                    tag: imageUrl,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 300,
                          height: 300,
                          color: kDeathCardBg,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.white.withOpacity(0.05), size: 50),
                                const SizedBox(height: 12),
                                Text(
                                  'Gagal memuat gambar',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.05),
                                    fontSize: 12,
                                    fontFamily: 'ShareTechMono',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'developer':
        return const Color(0xFF7B2FBE);
      case 'executive':
        return kDeathRed;
      case 'xfounder':
        return const Color(0xFFFF6B00);
      case 'moderator':
        return kDeathGold;
      case 'owner':
        return const Color(0xFF00E5FF);
      case 'owner':
        return const Color(0xFF8B0000);
      case 'xvip':
        return const Color(0xFFFFAB40);
      case 'reseller':
        return const Color(0xFF00BCD4);
      case 'member':
        return kDeathGreen;
      default:
        return Colors.grey.shade500;
    }
  }

  String _formatTime(DateTime timestamp) {
    return DateFormat('HH:mm').format(timestamp);
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            _buildOnlineUsersHeader(),
            Container(height: 0.5, color: kDeathBorder),
            Expanded(
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : _buildMessagesList(),
            ),
            if (_isRecording) _buildRecordingIndicator(),
            _buildMessageInput(),
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
            Icon(Icons.chat_rounded, color: kDeathRed, size: 16),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [kDeathRed, kDeathGold],
              ).createShader(bounds),
              child: Text(
                'GLOBAL CHAT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kDeathCardBg.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kDeathBorder),
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: kDeathRed,
              size: 18,
            ),
          ),
          onPressed: _loadMessages,
        ),
      ],
    );
  }

  // ============================================================
  // ONLINE USERS
  // ============================================================
  Widget _buildOnlineUsersHeader() {
    final onlineUsers = _onlineUsers.where((u) => u.isOnline).take(8).toList();

    return Container(
      color: kDeathCardBg,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: onlineUsers.isEmpty
                    ? [
                        Row(
                          children: [
                            Icon(Icons.person_off_rounded,
                                color: Colors.white.withOpacity(0.03), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Tidak ada user online',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.04),
                                fontSize: 10,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ],
                        )
                      ]
                    : onlineUsers
                        .map((user) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildUserAvatar(user),
                            ))
                        .toList(),
              ),
            ),
          ),
          if (_onlineUsers.length > 8)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kDeathRed.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kDeathRed.withOpacity(0.04)),
              ),
              child: Text(
                '+${_onlineUsers.length - 8}',
                style: TextStyle(
                  color: kDeathRed.withOpacity(0.2),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'FontX',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(ChatUser user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _getRoleColor(user.role),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'FontX',
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: kDeathGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: kDeathCardBg, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 40,
          child: Text(
            user.name.length > 5 ? '${user.name.substring(0, 5)}..' : user.name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontSize: 7,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOADING
  // ============================================================
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(4),
            child: CircularProgressIndicator(
              color: kDeathRed,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'LOADING MESSAGES...',
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
  // MESSAGES LIST
  // ============================================================
  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.02)),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white.withOpacity(0.03),
                size: 48,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'BELUM ADA PESAN',
              style: TextStyle(
                color: Colors.white.withOpacity(0.06),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'FontX',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Jadi yang pertama ngobrol!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.03),
                fontSize: 10,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == widget.username;
        final isPrevSameSender = index > 0 && _messages[index - 1].senderId == message.senderId;

        return _buildMessageBubble(message, isMe, isPrevSameSender);
      },
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================
  Widget _buildMessageBubble(
    ChatMessage message,
    bool isMe,
    bool isPrevSameSender,
  ) {
    final topMargin = isPrevSameSender ? 2.0 : 8.0;
    final isTempMsg = message.id.startsWith('temp_');

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isTempMsg ? 0.7 : 1.0,
      child: Container(
        margin: EdgeInsets.only(
          top: topMargin,
          bottom: 2,
          left: isMe ? 60 : 8,
          right: isMe ? 8 : 60,
        ),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe && !isPrevSameSender) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: _getRoleColor(message.senderRole),
                child: Text(
                  message.senderName.isNotEmpty
                      ? message.senderName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'FontX',
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ] else if (!isMe) ...[
              const SizedBox(width: 34),
            ],
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  gradient: isMe
                      ? LinearGradient(
                          colors: [kDeathRed.withOpacity(0.15), kDeathRedDark.withOpacity(0.08)],
                        )
                      : LinearGradient(
                          colors: [kDeathCardBg, kDeathDarkBg],
                        ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(
                      isMe ? 12 : (isPrevSameSender ? 4 : 12),
                    ),
                    bottomRight: Radius.circular(
                      isMe ? (isPrevSameSender ? 4 : 12) : 12,
                    ),
                  ),
                  border: Border.all(
                    color: isMe ? kDeathRed.withOpacity(0.1) : kDeathBorder,
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe && !isPrevSameSender) ...[
                      Row(
                        children: [
                          Text(
                            message.senderName,
                            style: TextStyle(
                              color: _getRoleColor(message.senderRole),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'FontX',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: _getRoleColor(message.senderRole)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              message.senderRole.toUpperCase(),
                              style: TextStyle(
                                color: _getRoleColor(message.senderRole)
                                    .withOpacity(0.3),
                                fontSize: 6,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'FontX',
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    _buildMessageContent(message, isMe),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: isMe ? Colors.white60 : Colors.white.withOpacity(0.1),
                            fontSize: 9,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 2),
                          isTempMsg
                              ? SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.2,
                                    color: Colors.white60,
                                  ),
                                )
                              : Icon(
                                  Icons.done_all_rounded,
                                  color: kDeathGold.withOpacity(0.3),
                                  size: 12,
                                ),
                        ],
                      ],
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
  // MESSAGE CONTENT
  // ============================================================
  Widget _buildMessageContent(ChatMessage message, bool isMe) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'ShareTechMono',
            height: 1.4,
          ),
        );

      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.mediaUrl != null)
              GestureDetector(
                onTap: () => _showImageViewer(message.mediaUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    message.mediaUrl!,
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        width: 200,
                        color: kDeathCardBg,
                        child: Center(
                          child: Icon(Icons.broken_image, color: Colors.white.withOpacity(0.05), size: 32),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 120,
                        width: 200,
                        color: kDeathCardBg,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: kDeathRed,
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (message.content.isNotEmpty && message.content != '📷 Photo')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'ShareTechMono',
                    height: 1.3,
                  ),
                ),
              ),
          ],
        );

      case MessageType.voice:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => message.mediaUrl != null
                  ? _playVoiceNote(message.mediaUrl!, message.id)
                  : null,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _currentPlayingId == message.id && _isPlayingVoice
                      ? kDeathRed.withOpacity(0.08)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _currentPlayingId == message.id && _isPlayingVoice
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: isMe ? kDeathRed : kDeathGold.withOpacity(0.3),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    16,
                    (index) => Container(
                      width: 2,
                      height: _currentPlayingId == message.id && _isPlayingVoice
                          ? (index % 3 == 0 ? 10 : (index % 3 == 1 ? 14 : 6))
                          : (index % 4 == 0 ? 6 : 10),
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: BoxDecoration(
                        color: _currentPlayingId == message.id && _isPlayingVoice
                            ? kDeathRed
                            : (isMe ? Colors.white38 : Colors.white.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (message.duration != null)
                      Text(
                        '${message.duration}s',
                        style: TextStyle(
                          color: isMe ? Colors.white60 : Colors.white.withOpacity(0.1),
                          fontSize: 9,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    if (_currentPlayingId == message.id && _isPlayingVoice) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: kDeathRed.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PLAYING',
                          style: TextStyle(
                            color: kDeathRed.withOpacity(0.2),
                            fontSize: 6,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'FontX',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        );
    }
  }

  // ============================================================
  // RECORDING INDICATOR
  // ============================================================
  Widget _buildRecordingIndicator() {
    return Container(
      color: kDeathCardBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kDeathRed.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, color: kDeathRed, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: List.generate(
              12,
              (index) => Container(
                width: 2.5,
                height: 6 + (index % 4) * 3.0,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: kDeathRed,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_recordingDuration ~/ 60}:${(_recordingDuration % 60).toString().padLeft(2, '0')}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'ShareTechMono',
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kDeathRed, kDeathRedDark],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: kDeathRed.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.send_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'KIRIM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'FontX',
                      letterSpacing: 1,
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

  // ============================================================
  // MESSAGE INPUT
  // ============================================================
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 8),
      decoration: BoxDecoration(
        color: kDeathCardBg,
        border: Border(
          top: BorderSide(color: kDeathBorder, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildCircleButton(
            icon: Icons.attach_file_rounded,
            color: Colors.white.withOpacity(0.1),
            onTap: _isUploadingImage ? null : _sendImage,
            isLoading: _isUploadingImage,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: kDeathDarkBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: kDeathBorder,
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontFamily: 'ShareTechMono',
                  height: 1.3,
                ),
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.06),
                    fontSize: 12,
                    fontFamily: 'ShareTechMono',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _messageController.text.trim().isNotEmpty || _isSending
                ? _buildCircleButton(
                    key: const ValueKey('send'),
                    icon: Icons.send_rounded,
                    color: kDeathRed,
                    bgColor: kDeathRed,
                    iconColor: Colors.white,
                    onTap: _isSending ? null : _sendMessage,
                    isLoading: _isSending,
                  )
                : _buildCircleButton(
                    key: const ValueKey('mic'),
                    icon: Icons.mic_rounded,
                    color: Colors.white.withOpacity(0.1),
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    isActive: _isRecording,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    Color? bgColor,
    Color? iconColor,
    VoidCallback? onTap,
    bool isLoading = false,
    bool isActive = false,
    Key? key,
  }) {
    return SizedBox(
      key: key,
      height: 38,
      width: 38,
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: iconColor ?? color,
                  strokeWidth: 2,
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: isActive
                      ? kDeathRed.withOpacity(0.08)
                      : (bgColor ?? Colors.transparent),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: Icon(
                  icon,
                  color: iconColor ?? (isActive ? kDeathRed : color),
                  size: 20,
                ),
              ),
      ),
    );
  }
}