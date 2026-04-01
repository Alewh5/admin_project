import 'package:flutter/material.dart';
import '../../../models/task_model.dart';
import '../../../services/kanban_service.dart';
import '../../../config/constants.dart';

class TaskDetailModal extends StatefulWidget {
  final TaskModel? task;
  final List<dynamic> projectMembers;
  final VoidCallback onDataChanged;

  final int? proyectoId;
  final int? sprintId;
  final int? columnId;

  const TaskDetailModal({
    super.key,
    this.task,
    required this.projectMembers,
    required this.onDataChanged,
    this.proyectoId,
    this.sprintId,
    this.columnId,
  });

  @override
  State<TaskDetailModal> createState() => _TaskDetailModalState();
}

class _TaskDetailModalState extends State<TaskDetailModal> {
  final KanbanService _kanbanService = KanbanService();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _estimacionCtrl;

  late String _prioridad;
  late int _dificultad;
  int? _assignedUserId;

  bool _isLoading = false;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.task == null;

    _titleCtrl = TextEditingController(text: widget.task?.titulo ?? '');
    _descCtrl = TextEditingController(text: widget.task?.descripcion ?? '');
    _estimacionCtrl = TextEditingController(
      text: widget.task?.estimacion?.toString() ?? '',
    );

    _prioridad = widget.task != null
        ? (widget.task!.prioridad.length == 1 ? widget.task!.prioridad : '3')
        : '3';
    _dificultad = widget.task?.dificultad ?? 3;

