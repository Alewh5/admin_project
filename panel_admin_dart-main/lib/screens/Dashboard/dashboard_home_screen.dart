import 'package:flutter/material.dart';
import 'package:panel_admin_chat/models/chat_model.dart';
import '../../services/chat_service.dart';
import '../../widgets/common/error_state.dart';

class DashboardHomeScreen extends StatefulWidget {
  final String agentName;
  final String agentRole;
  final List<ChatRoom> activeRooms;

  const DashboardHomeScreen({
    super.key,
    required this.agentName,
    required this.agentRole,
    required this.activeRooms,
  });

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  final ChatService _chatService = ChatService();
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final data = await _chatService.getSummary();
      if (mounted) {
        setState(() {
          _summary = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError || _summary == null) {
      return ErrorState(
        message: 'No se pudieron cargar las métricas del sistema.',
        onRetry: _loadSummary,
      );
    }

    final unassigned = widget.activeRooms
        .where((r) => r.agentId == null)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Saludo ────────────────────────────────────────────────────
            Text(
              'Bienvenido, ${widget.agentName} 👋',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Aquí tienes el resumen del día.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // ─── Tarjetas de métricas ───────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _MetricCard(
                      label: 'Chats activos',
                      value: '${_summary!['chatsActivos'] ?? 0}',
                      icon: Icons.forum_rounded,
                      color: const Color(0xFF3B82F6),
                    ),
                    _MetricCard(
                      label: 'Sin asignar',
                      value: '${_summary!['chatsSinAsignar'] ?? 0}',
                      icon: Icons.person_off_outlined,
                      color: (_summary!['chatsSinAsignar'] ?? 0) > 0
                          ? Colors.orange
                          : const Color(0xFF10B981),
                    ),
                    _MetricCard(
                      label: 'Tickets abiertos',
                      value: '${_summary!['ticketsAbiertos'] ?? 0}',
                      icon: Icons.confirmation_number_outlined,
                      color: const Color(0xFF8B5CF6),
                    ),
                    _MetricCard(
                      label: 'Resueltos hoy',
                      value: '${_summary!['ticketsResueltos'] ?? 0}',
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF10B981),
                    ),
                    _MetricCard(
                      label: 'Calificación Promedio',
                      value: '${_summary!['promedioCalificacion'] ?? '0.0'}',
                      icon: Icons.star_rounded,
                      color: Colors.amber,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // ─── Lista de chats sin atender ─────────────────────────────
            if (unassigned.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chats esperando atención (${unassigned.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...unassigned
                  .take(5)
                  .map((room) => _UnassignedChatTile(room: room)),
              if (unassigned.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... y ${unassigned.length - 5} más. Ve a Chats Activos para verlos todos.',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
            ] else ...[
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Todos los chats están atendidos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Tarjeta de métrica ────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tile de chat sin asignar ────────────────────────────────────────────────
class _UnassignedChatTile extends StatelessWidget {
  final ChatRoom room;

  const _UnassignedChatTile({required this.room});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withValues(alpha: 0.15),
          child: const Icon(Icons.person, color: Colors.orange),
        ),
        title: Text(
          room.visitorEmail ?? 'Visitante desconocido',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          room.status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Sin asignar',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
