import 'package:flutter/material.dart';
import '../../config/app_roles.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/user_avatar.dart';
import 'chat_detail_screen.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  final List<ChatRoom> activeRooms;
  final String agentName;
  final String agentRole;

  const ChatScreen({
    super.key,
    required this.activeRooms,
    required this.agentName,
    required this.agentRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ChatRoom? _selectedRoom;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        if (isDesktop) {
          return Row(
            children: [
              SizedBox(width: 350, child: _buildChatList()),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: _selectedRoom == null
                    ? _buildEmptyState()
                    : _buildChatDetail(_selectedRoom!),
              ),
            ],
          );
        } else {
          if (_selectedRoom != null) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) setState(() => _selectedRoom = null);
              },
              child: _buildChatDetail(_selectedRoom!),
            );
          }
          return _buildChatList();
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      title: 'Selecciona una conversación',
      subtitle: 'Elige un chat de la lista izquierda para comenzar.',
      icon: Icons.forum_rounded,
    );
  }

  Widget _buildChatDetail(ChatRoom room) {
    bool isMyChat = room.agentId == null || room.agentName == widget.agentName;

    return ChatDetailScreen(
      key: ValueKey(room.id),
      room: room,
      agentName: widget.agentName,
      agentRole: widget.agentRole,
      isReadOnly: !isMyChat,
      onBack: () {
        setState(() => _selectedRoom = null);
      },
    );
  }

  Widget _buildChatList() {
    final sortedRooms = List<ChatRoom>.from(widget.activeRooms);
    sortedRooms.sort((a, b) {
      final aIsMine = a.agentId != null && a.agentName == widget.agentName;
      final bIsMine = b.agentId != null && b.agentName == widget.agentName;
      final aUnassigned = a.agentId == null;
      final bUnassigned = b.agentId == null;

      if (aIsMine && !bIsMine) return -1;
      if (!aIsMine && bIsMine) return 1;

      if (aUnassigned && !bUnassigned) return -1;
      if (!aUnassigned && bUnassigned) return 1;

      return 0;
    });

    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomTextField(
              controller: TextEditingController(),
              hintText: 'Buscar chats...',
              prefixIcon: Icons.search,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: sortedRooms.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final room = sortedRooms[index];
                return _buildChatListItem(room);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListItem(ChatRoom room) {
    final isAttended = room.agentId != null;
    final assignedAgentName = room.agentName ?? 'Sin asignar';
    final isMine = isAttended && assignedAgentName == widget.agentName;
    final isSelected = _selectedRoom?.id == room.id;

    return ListTile(
      selected: isSelected,
      selectedTileColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: UserAvatar(
        name: room.visitorEmail ?? 'Desconocido',
        radius: 25,
        backgroundColor: isMine
            ? Colors.green.withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        textColor: isMine
            ? Colors.green[800]
            : Theme.of(context).colorScheme.primary,
        showStatus: true,
        isActive: isAttended,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              room.visitorEmail ?? 'Desconocido',
              style: TextStyle(
                fontWeight: isMine ? FontWeight.bold : FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (room.status == 'closed')
            const Icon(Icons.check_circle, size: 16, color: Colors.grey),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            room.status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isAttended ? Icons.person : Icons.person_outline,
                size: 14,
                color: isMine ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                isMine ? 'Tú' : assignedAgentName,
                style: TextStyle(
                  fontSize: 12,
                  color: isMine ? Colors.green : Colors.grey,
                  fontWeight: isMine ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (AppRoles.isSupervisorOrHigher(widget.agentRole))
                InkWell(
                  onTap: () => _showAssignDialog(room),
                  child: const Text(
                    'Reasignar',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
            ],
          ),
        ],
      ),
      onTap: () {
        setState(() {
          _selectedRoom = room;
        });
      },
    );
  }

  void _showAssignDialog(ChatRoom room) async {
    final users = await UserService().getUsers();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        String? selectedUserId;
        String? selectedUserName;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Asignar Chat'),
          content: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Selecciona un Agente',
              border: OutlineInputBorder(),
            ),
            items: users.map<DropdownMenuItem<String>>((var user) {
              return DropdownMenuItem<String>(
                value: user['id'].toString(),
                child: Text('${user['firstName']} - ${user['role']['name']}'),
              );
            }).toList(),
            onChanged: (value) {
              selectedUserId = value;
              final selectedUser = users.firstWhere(
                (u) => u['id'].toString() == value,
              );
              selectedUserName = selectedUser['firstName'];
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            CustomButton(
              text: 'Asignar',
              width: 120,
              height: 40,
              onPressed: () async {
                if (selectedUserId != null && selectedUserName != null) {
                  final navigator = Navigator.of(context);
                  await ChatService().assignAgent(
                    (room.roomId ?? room.id.toString()),
                    selectedUserId!,
                    selectedUserName!,
                    widget.agentName,
                  );
                  if (mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