    if (widget.task != null && widget.task!.assignees.isNotEmpty) {
      _assignedUserId = widget.task!.assignees.first['id'];
    }
  }

  Future<void> _saveChanges() async {
    if (_titleCtrl.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    if (widget.task == null) {
      final newTask = await _kanbanService.createTask(
        widget.proyectoId!,
        widget.sprintId!,
        widget.columnId!,
        _titleCtrl.text.trim(),
        _descCtrl.text.trim(),
      );
      if (newTask != null) {
        final data = {
          'prioridad': _prioridad,
          'dificultad': _dificultad,
          'estimacion': double.tryParse(_estimacionCtrl.text),
          if (_assignedUserId != null) 'assignees': [_assignedUserId],
        };
        await _kanbanService.updateTaskDetails(newTask.id, data);
        widget.onDataChanged();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _isLoading = false);
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Error al crear tarea')));
      }
    } else {
      final data = {
        'titulo': _titleCtrl.text.trim(),
        'descripcion': _descCtrl.text.trim(),
        'prioridad': _prioridad,
        'dificultad': _dificultad,
        'estimacion': double.tryParse(_estimacionCtrl.text),
        if (_assignedUserId != null) 'assignees': [_assignedUserId],
      };

      final ok = await _kanbanService.updateTaskDetails(widget.task!.id, data);
      setState(() => _isLoading = false);

      if (ok) {
        widget.onDataChanged();
        setState(() => _isEditing = false);
      } else {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Error al guardar')));
      }
    }
  }

  Future<void> _recordTime(String event) async {
    if (widget.task == null) return;
    setState(() => _isLoading = true);
    final data = <String, dynamic>{};
    if (event == 'start') {
      data['fechaRealInicio'] = DateTime.now().toIso8601String();
    } else if (event == 'finish') {
      data['fechaRealFin'] = DateTime.now().toIso8601String();
    }

    final ok = await _kanbanService.updateTaskDetails(widget.task!.id, data);
    setState(() => _isLoading = false);

    if (ok) {
      widget.onDataChanged();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 550,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.task == null
                            ? 'Crear Tarea'
                            : 'Detalles de la Tarea',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          if (widget.task != null && !_isEditing)
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Editar Tarea',
                              onPressed: () =>
                                  setState(() => _isEditing = true),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isEditing) ...[
                    TextField(
                      controller: _titleCtrl,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: theme.textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else ...[
                    Text(
                      _titleCtrl.text.isEmpty ? 'Sin Título' : _titleCtrl.text,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _descCtrl.text.isEmpty
                          ? 'No hay descripción'
                          : _descCtrl.text,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],

                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Asignado a',
                            border: _isEditing
                                ? const OutlineInputBorder()
                                : InputBorder.none,
                            isDense: true,
                            filled: !_isEditing,
                            labelStyle: TextStyle(fontSize: 12),
                          ),
                          style: theme.textTheme.bodySmall,
                          value: _assignedUserId,
                          icon: _isEditing
                              ? const Icon(Icons.arrow_drop_down)
                              : const SizedBox.shrink(),
                          items: widget.projectMembers
                              .map(
                                (u) => DropdownMenuItem<int>(
                                  value: u['id'],
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundImage: u['avatar'] != null
                                            ? NetworkImage(
                                                '${Constants.baseUrl.replaceAll('/api', '')}${u['avatar']}',
                                              )
                                            : null,
                                        child: u['avatar'] == null
                                            ? Text(
                                                u['firstName'][0],
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${u['firstName']} ${u['lastName']}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _isEditing
                              ? (v) => setState(() => _assignedUserId = v)
                              : null,
                        ),
                      ),

                      SizedBox(
                        width: 140,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Prioridad',
                            border: _isEditing
                                ? const OutlineInputBorder()
                                : InputBorder.none,
                            isDense: true,
                            filled: !_isEditing,
                            labelStyle: TextStyle(fontSize: 12),
                          ),
                          style: theme.textTheme.bodySmall,
                          value: _prioridad,
                          icon: _isEditing
                              ? const Icon(Icons.arrow_drop_down)
                              : const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(
                              value: '1',
                              child: Text('1 - Muy Baja'),
                            ),
                            DropdownMenuItem(
                              value: '2',
                              child: Text('2 - Baja'),
                            ),
                            DropdownMenuItem(
                              value: '3',
                              child: Text('3 - Media'),
                            ),
                            DropdownMenuItem(
                              value: '4',
                              child: Text('4 - Alta'),
                            ),
                            DropdownMenuItem(
                              value: '5',
                              child: Text('5 - Urgente'),
                            ),
                          ],
                          onChanged: _isEditing
                              ? (v) => setState(() => _prioridad = v!)
                              : null,
                        ),
                      ),

                      SizedBox(
                        width: 110,
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Dificultad',
                            border: _isEditing
                                ? const OutlineInputBorder()
                                : InputBorder.none,
                            isDense: true,
                            filled: !_isEditing,
                            labelStyle: TextStyle(fontSize: 12),
                          ),
                          style: theme.textTheme.bodySmall,
                          value: _dificultad,
                          icon: _isEditing
                              ? const Icon(Icons.arrow_drop_down)
                              : const SizedBox.shrink(),
                          items: List.generate(
                            5,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('Nivel ${i + 1}'),
                            ),
                          ),
                          onChanged: _isEditing
                              ? (v) => setState(() => _dificultad = v!)
                              : null,
                        ),
                      ),

                      if (_isEditing)
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _estimacionCtrl,
                            keyboardType: TextInputType.number,
                            style: theme.textTheme.bodySmall,
                            decoration: const InputDecoration(
                              labelText: 'Est. (hr)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              labelStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Est. (hr)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                _estimacionCtrl.text.isEmpty
                                    ? '-'
                                    : _estimacionCtrl.text,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  if (widget.task != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Línea de Tiempo Operativa',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Inicio Real',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            widget.task!.fechaRealInicio != null
                                ? Text(
                                    '${widget.task!.fechaRealInicio!.toLocal()}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    icon: const Icon(
                                      Icons.play_arrow,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Iniciar',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: () => _recordTime('start'),
                                  ),
                          ],
                        ),
                        Column(
                          children: [
                            Text('Fin Real', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            widget.task!.fechaRealFin != null
                                ? Text(
                                    '${widget.task!.fechaRealFin!.toLocal()}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    icon: const Icon(Icons.stop, size: 16),
                                    label: const Text(
                                      'Finalizar',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed:
                                        widget.task!.fechaRealInicio == null
                                        ? null
                                        : () => _recordTime('finish'),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  if (_isEditing) ...[
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.task != null)
                          TextButton(
                            onPressed: () => setState(() {
                              _isEditing = false;
                              _titleCtrl.text = widget.task!.titulo;
                              _descCtrl.text = widget.task!.descripcion ?? '';
                              _estimacionCtrl.text =
                                  widget.task!.estimacion?.toString() ?? '';
                              _prioridad = widget.task!.prioridad.length == 1
                                  ? widget.task!.prioridad
                                  : '3';
                              _dificultad = widget.task!.dificultad;
                              if (widget.task!.assignees.isNotEmpty) {
                                _assignedUserId =
                                    widget.task!.assignees.first['id'];
                              }
                            }),
                            child: const Text('Cancelar'),
                          ),

                        if (widget.task == null)
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),

                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveChanges,
                          child: const Text('Guardar'),
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
