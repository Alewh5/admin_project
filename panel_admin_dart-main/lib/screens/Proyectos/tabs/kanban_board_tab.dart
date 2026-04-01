import 'package:flutter/material.dart';
import '../../../models/proyecto_model.dart';
import '../../../models/sprint_model.dart';
import '../../../models/task_column_model.dart';
import '../../../models/task_model.dart';
import '../../../services/kanban_service.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/error_state.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/kanban_task_card.dart';
import '../../../widgets/common/form_dialog_layout.dart';
import '../../../services/proyectos_service.dart';
import 'task_detail_modal.dart';

class KanbanBoardTab extends StatefulWidget {
  final Proyecto proyecto;
  final int? agentId;

  const KanbanBoardTab({super.key, required this.proyecto, this.agentId});

  @override
  State<KanbanBoardTab> createState() => _KanbanBoardTabState();
}

class _KanbanBoardTabState extends State<KanbanBoardTab> {
  final KanbanService _kanbanService = KanbanService();
  bool _isSidebarExpanded = true;

  List<SprintModel> _sprints = [];
  SprintModel? _selectedSprint;
  bool _isLoadingSprints = true;
  bool _hasSprintsError = false;

  final ProyectosService _proyectosService = ProyectosService();
  List<dynamic> _projectMembers = [];

  List<TaskColumnModel> _columns = [];
  bool _isLoadingBoard = false;
  bool _hasBoardError = false;

  @override
  void initState() {
    super.initState();
    _loadSprints();
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    try {
      final team = await _proyectosService.getProjectTeam(widget.proyecto.id);
      if (mounted) setState(() => _projectMembers = team);
    } catch (e) {
      debugPrint('Error cargando equipo: $e');
    }
  }

