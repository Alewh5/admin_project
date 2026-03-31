import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:pasteboard/pasteboard.dart';
import '../../services/chat_service.dart';
import '../../services/ticket_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/user_avatar.dart';
import '../Tickets/ticket_detail_screen.dart';
import '../../models/chat_model.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatRoom room;
  final String agentName;
  final String agentRole;
  final bool isReadOnly;
  final VoidCallback? onBack;

  const ChatDetailScreen({
    super.key,
    required this.room,
    required this.agentName,
    required this.agentRole,
    this.isReadOnly = false,
    this.onBack,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TicketService _ticketService = TicketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  List<dynamic> _tickets = [];
  int _ticketPage = 1;
  bool _hasMoreTickets = true;
  bool _isLoadingTickets = false;
  bool _isVisitorTyping = false;
  String _visitorTypingText = '';
  bool _isInternalNote = false;

  // ESTA ES LA CLAVE: Centralizar el ID correcto
  String get _activeRoomId => widget.room.id;

  @override
  void initState() {
    super.initState();
    _chatService.currentActiveRoomId = _activeRoomId;
    _chatService.addMessageListener(_onMessageReceived);
    _chatService.addTypingListener(_onTypingReceived);
    _loadHistoryAndJoin();
    _loadTickets();
  }

  Future<void> _loadTickets({bool loadMore = false}) async {
    if (_isLoadingTickets) return;

    if (loadMore) {
      _ticketPage++;
    } else {
      _ticketPage = 1;
      _tickets.clear();
      _hasMoreTickets = true;
    }

    setState(() {
      _isLoadingTickets = true;
    });

    final response = await _ticketService.getTickets(
      _activeRoomId,
      page: _ticketPage,
    );
    final newTickets = response['tickets'] as List<dynamic>? ?? [];

    if (mounted) {
      setState(() {
        if (loadMore) {
          _tickets.addAll(newTickets);
        } else {
          _tickets = newTickets;
        }
        _hasMoreTickets = _ticketPage < (response['totalPages'] as int? ?? 1);
        _isLoadingTickets = false;
      });
    }
  }

  Future<void> _loadHistoryAndJoin() async {
    try {
      final history = await _chatService.getHistory(_activeRoomId);
      if (mounted) {
        setState(() {
          _messages = history;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print(e);
    }

    _chatService.joinRoom(
      _activeRoomId,
      widget.agentName,
      role: widget.isReadOnly ? 'supervisor' : 'agent',
    );
  }

  void _onMessageReceived(ChatMessage message) {
    if (message.roomId == _activeRoomId) {
      if (mounted) {
        setState(() {
          int optIndex = _messages.indexWhere(
            (m) =>
                m.id == null &&
                m.message == message.message &&
                m.senderId == message.senderId,
          );

          if (optIndex != -1) {
            _messages[optIndex] = message;
          } else {
            bool exists =
                message.id != null && _messages.any((m) => m.id == message.id);
            if (!exists) {
              _messages.add(message);
            }
          }
        });
        _scrollToBottom();
      }
    }
  }

  void _onTypingReceived(dynamic data) {
    if (data['roomId'].toString() == _activeRoomId) {
      if (data['role'] == 'visitor') {
        if (mounted) {
          setState(() {
            _isVisitorTyping = data['isTyping'];
            _visitorTypingText = data['previewText']?.toString() ?? '';
          });
        }
      }
    }
  }

  void _onTyping(String text) {
    if (widget.isReadOnly) return;
    _chatService.sendTypingStatus(_activeRoomId, text.isNotEmpty, 'agent');
  }

  void _sendMessage() {
    if (widget.isReadOnly) return;
    final text = _messageController.text.trim();

    if (text.isNotEmpty) {
      final message = ChatMessage(
        roomId: _activeRoomId,
        message: text,
        senderId: widget.agentName,
        role: 'agent',
        type: _isInternalNote ? 'internal' : 'text',
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();

      _chatService.sendMessage(message);
      _chatService.sendTypingStatus(_activeRoomId, false, 'agent');

      _messageController.clear();
      _focusNode.requestFocus();
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    String avatarText =
        widget.room.visitorEmail != null && widget.room.visitorEmail!.isNotEmpty
        ? widget.room.visitorEmail!.substring(0, 1).toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: (widget.onBack != null || Navigator.canPop(context))
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.pop(context);
                  }
                },
              )
            : (isDesktop
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    )),
        title: Row(
          children: [
            UserAvatar(name: avatarText, radius: 18, showStatus: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isReadOnly
                        ? 'Viendo: ${widget.room.visitorEmail ?? "Cliente"}'
                        : widget.room.visitorEmail ?? 'Chat con Cliente',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.room.status == 'closed'
                        ? 'Chat Cerrado'
                        : 'Chat Activo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.confirmation_number_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Tickets',
            onPressed: () => _showTicketsModal(context),
          ),
          if (!widget.isReadOnly)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                tooltip: 'Finalizar Chat',
                onPressed: () {
                  _chatService.closeRoom(_activeRoomId);
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.blue[50],
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : Colors.blue[100]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: isDark ? Colors.blue[300] : Colors.blue[800],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Detalles de la consulta',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.blue[300] : Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.room.visitorName ??
                      widget.room.visitorEmail ??
                      'Visitante',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.room.reason ?? 'Sin motivo especificado',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.room.originUrl ?? 'Sin URL especificado',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? const EmptyState(
                    title: 'No hay mensajes aún',
                    subtitle:
                        'Escribe el primer mensaje para comenzar la conversación.',
                    icon: Icons.chat_bubble_outline_rounded,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      bool isMe = msg.role == 'agent';

                      Widget content;
                      if (msg.fileUrl != null && msg.fileUrl!.isNotEmpty) {
                        content = Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                msg.fileUrl!,
                                width: 250,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                            if (msg.message.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  msg.message,
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white
                                              : Colors.black87),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                          ],
                        );
                      } else {
                        content = Text(
                          msg.message,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                            fontSize: 15,
                          ),
                        );
                      }

                      final borderRadius = BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      );

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (msg.type == 'internal')
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                  vertical: 2.0,
                                ),
                                child: Text(
                                  '${msg.senderId} (Nota Interna)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Container(
                              margin: const EdgeInsets.only(top: 2, bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: msg.type == 'internal'
                                    ? (isDark
                                          ? Colors.amber[900]
                                          : Colors.amber[100])
                                    : isMe
                                    ? (widget.isReadOnly
                                          ? Colors.blueGrey
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary)
                                    : (isDark
                                          ? const Color(0xFF1F2937)
                                          : const Color(0xFFF3F4F6)),
                                borderRadius: borderRadius,
                              ),
                              child: content,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_isVisitorTyping)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 4.0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _visitorTypingText.isNotEmpty
                            ? '${widget.room.visitorEmail ?? 'El cliente'} está escribiendo: "$_visitorTypingText"'
                            : '${widget.room.visitorEmail ?? 'El cliente'} está escribiendo...',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!widget.isReadOnly)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
              ),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isInternalNote ? Icons.lock : Icons.lock_open,
                        color: _isInternalNote ? Colors.amber : Colors.grey,
                      ),
                      tooltip: 'Alternar Nota Interna',
                      onPressed: () {
                        setState(() {
                          _isInternalNote = !_isInternalNote;
                        });
                      },
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _isInternalNote
                              ? Colors.amber.withValues(alpha: 0.1)
                              : (isDark
                                    ? const Color(0xFF1F2937)
                                    : const Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          onChanged: _onTyping,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: _isInternalNote
                                ? 'Escribe una nota interna...'
                                : 'Mensaje...',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _isInternalNote
                            ? Colors.amber
                            : Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _sendMessage,
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

  void _showTicketsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tickets',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (!widget.isReadOnly)
                    CustomButton(
                      text: 'Crear Ticket',
                      icon: Icons.add,
                      onPressed: () {
                        _showCreateTicketDialog(context, setModalState);
                      },
                    ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _isLoadingTickets && _tickets.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _tickets.isEmpty
                        ? const Center(
                            child: Text('No hay tickets para esta sala.'),
                          )
                        : ListView.builder(
                            itemCount: _tickets.length,
                            itemBuilder: (context, index) {
                              final ticket =
                                  _tickets[index]; // Ahora es un objeto Ticket
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${ticket.ticketNumber ?? '#N/A'} - ${ticket.title ?? 'Sin título'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ticket.description ?? 'Sin descripción',
                                      ),
                                      if (ticket.images != null &&
                                          (ticket.images as List)
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: (ticket.images as List)
                                              .map(
                                                (url) => ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    url.toString(),
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => const Icon(
                                                          Icons.broken_image,
                                                          size: 60,
                                                          color: Colors.grey,
                                                        ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Status: ${_getStatusText(ticket.status ?? 0)}',
                                                style: TextStyle(
                                                  color: _getStatusColor(
                                                    ticket.status ?? 0,
                                                  ),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.copy,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                tooltip:
                                                    'Copiar número de ticket',
                                                constraints:
                                                    const BoxConstraints(),
                                                padding: EdgeInsets.zero,
                                                onPressed: () {
                                                  Clipboard.setData(
                                                    ClipboardData(
                                                      text:
                                                          ticket.ticketNumber ??
                                                          '#N/A',
                                                    ),
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Número de ticket copiado',
                                                      ),
                                                      duration: Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                          if (!widget.isReadOnly)
                                            DropdownButton<int>(
                                              value: ticket.status,
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 0,
                                                  child: Text('Abierto'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 1,
                                                  child: Text('En progreso'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 2,
                                                  child: Text('Cerrado'),
                                                ),
                                              ],
                                              onChanged: (newStatus) async {
                                                if (newStatus != null) {
                                                  final success =
                                                      await _ticketService
                                                          .updateTicketStatus(
                                                            ticket.id!,
                                                            newStatus,
                                                          );
                                                  if (success) {
                                                    setModalState(
                                                      () => _isLoadingTickets =
                                                          true,
                                                    );
                                                    await _loadTickets();
                                                    setModalState(() {});
                                                    setState(() {});
                                                  }
                                                }
                                              },
                                            ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_red_eye_outlined,
                                              color: Colors.blue,
                                            ),
                                            tooltip: 'Ver detalles',
                                            onPressed: () {
                                              showGeneralDialog(
                                                context: context,
                                                barrierDismissible: true,
                                                barrierLabel: 'Cerrar Detalles',
                                                transitionDuration:
                                                    const Duration(
                                                      milliseconds: 300,
                                                    ),
                                                pageBuilder:
                                                    (
                                                      context,
                                                      animation,
                                                      secondaryAnimation,
                                                    ) {
                                                      return Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: Material(
                                                          elevation: 16,
                                                          child: TicketDetailScreen(
                                                            ticket:
                                                                ticket, // Pasamos el objeto completo
                                                            agentName: widget
                                                                .agentName,
                                                            isReadOnly: widget
                                                                .isReadOnly,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                transitionBuilder:
                                                    (
                                                      context,
                                                      animation,
                                                      secondaryAnimation,
                                                      child,
                                                    ) {
                                                      return SlideTransition(
                                                        position:
                                                            Tween<Offset>(
                                                              begin:
                                                                  const Offset(
                                                                    1.0,
                                                                    0.0,
                                                                  ),
                                                              end: Offset.zero,
                                                            ).animate(
                                                              CurvedAnimation(
                                                                parent:
                                                                    animation,
                                                                curve: Curves
                                                                    .easeOutCubic,
                                                              ),
                                                            ),
                                                        child: child,
                                                      );
                                                    },
                                              ).then((_) async {
                                                setModalState(
                                                  () =>
                                                      _isLoadingTickets = true,
                                                );
                                                await _loadTickets();
                                                setModalState(() {});
                                                setState(() {});
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (_hasMoreTickets)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Center(
                        child: TextButton(
                          onPressed: _isLoadingTickets
                              ? null
                              : () {
                                  _loadTickets(loadMore: true);
                                  setModalState(() {});
                                },
                          child: _isLoadingTickets
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Cargar Más'),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateTicketDialog(
    BuildContext context,
    StateSetter setModalState,
  ) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    int selectedStatus = 0;
    List<Uint8List> attachedImages = [];
    bool isUploading = false;
    bool isDragging = false;
    final FocusNode focusNode = FocusNode();

    Future<void> _pickFiles(StateSetter setDialogState) async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );
      if (result != null) {
        setDialogState(() {
          for (var file in result.files) {
            if (file.bytes != null) {
              attachedImages.add(file.bytes!);
            }
          }
        });
      }
    }

    Future<void> _pasteImage(StateSetter setDialogState) async {
      final imageBytes = await Pasteboard.image;
      if (imageBytes != null) {
        setDialogState(() {
          attachedImages.add(imageBytes);
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo Ticket'),
              content: SizedBox(
                width: 500,
                child: KeyboardListener(
                  focusNode: focusNode,
                  autofocus: true,
                  onKeyEvent: (KeyEvent event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.keyV &&
                        HardwareKeyboard.instance.isControlPressed) {
                      _pasteImage(setDialogState);
                    }
                  },
                  child: DropTarget(
                    onDragDone: (detail) async {
                      for (final file in detail.files) {
                        final bytes = await file.readAsBytes();
                        setDialogState(() {
                          attachedImages.add(bytes);
                        });
                      }
                    },
                    onDragEntered: (detail) {
                      setDialogState(() => isDragging = true);
                    },
                    onDragExited: (detail) {
                      setDialogState(() => isDragging = false);
                    },
                    child: Container(
                      decoration: isDragging
                          ? BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                            )
                          : null,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              controller: titleController,
                              labelText: 'Título',
                              hintText: 'Falla en el pago',
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: descController,
                              labelText: 'Descripción',
                              hintText:
                                  'El cliente no puede procesar su tarjeta.',
                              minLines: 3,
                              maxLines: 5,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              initialValue: selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Estado',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 0,
                                  child: Text('Abierto'),
                                ),
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text('En progreso'),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text('Cerrado'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    selectedStatus = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Imágenes adjuntas (${attachedImages.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...attachedImages.asMap().entries.map((entry) {
                                  int idx = entry.key;
                                  Uint8List bytes = entry.value;
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          bytes,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: InkWell(
                                          onTap: () {
                                            setDialogState(() {
                                              attachedImages.removeAt(idx);
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                                InkWell(
                                  onTap: () => _pickFiles(setDialogState),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Subir',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Puedes arrastrar imágenes, usar el botón de subir o presionar Ctrl+V.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (isUploading)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty) return;

                          setDialogState(() {
                            isUploading = true;
                          });

                          List<String> imageUrls = [];
                          for (int i = 0; i < attachedImages.length; i++) {
                            String fileName =
                                'ticket_img_${DateTime.now().millisecondsSinceEpoch}_$i.png';
                            String? url = await _ticketService
                                .uploadTicketImageBytes(
                                  attachedImages[i],
                                  fileName,
                                );
                            if (url != null) {
                              imageUrls.add(url);
                            }
                          }

                          final success = await _ticketService.createTicket(
                            _activeRoomId,
                            titleController.text.trim(),
                            descController.text.trim(),
                            selectedStatus,
                            images: imageUrls,
                          );

                          if (success) {
                            if (mounted) Navigator.pop(context);
                            setModalState(() => _isLoadingTickets = true);
                            await _loadTickets();
                            setModalState(() {});
                          } else {
                            setDialogState(() {
                              isUploading = false;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error al crear el ticket'),
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getStatusText(int status) {
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

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _chatService.currentActiveRoomId = null;
    _chatService.removeMessageListener(_onMessageReceived);
    _chatService.removeTypingListener(_onTypingReceived);
    super.dispose();
  }
}
