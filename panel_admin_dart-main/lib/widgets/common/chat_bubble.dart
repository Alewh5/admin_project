import 'package:flutter/material.dart';
import '../../models/task_comment_model.dart';

class ChatBubble extends StatelessWidget {
  final TaskCommentModel comment;
  final bool isMe;

  const ChatBubble({super.key, required this.comment, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8, left: 32, right: 32),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              comment.user?['firstName'] ?? 'Usuario',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(comment.contenido),
            const SizedBox(height: 4),
            Text(
              comment.createdAt,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
