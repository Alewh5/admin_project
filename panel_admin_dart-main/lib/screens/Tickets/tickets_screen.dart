import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ticket_service.dart';
import '../../models/ticket_model.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/custom_data_table.dart';
import '../../widgets/common/screen_header.dart';
import '../../widgets/common/user_avatar_cell.dart';
import '../../widgets/common/action_buttons_cell.dart';
import '../../widgets/common/error_state.dart';
import 'ticket_detail_screen.dart';

class TicketsScreen extends StatefulWidget {
  final String agentRole;
  final String agentName;
  final bool isReadOnly;

  const TicketsScreen({
    super.key,
    required this.agentRole,
    required this.agentName,
    this.isReadOnly = false,
  });

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final TicketService _ticketService = TicketService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Ticket> _tickets = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasError = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoading &&
        _hasMore) {
      _loadTickets(loadMore: true);
    }
  }

  Future<void> _loadTickets({bool loadMore = false}) async {
    if (_isLoading) return;

    if (loadMore) {
      _currentPage++;
    } else {
      _currentPage = 1;
      _tickets.clear();
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _ticketService.getAllTickets(
        page: _currentPage,
        limit: 20,
        search: _searchQuery,
      );
      final newTickets = response['tickets'] as List<Ticket>;

      if (mounted) {
        setState(() {
          if (loadMore) {
            _tickets.addAll(newTickets);
          } else {
            _tickets = newTickets;
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

  void _onSearchSubmit(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
    _loadTickets();
  }

  bool _isStatusPositive(int status) {
    return status == 2; // Green when closed
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 0:
        return Icons.mail_outline;
      case 1:
        return Icons.hourglass_top;
      case 2:
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Gestión de Tickets',
          actionWidget: _isLoading && _tickets.isNotEmpty
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por número de ticket o correo...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchSubmit('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              isDense: true,
            ),
            onSubmitted: _onSearchSubmit,
            textInputAction: TextInputAction.search,
          ),
        ),
        Expanded(
          child: _hasError
              ? ErrorState(
                  message: 'No se pudieron cargar los tickets.',
                  onRetry: _loadTickets,
                )
              : _buildTicketList(),
        ),
      ],
    );
  }

  Widget _buildTicketList() {
    return CustomDataTable(
      scrollController: _scrollController,
      isLoading: _isLoading,
      isEmpty: _tickets.isEmpty,
      emptyTitle: 'No hay tickets',
      emptySubtitle: 'No se encontraron tickets en el sistema.',
      emptyIcon: Icons.confirmation_number_outlined,
      columns: const [
        DataColumn(label: Text('Ticket Number')),
        DataColumn(label: Text('Título')),
        DataColumn(label: Text('Visitante')),
        DataColumn(label: Text('Agente')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Acciones')),
      ],
      rows: _tickets.map((ticket) {
        final room = ticket.room ?? {};
        final visitorName = room['firstName'] ?? room['email'] ?? 'Visitante';
        final agentName = room['agentName'] ?? 'Desconocido';
        final ticketIdText = ticket.ticketNumber;

        return DataRow(
          cells: [
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ticketIdText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                    tooltip: 'Copiar número de ticket',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: ticketIdText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Número de ticket copiado'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            DataCell(
              SizedBox(
                width: 250,
                child: Text(
                  ticket.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(UserAvatarCell(name: visitorName, avatarRadius: 14)),
            DataCell(Text(agentName)),
            DataCell(
              widget.isReadOnly
                  ? StatusBadge(
                      text: ticket.statusText,
                      icon: _getStatusIcon(ticket.status),
                      isPositive: _isStatusPositive(ticket.status),
                      isWarning: ticket.status == 1,
                    )
                  : DropdownButton<int>(
                      value: ticket.status,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Abierto')),
                        DropdownMenuItem(value: 1, child: Text('En progreso')),
                        DropdownMenuItem(value: 2, child: Text('Cerrado')),
                      ],
                      onChanged: (newStatus) async {
                        if (newStatus != null) {
                          final success = await _ticketService
                              .updateTicketStatus(ticket.id, newStatus);
                          if (success) {
                            setState(() {
                              _loadTickets(); // Reload or update model
                            });
                          }
                        }
                      },
                    ),
            ),
            DataCell(
              ActionButtonsCell(
                showView: true,
                onView: () {
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: 'Cerrar Detalles',
                    transitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Material(
                          elevation: 16,
                          child: TicketDetailScreen(
                            ticket: ticket,
                            agentName: widget.agentName,
                            isReadOnly: widget.isReadOnly,
                          ),
                        ),
                      );
                    },
                    transitionBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: child,
                          );
                        },
                  ).then((_) {
                    _loadTickets();
                  });
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