  Future<void> _loadSprints() async {
    setState(() {
      _isLoadingSprints = true;
      _hasSprintsError = false;
    });

    try {
      final sprints = await _kanbanService.getSprints(widget.proyecto.id);
      if (mounted) {
        setState(() {
          _sprints = sprints;
          _isLoadingSprints = false;
          if (_sprints.isNotEmpty) {
            _selectedSprint = _sprints.first;
            _loadBoard();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasSprintsError = true;
          _isLoadingSprints = false;
        });
      }
    }
  }

  Future<void> _loadBoard() async {
    if (_selectedSprint == null) return;

    setState(() {
      _isLoadingBoard = true;
      _hasBoardError = false;
    });

    try {
      final columns = await _kanbanService.getProjectColumns(
        widget.proyecto.id,
        sprintId: _selectedSprint!.id,
      );
      if (mounted) {
        setState(() {
          _columns = columns;
          _isLoadingBoard = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasBoardError = true;
          _isLoadingBoard = false;
        });
      }
    }
  }

  void _showAddSprintModal() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => FormDialogLayout(
        title: 'Agregar Sprint',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Sprint',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        onSave: () async {
          if (nameController.text.trim().isEmpty) return false;
          final newSprint = await _kanbanService.createSprint(
            widget.proyecto.id,
            nameController.text.trim(),
            descController.text.trim(),
          );
          return newSprint != null;
        },
        onSuccess: _loadSprints,
        errorMessage: 'Error al crear sprint',
      ),
    );
  }

  void _showAddTaskModal(TaskColumnModel column) {
    if (_selectedSprint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un sprint primero.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: TaskDetailModal(
          task: null,
          projectMembers: _projectMembers,
          onDataChanged: _loadBoard,
          proyectoId: widget.proyecto.id,
          sprintId: _selectedSprint!.id,
          columnId: column.id,
        ),
      ),
    );
  }

  void _showConfigColumnsModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar Estados (Columnas)'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Crea o edita los estados globales del tablero.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 16),
              ..._columns.map(
                (col) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(
                      int.parse(col.color.replaceFirst('#', '0xFF')),
                    ),
                    radius: 10,
                  ),
                  title: Text(col.nombre),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditOrCreateColumnModal(column: col);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditOrCreateColumnModal();
                },
                text: 'Añadir Nuevo Estado',
                icon: Icons.add,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showEditOrCreateColumnModal({TaskColumnModel? column}) {
    final nameCtrl = TextEditingController(text: column?.nombre ?? '');
    String selectedHex = column?.color ?? '#e0e0e0';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => FormDialogLayout(
          title: column == null ? 'Nuevo Estado' : 'Editar Estado',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Estado',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Color Hexadecimal (Ej. #42A5F5)'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(
                        int.parse(selectedHex.replaceFirst('#', '0xFF')),
                      ),
                      radius: 15,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        onChanged: (val) {
                          if (val.length == 7 && val.startsWith('#')) {
                            setModalState(() => selectedHex = val);
                          }
                        },
                        controller: TextEditingController(text: selectedHex),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          onSave: () async {
            if (nameCtrl.text.trim().isEmpty) return false;
            if (column == null) {
              return await _kanbanService.createColumn(
                widget.proyecto.id,
                nameCtrl.text.trim(),
                selectedHex,
                _columns.length + 1,
              );
            } else {
              return await _kanbanService.updateColumn(
                column.id,
                nameCtrl.text.trim(),
                selectedHex,
              );
            }
          },
          onSuccess: _loadBoard,
          errorMessage: 'Error al procesar columna',
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: _isSidebarExpanded ? 250 : 70,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: SizedBox(
              height: 48,
              child: ClipRect(
                child: OverflowBox(
                  maxWidth: 250,
                  minWidth: 70,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: _isSidebarExpanded ? 250 : 70,
                    child: Row(
                      mainAxisAlignment: _isSidebarExpanded
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.center,
                      children: [
                        if (_isSidebarExpanded)
                          const Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Text(
                              'Sprints',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (_isSidebarExpanded)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add, size: 20),
                                onPressed: _showAddSprintModal,
                                tooltip: 'Nuevo Sprint',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  size: 16,
                                ),
                                onPressed: () =>
                                    setState(() => _isSidebarExpanded = false),
                                tooltip: 'Contraer',
                              ),
                            ],
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: () =>
                                setState(() => _isSidebarExpanded = true),
                            tooltip: 'Expandir',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isSidebarExpanded) ...[
            Expanded(
              child: _isLoadingSprints
                  ? const Center(child: CircularProgressIndicator())
                  : _hasSprintsError
                  ? ErrorState(
                      message: 'Error al cargar sprints',
                      onRetry: _loadSprints,
                    )
                  : _sprints.isEmpty
                  ? Center(
                      child: Text(
                        'Sin sprints',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _sprints.length,
                      itemBuilder: (context, index) {
                        final sprint = _sprints[index];
                        final isSelected = _selectedSprint?.id == sprint.id;
                        return ListTile(
                          tileColor: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          title: Text(
                            sprint.nombre,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            sprint.estado == 0 ? 'Planeado' : 'Activo',
                          ),
                          selected: isSelected,
                          onTap: () {
                            setState(() => _selectedSprint = sprint);
                            _loadBoard();
                          },
                        );
                      },
                    ),
            ),
          ] else ...[
            Expanded(
              child: _isLoadingSprints
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _sprints.length,
                      itemBuilder: (context, index) {
                        final sprint = _sprints[index];
                        final isSelected = _selectedSprint?.id == sprint.id;
                        return Tooltip(
                          message: sprint.nombre,
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedSprint = sprint);
                              _loadBoard();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.av_timer,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).iconTheme.color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddSprintModal,
              tooltip: 'Agregar Sprint',
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildMainBoard() {
    if (_sprints.isEmpty && !_isLoadingSprints) {
      return const EmptyState(
        title: 'No hay sprints activos',
        subtitle:
            'Crea un sprint en la barra lateral para comenzar a organizar tareas.',
        icon: Icons.view_kanban_outlined,
      );
    }

    if (_isLoadingBoard) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasBoardError) {
      return ErrorState(
        message: 'Error al cargar el tablero',
        onRetry: _loadBoard,
      );
    }

    if (_columns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              size: 64,
              color: Theme.of(context).iconTheme.color,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay columnas en el proyecto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CustomButton(
              onPressed: () async {
                setState(() => _isLoadingBoard = true);
                try {
                  await _kanbanService.initializeDefaultColumns(
                    widget.proyecto.id,
                  );
                  await _loadBoard();
                } catch (e) {
                  setState(() => _isLoadingBoard = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error al inicializar tablero'),
                      ),
                    );
                  }
                }
              },
              text: 'Inicializar Tablero',
              width: 200,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sprint: ${_selectedSprint?.nombre ?? ''}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: _showConfigColumnsModal,
                tooltip: 'Configurar Estados',
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _columns
                  .map<Widget>((col) => _buildColumn(col))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(TaskColumnModel column) {
    return DragTarget<TaskModel>(
      onWillAcceptWithDetails: (details) => details.data.columnId != column.id,
      onAcceptWithDetails: (details) async {
        final task = details.data;
        bool success = await _kanbanService.moveTask(task.id, column.id);
        if (success) {
          _loadBoard();
        } else if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Error al mover tarea')));
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          width: 250,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: isHovered
                ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: isHovered
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(column.color.replaceFirst('#', '0xFF')),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        column.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${column.tasks.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: column.tasks.length,
                  itemBuilder: (context, index) {
                    final task = column.tasks[index];
                    return Draggable<TaskModel>(
                      data: task,
                      feedback: Material(
                        elevation: 6,
                        color: Colors.transparent,
                        child: SizedBox(
                          width: 234,
                          child: KanbanTaskCard(task: task),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: KanbanTaskCard(task: task),
                      ),
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.all(24),
                              child: TaskDetailModal(
                                task: task,
                                projectMembers: _projectMembers,
                                onDataChanged: _loadBoard,
                              ),
                            ),
                          );
                        },
                        child: KanbanTaskCard(task: task),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton.icon(
                  onPressed: () => _showAddTaskModal(column),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Añadir', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildSidebar(),
        Expanded(child: _buildMainBoard()),
      ],
    );
  }
}
