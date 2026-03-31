class Ticket {
  final int id;
  final String ticketNumber;
  final String roomId;
  final String title;
  final String? description;
  final int status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<TicketReply>? replies;
  final List<TicketImage>? images;
  final Map<String, dynamic>? room;

  Ticket({
    required this.id,
    required this.ticketNumber,
    required this.roomId,
    required this.title,
    this.description,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.replies,
    this.images,
    this.room,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      ticketNumber: json['ticketNumber'] ?? '',
      roomId: json['roomId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      replies: json['ticketReplies'] != null
          ? (json['ticketReplies'] as List).map((i) => TicketReply.fromJson(i)).toList()
          : null,
      images: json['ticketImages'] != null
          ? (json['ticketImages'] as List).map((i) => TicketImage.fromJson(i)).toList()
          : null,
      room: json['room'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketNumber': ticketNumber,
      'roomId': roomId,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get statusText {
    switch (status) {
      case 0:
        return 'Abierto';
      case 1:
        return 'En progreso';
      case 2:
        return 'Cerrado';
      default:
        return 'Desconocido';
    }
  }

  dynamic get statusIcon {
    switch (status) {
      case 0:
        return 0xe3ca; // Icons.new_releases
      case 1:
        return 0xe333; // Icons.hourglass_top
      case 2:
        return 0xe156; // Icons.check_circle_outline
      default:
        return 0xe31e; // Icons.help_outline
    }
  }
}

class TicketReply {
  final int id;
  final int ticketId;
  final String message;
  final String agentName;
  final DateTime? createdAt;

  TicketReply({
    required this.id,
    required this.ticketId,
    required this.message,
    required this.agentName,
    this.createdAt,
  });

  factory TicketReply.fromJson(Map<String, dynamic> json) {
    return TicketReply(
      id: json['id'],
      ticketId: json['ticketId'],
      message: json['message'] ?? '',
      agentName: json['agentName'] ?? 'Agente',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class TicketImage {
  final int id;
  final int ticketId;
  final String fileUrl;

  TicketImage({
    required this.id,
    required this.ticketId,
    required this.fileUrl,
  });

  factory TicketImage.fromJson(Map<String, dynamic> json) {
    return TicketImage(
      id: json['id'],
      ticketId: json['ticketId'],
      fileUrl: json['fileUrl'] ?? '',
    );
  }
}
