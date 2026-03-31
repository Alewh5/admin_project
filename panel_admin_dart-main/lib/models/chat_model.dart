class ChatRoom {
  final String id;
  final String? roomId;
  final String? visitorName;
  final String? visitorEmail;
  final String? reason;
  final String? originUrl;
  final String status;
  final String? agentId;
  final String? agentName;
  final DateTime? createdAt;
  final int? rating;
  final String? ratingFeedback;
  final List<ChatMessage>? lastMessages;

  ChatRoom({
    required this.id,
    this.roomId,
    this.visitorName,
    this.visitorEmail,
    this.reason,
    this.originUrl,
    required this.status,
    this.agentId,
    this.agentName,
    this.createdAt,
    this.rating,
    this.ratingFeedback,
    this.lastMessages,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'].toString(),
      roomId: json['roomId']?.toString(),
      visitorName: json['firstName'] ?? json['email'] ?? 'Visitante',
      visitorEmail: json['email'],
      reason: json['reason']?.toString(),
      originUrl: json['originUrl']?.toString(),
      status: json['status'] ?? 'active',
      agentId: json['agentId']?.toString(),
      agentName: json['agentName'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      rating: json['rating'] != null
          ? int.tryParse(json['rating'].toString())
          : null,
      ratingFeedback: json['ratingFeedback']?.toString(),
      lastMessages: json['messages'] != null
          ? (json['messages'] as List)
                .map((m) => ChatMessage.fromJson(m))
                .toList()
          : null,
    );
  }
}

class ChatMessage {
  final String? id;
  final String roomId;
  final String message;
  final String senderId;
  final String role; // 'visitor' or 'agent'
  final String type; // 'text', 'image', 'file'
  final String? fileUrl;
  final DateTime? createdAt;

  ChatMessage({
    this.id,
    required this.roomId,
    required this.message,
    required this.senderId,
    required this.role,
    this.type = 'text',
    this.fileUrl,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      roomId: json['roomId']?.toString() ?? '',
      message: json['message'] ?? '',
      senderId: json['senderId']?.toString() ?? '',
      role: json['role'] ?? 'visitor',
      type: json['type'] ?? 'text',
      fileUrl: json['fileUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'message': message,
      'senderId': senderId,
      'role': role,
      'type': type,
      'fileUrl': fileUrl,
    };
  }
}
