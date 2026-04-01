import 'package:flutter/material.dart';
import '../../../models/proyecto_model.dart';
import '../../../models/task_comment_model.dart';
import '../../../services/kanban_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../widgets/common/custom_text_field.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/error_state.dart';
import '../../../widgets/common/chat_bubble.dart';

class ConversacionesTab extends StatefulWidget {
  final Proyecto proyecto;
  final String? agentName;
  final int? agentId;

  const ConversacionesTab({
    super.key,
    required this.proyecto,
    this.agentName,
    this.agentId,
  });

  @override
  State<ConversacionesTab> createState() => _ConversacionesTabState();
}

class _ConversacionesTabState extends State<ConversacionesTab> {
  final KanbanService _kanbanService = KanbanService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  IO.Socket? socket;

  int get defaultTaskId => widget.proyecto.id;

  List<TaskCommentModel> _comments = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
    _connectSocket();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    socket?.disconnect();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoading &&
        _hasMore) {
      _loadComments(loadMore: true);
    }
  }

  Future<void> _loadComments({bool loadMore = false}) async {
    if (_isLoading) return;

    if (loadMore) {
      _currentPage++;
    } else {
      _currentPage = 1;
      _comments.clear();
      _hasMore = true;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _kanbanService.getProjectChat(
        widget.proyecto.id,
        page: _currentPage,
        limit: 30,
      );
      final newComments = response['items'] as List<TaskCommentModel>;

      if (mounted) {
        setState(() {
          if (loadMore) {
            _comments.addAll(newComments);
          } else {
            _comments = newComments;
          }
          _hasMore = _currentPage < (response['totalPages'] as int? ?? 1);
          _hasError = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _connectSocket() {
    socket = IO.io(
      'http://localhost:3000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket?.on('kanban_project_${widget.proyecto.id}_chat', (data) {
      if (!mounted) return;
      final newComment = TaskCommentModel.fromJson(data);
      setState(() {
        _comments.insert(0, newComment);
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    await _kanbanService.addProjectChat(
      widget.proyecto.id,
      widget.agentId ?? 1,
      text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isLoading && _comments.isEmpty)
          const Expanded(child: Center(child: CircularProgressIndicator())),

        if (_hasError)
          Expanded(
            child: ErrorState(
              message: 'Error al cargar los mensajes de conversación',
              onRetry: _loadComments,
            ),
          ),

        if (!_isLoading && !_hasError && _comments.isEmpty)
          const Expanded(
            child: EmptyState(
              title: 'Aún no hay mensajes',
              subtitle: 'Escribe el primero para comenzar',
              icon: Icons.chat_bubble_outline,
            ),
          ),

        if (_comments.isNotEmpty)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _comments.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _comments.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final comment = _comments[index];

                final isMe = comment.userId == (widget.agentId ?? 1);

                return ChatBubble(comment: comment, isMe: isMe);
              },
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _controller,
                  hintText: 'Escribe un mensaje...',
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CustomButton(
                onPressed: _sendMessage,
                text: 'Enviar',
                icon: Icons.send,
                width: 130,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
