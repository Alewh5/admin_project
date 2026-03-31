import 'package:flutter/material.dart';
import 'package:panel_admin_chat/models/chat_model.dart';
import '../../services/chat_service.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/custom_data_table.dart';
import '../../widgets/common/screen_header.dart';
import '../../widgets/common/user_avatar_cell.dart';
import '../../widgets/common/action_buttons_cell.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/pagination_bar.dart';
import 'package:intl/intl.dart';
import '../Chat/chat_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String agentName;
  final String agentRole;

  const HistoryScreen({
    super.key,
    required this.agentName,
    required this.agentRole,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _agentFilterController = TextEditingController();

  List<ChatRoom> _historicalRooms = [];
  bool _isLoading = false;
  bool _hasError = false;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadHistoricalRooms();
  }

  Future<void> _loadHistoricalRooms({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await _chatService.getHistoricalRoomsPaginated(
        page: page,
        limit: 20,
        agentName: _agentFilterController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _historicalRooms = result['rooms'] ?? [];
          _totalPages = result['totalPages'] ?? 1;
          _currentPage = page;
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

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Historial de Chats',
          actionWidget: Row(
            children: [
              SizedBox(
                width: 250,
                height: 40,
                child: TextField(
                  controller: _agentFilterController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por agente...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                  ),
                  onSubmitted: (_) => _loadHistoricalRooms(page: 1),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.leaderboard, color: Colors.amber),
                tooltip: 'Ver Ranking de Agentes',
                onPressed: () => _showRankingModal(context),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar Historial',
                onPressed: () {
                  _agentFilterController
                      .clear(); // Limpia el filtro si presionas actualizar
                  _loadHistoricalRooms(page: 1);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _hasError
              ? ErrorState(
                  message: 'No se pudo cargar el historial.',
                  onRetry: () => _loadHistoricalRooms(page: _currentPage),
                )
              : CustomDataTable(
                  isLoading: _isLoading,
                  isEmpty: _historicalRooms.isEmpty && !_isLoading,
                  emptyTitle: 'No hay historial',
                  emptySubtitle: 'No se encontraron chats cerrados.',
                  emptyIcon: Icons.history_outlined,
                  columns: const [
                    DataColumn(label: Text('Visitante')),
                    DataColumn(label: Text('Correo')),
                    DataColumn(label: Text('Tema')),
                    DataColumn(label: Text('Agente')),
                    DataColumn(label: Text('Fecha Cierre')),
                    DataColumn(label: Text('Calificación')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: _historicalRooms.map((room) {
                    final visitorName = room.visitorName ?? 'Visitante';
                    final visitorEmail = room.visitorEmail ?? 'Sin correo';
                    final agentName = room.agentName ?? 'Desconocido';
                    final reason = room.status;
                    final closedAt =
                        room.createdAt?.toIso8601String() ??
                        DateTime.now().toIso8601String();

                    return DataRow(
                      cells: [
                        DataCell(
                          UserAvatarCell(name: visitorName, avatarRadius: 14),
                        ),
                        DataCell(Text(visitorEmail)),
                        DataCell(
                          SizedBox(
                            width: 200,
                            child: Text(
                              reason,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(agentName)),
                        DataCell(Text(_formatDate(closedAt))),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < (room.rating ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              }),
                              if (room.ratingFeedback != null &&
                                  room.ratingFeedback!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.comment,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Ver comentario',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'Comentario del Cliente',
                                          ),
                                          content: Text(room.ratingFeedback!),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cerrar'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        DataCell(
                          const StatusBadge(
                            text: 'Cerrado',
                            icon: Icons.check_circle_outline,
                            isPositive: true,
                          ),
                        ),
                        DataCell(
                          ActionButtonsCell(
                            showView: true,
                            onView: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailScreen(
                                    room: room,
                                    agentName: widget.agentName,
                                    agentRole: widget.agentRole,
                                    isReadOnly: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
        ),
        PaginationBar(
          currentPage: _currentPage,
          totalPages: _totalPages,
          onPrevious: _currentPage > 1
              ? () => _loadHistoricalRooms(page: _currentPage - 1)
              : null,
          onNext: _currentPage < _totalPages
              ? () => _loadHistoricalRooms(page: _currentPage + 1)
              : null,
        ),
      ],
    );
  }

  void _showRankingModal(BuildContext context) {
    String selectedPeriod = '7d';
    List<dynamic> rankingData = [];
    bool isLoading = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void loadRanking() async {
              setDialogState(() => isLoading = true);
              final data = await _chatService.getAgentRanking(selectedPeriod);
              setDialogState(() {
                rankingData = data;
                isLoading = false;
              });
            }

            // Cargar la primera vez
            if (isLoading && rankingData.isEmpty) loadRanking();

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ranking de Agentes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: selectedPeriod,
                    items: const [
                      DropdownMenuItem(
                        value: '7d',
                        child: Text('Últimos 7 días'),
                      ),
                      DropdownMenuItem(
                        value: '15d',
                        child: Text('Últimos 15 días'),
                      ),
                      DropdownMenuItem(value: '1m', child: Text('Último mes')),
                      DropdownMenuItem(
                        value: '3m',
                        child: Text('Últimos 3 meses'),
                      ),
                      DropdownMenuItem(value: '1y', child: Text('Último año')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedPeriod = val);
                        loadRanking();
                      }
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                height: 400,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : rankingData.isEmpty
                    ? const Center(
                        child: Text('No hay calificaciones en este periodo.'),
                      )
                    : ListView.builder(
                        itemCount: rankingData.length,
                        itemBuilder: (context, index) {
                          final agent = rankingData[index];
                          final double promedio =
                              double.tryParse(
                                agent['promedio']?.toString() ?? '0',
                              ) ??
                              0.0;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withValues(
                                alpha: 0.1,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              agent['agentName'] ?? 'Desconocido',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${agent['totalChats']} chats calificados',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  promedio.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
