import 'package:flutter/material.dart';
import '../../../models/proyecto_model.dart';
import '../../../widgets/common/error_state.dart';
import '../../../services/kanban_service.dart';

class RendimientoTab extends StatefulWidget {
  final Proyecto proyecto;
  const RendimientoTab({super.key, required this.proyecto});

  @override
  State<RendimientoTab> createState() => _RendimientoTabState();
}

class _RendimientoTabState extends State<RendimientoTab> {
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _metrics;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final metrics = await KanbanService().getProjectMetrics(widget.proyecto.id);
      
      if (mounted) {
        setState(() {
          _metrics = metrics;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError || _metrics == null) {
      return ErrorState(
        message: 'Error al cargar métricas de rendimiento',
        onRetry: _loadMetrics,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Métricas del Proyecto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard('Total Tareas', _metrics!['totalTasks'].toString(), Icons.assignment, Colors.blue),
              _buildMetricCard('Completadas', _metrics!['completedTasks'].toString(), Icons.check_circle, Colors.green),
              _buildMetricCard('Atrasadas', _metrics!['overdueTasks'].toString(), Icons.warning, Colors.red),
              _buildMetricCard('Comentarios', _metrics!['totalComments'].toString(), Icons.comment, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Progreso General',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_metrics!['completedTasks'] as int) / (_metrics!['totalTasks'] as int),
            minHeight: 10,
            backgroundColor: Theme.of(context).dividerColor,
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          Text('${(((_metrics!['completedTasks'] as int) / (_metrics!['totalTasks'] as int)) * 100).toStringAsFixed(1)}% Completado'),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
