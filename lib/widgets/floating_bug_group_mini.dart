import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import '../bug_group.dart';

/// Mini floating widget for quick Bug Group attack from floating menu
class FloatingBugGroupMini extends StatefulWidget {
  final String sessionKey;
  final String username;

  const FloatingBugGroupMini({
    super.key,
    required this.sessionKey,
    required this.username,
  });

  @override
  State<FloatingBugGroupMini> createState() => _FloatingBugGroupMiniState();
}

class _FloatingBugGroupMiniState extends State<FloatingBugGroupMini> {
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _handleAttack() async {
    final link = _linkController.text.trim();
    
    if (link.isEmpty) {
      _showMessage('⚠️ Group link required!', isError: true);
      return;
    }

    // Validate WhatsApp group link format
    final regex = RegExp(r'https://chat\.whatsapp\.com/[a-zA-Z0-9]{22}');
    if (!regex.hasMatch(link)) {
      _showMessage('❌ Invalid WhatsApp group link', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await GroupBugPage.sendGroupBugStatic(
      sessionKey: widget.sessionKey,
      groupLink: link,
    );
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      _showMessage('✅ ${result['message']}');
      _linkController.clear();
    } else {
      _showMessage('❌ ${result['message']}', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: isError ? Colors.red.shade900 : const Color(0xFF4ADE80),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4ADE80).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.userGroup,
                    color: Color(0xFF4ADE80),
                    size: 12,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ATTACK GROUP',
                    style: TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),

            // Input Field
            TextField(
              controller: _linkController,
              enabled: !_isLoading,
              style: const TextStyle(
                color: Color(0xFF4ADE80),
                fontSize: 11,
              ),
              decoration: InputDecoration(
                hintText: 'https://chat.whatsapp.com/...',
                hintStyle: TextStyle(
                  color: const Color(0xFF4ADE80).withOpacity(0.3),
                  fontSize: 10,
                ),
                prefixIcon: const Icon(
                  Icons.link,
                  color: Color(0xFF4ADE80),
                  size: 14,
                ),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
              maxLines: 1,
            ),

            const SizedBox(height: 8),

            // Attack Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleAttack,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ADE80),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(FontAwesomeIcons.rocket, size: 11),
                        SizedBox(width: 6),
                        Text(
                          'LAUNCH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
