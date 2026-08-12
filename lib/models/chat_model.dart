class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final String? mediaUrl;
  final int? duration; // for voice notes in seconds

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.type,
    required this.timestamp,
    this.mediaUrl,
    this.duration,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'] ?? 'Unknown',
      senderRole: json['sender_role'] ?? 'user',
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      mediaUrl: json['media_url'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'media_url': mediaUrl,
      'duration': duration,
    };
  }
}

class ChatUser {
  final String id;
  final String name;
  final String role;
  final bool isOnline;
  final DateTime lastSeen;

  ChatUser({
    required this.id,
    required this.name,
    required this.role,
    required this.isOnline,
    required this.lastSeen,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      role: json['role'] ?? 'user',
      isOnline: json['is_online'] ?? false,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(json['last_seen'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'is_online': isOnline,
      'last_seen': lastSeen.millisecondsSinceEpoch,
    };
  }
}

enum MessageType {
  text,
  image,
  voice,
}

class ChatRoom {
  final String id;
  final String name;
  final String description;
  final List<ChatMessage> messages;
  final List<ChatUser> participants;
  final DateTime createdAt;
  final ChatUser? lastMessageSender;
  final String? lastMessagePreview;

  ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.messages,
    required this.participants,
    required this.createdAt,
    this.lastMessageSender,
    this.lastMessagePreview,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Chat All',
      description: json['description'] ?? 'Chat For All User Apps',
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => ChatMessage.fromJson(e))
              .toList() ??
          [],
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => ChatUser.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] ?? 0),
      lastMessageSender: json['last_message_sender'] != null
          ? ChatUser.fromJson(json['last_message_sender'])
          : null,
      lastMessagePreview: json['last_message_preview'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'messages': messages.map((e) => e.toJson()).toList(),
      'participants': participants.map((e) => e.toJson()).toList(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_message_sender': lastMessageSender?.toJson(),
      'last_message_preview': lastMessagePreview,
    };
  }
}
