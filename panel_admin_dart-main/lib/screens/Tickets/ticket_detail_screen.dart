import 'package:flutter/material.dart';
import '../../widgets/common/status_badge.dart';
import '../../services/ticket_service.dart';
import '../../models/ticket_model.dart';

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  final bool isReadOnly;
  final String agentName;

  const TicketDetailScreen({
    super.key,
    required this.ticket,
    required this.agentName,
    this.isReadOnly = false,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen>
    with SingleTickerProviderStateMixin {
  final TicketService _ticketService = TicketService();
  late TabController _tabController;
  late int _currentStatus;
  late Ticket _ticket;

  final TextEditingController _replyController = TextEditingController();
  int? _replyStatusChange;
  bool _isSendingReply = false;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _currentStatus = _ticket.status;
    _tabController = TabController(
      length: widget.isReadOnly ? 1 : 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _replyController.dispose();
    super.dispose();
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

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 0:
        return Icons.new_releases;
      case 1:
        return Icons.hourglass_top;
      case 2:
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendReply() async {
    final msg = _replyController.text.trim();
    if (msg.isEmpty) return;

    setState(() => _isSendingReply = true);

    final ticketId = _ticket.id;
    final updatedTicket = await _ticketService.addReplyToTicket(
      ticketId,
      msg,
      widget.agentName,
      newStatus: _replyStatusChange,
    );

    if (mounted) {
      if (updatedTicket != null) {
        setState(() {
          _ticket = updatedTicket;
          _currentStatus = updatedTicket.status;
          _replyController.clear();
          _replyStatusChange = null;
          _isSendingReply = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Respuesta enviada')));
        _tabController.animateTo(0);
      } else {
        setState(() => _isSendingReply = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar respuesta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<TicketReply> _getReplies() {
    return _ticket.replies ?? [];
  }

  List<TicketImage> _getImages() {
    return _ticket.images ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final ticketNumber = _ticket.ticketNumber;
    final title = _ticket.title;
    final description = _ticket.description ?? 'Sin descripción';
    final rawImages = _getImages();
    final replies = _getReplies();

    return Container(
      width: 480,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          left: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticketNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    StatusBadge(
                      text: _getStatusText(_currentStatus),
                      icon: _getStatusIcon(_currentStatus),
                      isPositive: _currentStatus == 2,
                      isWarning: _currentStatus == 1,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              tabs: [
                const Tab(icon: Icon(Icons.info_outline), text: 'Detalles'),
                if (!widget.isReadOnly)
                  const Tab(icon: Icon(Icons.reply), text: 'Responder'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _sectionLabel('Descripción'),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          description,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (!widget.isReadOnly) ...[
                        _sectionLabel('Cambiar Estado'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          value: _currentStatus,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Abierto')),
                            DropdownMenuItem(
                              value: 1,
                              child: Text('En progreso'),
                            ),
                            DropdownMenuItem(value: 2, child: Text('Cerrado')),
                          ],
                          onChanged: (newStatus) async {
                            if (newStatus != null &&
                                newStatus != _currentStatus) {
                              final success = await _ticketService
                                  .updateTicketStatus(_ticket.id, newStatus);
                              if (success && mounted) {
                                setState(() => _currentStatus = newStatus);
                                final messenger = ScaffoldMessenger.of(context);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Estado actualizado'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      _sectionLabel('Respuestas (${replies.length})'),
                      const SizedBox(height: 8),
                      if (replies.isEmpty)
                        const Text(
                          'Aún no hay respuestas en este ticket.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        )
                      else
                        ...replies.map((reply) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      reply.agentName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDate(reply.createdAt),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  reply.message,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                      const SizedBox(height: 20),

                      _sectionLabel('Imágenes Adjuntas'),
                      const SizedBox(height: 8),
                      if (rawImages.isEmpty)
                        const Text(
                          'No hay imágenes adjuntas en este ticket.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: rawImages.map((imgData) {
                            final urlStr = imgData.fileUrl;

                            if (urlStr.isEmpty) return const SizedBox.shrink();

                            return InkWell(
                              onTap: () =>
                                  _showFullScreenImage(context, urlStr),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    urlStr,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) =>
                                        const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 36,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    loadingBuilder: (_, child, prog) {
                                      if (prog == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),

                if (!widget.isReadOnly)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Mensaje de respuesta'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _replyController,
                          minLines: 5,
                          maxLines: 10,
                          decoration: InputDecoration(
                            hintText: 'Escribe tu respuesta al ticket...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sectionLabel('Cambiar estado (opcional)'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int?>(
                          initialValue: _replyStatusChange,
                          decoration: InputDecoration(
                            hintText: 'No cambiar estado',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('No cambiar estado'),
                            ),
                            DropdownMenuItem(value: 0, child: Text('Abierto')),
                            DropdownMenuItem(
                              value: 1,
                              child: Text('En progreso'),
                            ),
                            DropdownMenuItem(value: 2, child: Text('Cerrado')),
                          ],
                          onChanged: (val) =>
                              setState(() => _replyStatusChange = val),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _isSendingReply
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: const Text('Enviar Respuesta'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isSendingReply ? null : _sendReply,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
  );

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.toString();
    }
  }
}
