import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import '../config/constants.dart';
import 'api_client.dart';
import '../models/chat_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  io.Socket? socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiClient _client = ApiClient();
  final String chatApiUrl = '${Constants.baseUrl}/chat';
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? currentActiveRoomId;
  final List<Function(ChatMessage)> _messageListeners = [];
  final List<Function(dynamic)> _typingListeners = [];

  void addMessageListener(Function(ChatMessage) listener) {
    _messageListeners.add(listener);
  }

  void removeMessageListener(Function(ChatMessage) listener) {
    _messageListeners.remove(listener);
  }

  void addTypingListener(Function(dynamic) listener) {
    _typingListeners.add(listener);
  }

  void removeTypingListener(Function(dynamic) listener) {
    _typingListeners.remove(listener);
  }

  void playNewChatSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/new_chat.mp3'));
    } catch (_) {}
  }

  void playNewMessageSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/new_message.mp3'));
    } catch (_) {}
  }

  Future<void> connectSocket({
    required Function onUserJoined,
    required Function onRoomClosed,
    required Function onRoomListUpdated,
    required Function(ChatMessage) onGlobalMessage,
    required Function(dynamic) onRoomAssignedNotification,
  }) async {
    if (socket != null && socket!.connected) return;

    final token = await _storage.read(key: 'accessToken');

    socket = io.io(Constants.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'},
    });

    socket!.connect();

    socket!.on('new_room_created', (_) {
      playNewChatSound();
    });

    socket!.on('room_list_updated', (_) {
      onRoomListUpdated();
    });

    socket!.on('proyecto_assigned_notification', (data) {
      onRoomAssignedNotification({
        'agentName': data['agentName'],
        'assignedBy': data['assignedBy'],
        'isProyecto': true,
        'proyectoNombre': data['proyectoNombre'],
      });
    });

    socket!.on('room_assigned_notification', (data) {
      onRoomAssignedNotification(data);
    });

    socket!.on('global_new_message', (data) {
      final message = ChatMessage.fromJson(data);
      if (currentActiveRoomId != message.roomId.toString()) {
        playNewMessageSound();
        onGlobalMessage(message);
      }
    });

    socket!.on('receive_message', (data) {
      final message = ChatMessage.fromJson(data);
      for (var listener in _messageListeners) {
        listener(message);
      }
    });

    socket!.on('user_typing', (data) {
      for (var listener in _typingListeners) {
        listener(data);
      }
    });

    socket!.on('user_joined', (data) {
      if (data['role'] == 'visitor') {
        playNewChatSound();
      }
      onUserJoined(data);
    });

    socket!.on('room_closed', (data) => onRoomClosed(data));
  }

  Future<Map<String, dynamic>> getSummary() async {
    final response = await _client.get(
      Uri.parse('${Constants.baseUrl}/reports/summary'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {};
  }

  Future<List<ChatRoom>> getActiveRooms({int page = 1, int limit = 50}) async {
    final response = await _client.get(
      Uri.parse('$chatApiUrl/rooms?page=$page&limit=$limit'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List roomsData = data['rooms'] ?? data;
      return roomsData.map((json) => ChatRoom.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<ChatRoom>> getHistoricalRooms({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      Uri.parse('$chatApiUrl/history-rooms?page=$page&limit=$limit'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List roomsData = data['rooms'] ?? data;
      return roomsData.map((json) => ChatRoom.fromJson(json)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getHistoricalRoomsPaginated({
    int page = 1,
    int limit = 20,
    String? agentName,
  }) async {
    String url = '$chatApiUrl/history-rooms?page=$page&limit=$limit';

    if (agentName != null && agentName.isNotEmpty) {
      url += '&agentName=$agentName';
    }

    final response = await _client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List roomsData = data['rooms'] as List? ?? [];
      return {
        'rooms': roomsData.map((json) => ChatRoom.fromJson(json)).toList(),
        'totalPages': data['totalPages'] ?? 1,
        'currentPage': data['currentPage'] ?? 1,
        'totalItems': data['totalItems'] ?? 0,
      };
    }
    return {
      'rooms': <ChatRoom>[],
      'totalPages': 1,
      'currentPage': 1,
      'totalItems': 0,
    };
  }

  Future<List<ChatMessage>> getHistory(String roomId) async {
    final response = await _client.get(
      Uri.parse('$chatApiUrl/history/$roomId'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    }
    return [];
  }

  void joinRoom(String roomId, String agentName, {String role = 'agent'}) {
    socket?.emit('join_room', {
      'roomId': roomId,
      'userId': agentName,
      'role': role,
    });
  }

  void sendMessage(ChatMessage message) {
    socket?.emit('send_message', message.toJson());
  }

  void sendTypingStatus(String roomId, bool isTyping, String role) {
    socket?.emit('typing', {
      'roomId': roomId,
      'isTyping': isTyping,
      'role': role,
    });
  }

  void closeRoom(String roomId) {
    socket?.emit('close_room', {'roomId': roomId});
  }

  Future<bool> assignAgent(
    String roomId,
    String agentId,
    String agentName,
    String assignedBy,
  ) async {
    final response = await _client.put(
      Uri.parse('$chatApiUrl/room/$roomId/assign'),
      body: jsonEncode({
        'agentId': int.tryParse(agentId) ?? agentId,
        'agentName': agentName,
      }),
    );

    if (response.statusCode == 200) {
      socket?.emit('room_assigned', {
        'roomId': roomId,
        'agentName': agentName,
        'assignedBy': assignedBy,
      });
      return true;
    }
    return false;
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }

  Future<List<dynamic>> getAgentRanking(String period) async {
    final response = await _client.get(
      Uri.parse('${Constants.baseUrl}/reports/ranking?period=$period'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }
}
