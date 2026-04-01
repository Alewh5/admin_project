import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_data_table.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/screen_header.dart';
import '../../widgets/common/custom_dialog_scaffold.dart';
import '../../widgets/common/action_buttons_cell.dart';
import '../../services/proyectos_service.dart';
import '../../models/proyecto_model.dart';
import 'proyecto_tabs_screen.dart';

class ProyectosScreen extends StatefulWidget {
  final String agentRole;
  final String agentName;
  final int? agentId;
  final List<dynamic>? systemUsers;
  final bool onlyMyProjects;

  const ProyectosScreen({
    super.key,
    required this.agentRole,
    required this.agentName,
    this.agentId,
    this.systemUsers,
    this.onlyMyProjects = false,
  });

  @override
  State<ProyectosScreen> createState() => _ProyectosScreenState();
}

class _ProyectosScreenState extends State<ProyectosScreen> {
  final ProyectosService _proyectosService = ProyectosService();
  List<Proyecto> _proyectos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProyectos();
  }

  Future<void> _loadProyectos() async {
    setState(() => _isLoading = true);
    try {
      final proyectos = await _proyectosService.getProyectos();
      if (mounted) {
        setState(() {
          _proyectos = proyectos;
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError('Error de conexión o al cargar proyectos');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _deleteProyecto(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este proyecto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _proyectosService.deleteProyecto(id);
      if (success) {
        _showSuccess('Proyecto eliminado');
        _loadProyectos();
      } else {
        _showError('Error al eliminar');
      }
    } catch (e) {
      _showError('Error de red');
    }
  }

  void _showProyectoDialog([Proyecto? proyecto]) {
    final isEditing = proyecto != null;
    final nombreController = TextEditingController(text: proyecto?.nombre);
    final descController = TextEditingController(
      text: proyecto?.descripcion,
    );

    final availableEncargados = widget.systemUsers ?? [];
    int? selectedEncargado = proyecto?.encargadoProyecto;

    if (selectedEncargado != null) {
      bool exists = availableEncargados.any(
        (u) => u['id'] == selectedEncargado,
      );
      if (!exists && proyecto?.encargadoProyecto != null) {
        selectedEncargado = null;
      }
    }

    String selectedEstado = proyecto?.estado ?? 'Inactivo';
    DateTime? initDate = proyecto?.estimacionInicio;
    DateTime? endDate = proyecto?.estimacionFin;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return CustomDialogScaffold(
              title: isEditing ? 'Editar Proyecto' : 'Crear Proyecto',
              width: 500,
              submitText: 'Guardar',
              onSubmit: () async {
                if (nombreController.text.trim().isEmpty) {
                  _showError('El nombre es obligatorio');
                  return;
                }

                final navigator = Navigator.of(context);
                final payload = {
                  'nombre': nombreController.text.trim(),
                  'descripcion': descController.text.trim(),
                  'encargadoProyecto': selectedEncargado,
                  'estado': selectedEstado,
                  'estimacionInicio': initDate?.toIso8601String(),
                  'estimacionFin': endDate?.toIso8601String(),
                  'assignedBy': widget.agentName,
                };

                try {
                  bool success;
                  if (isEditing) {
                    success = await _proyectosService.updateProyecto(
                      proyecto.id,
                      payload,
                    );
                  } else {
                    success = await _proyectosService.createProyecto(payload);
                  }

                  if (success) {
                    _showSuccess(
                      isEditing ? 'Proyecto actualizado' : 'Proyecto creado',
                    );
                    if (mounted) navigator.pop();
                    _loadProyectos();
                  } else {
                    _showError('Error al guardar el proyecto');
                  }
                } catch (e) {
                  _showError('Error de red');
                }
              },
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: nombreController,
                    labelText: 'Nombre del Proyecto *',
                    hintText: 'Ej. Rediseño Web',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: descController,
                    labelText: 'Descripción',
                    hintText: 'Detalles del proyecto...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedEncargado,
                    decoration: InputDecoration(
                      labelText: 'Encargado del Proyecto',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sin Asignar'),
                      ),
                      ...availableEncargados.map((u) {
                        return DropdownMenuItem<int?>(
                          value: u['id'],
                          child: Text('${u['firstName']} ${u['lastName']}'),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setStateDialog(() => selectedEncargado = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text(
                            'Fecha Inicio',
                            style: TextStyle(fontSize: 12),
                          ),
                          subtitle: Text(
                            initDate != null
                                ? DateFormat('yyyy-MM-dd').format(initDate!)
                                : 'Seleccionar',
                          ),
                          trailing: const Icon(Icons.calendar_today, size: 16),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: initDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setStateDialog(() => initDate = date);
                            }
                          },
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ListTile(
                          title: const Text(
                            'Fecha Fin',
                            style: TextStyle(fontSize: 12),
                          ),
                          subtitle: Text(
                            endDate != null
                                ? DateFormat('yyyy-MM-dd').format(endDate!)
                                : 'Seleccionar',
                          ),
                          trailing: const Icon(Icons.calendar_today, size: 16),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  endDate ?? initDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setStateDialog(() => endDate = date);
                            }
                          },
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedEstado,
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                      DropdownMenuItem(
                        value: 'En Desarrollo',
                        child: Text('En Desarrollo'),
                      ),
                      DropdownMenuItem(
                        value: 'Finalizado',
                        child: Text('Finalizado'),
                      ),
                      DropdownMenuItem(
                        value: 'Bloqueo',
                        child: Text('Bloqueo'),
                      ),
                      DropdownMenuItem(
                        value: 'Dado de Baja',
                        child: Text('Dado de Baja'),
                      ),
                      DropdownMenuItem(
                        value: 'Inactivo',
                        child: Text('Inactivo'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null)
                        setStateDialog(() => selectedEstado = val);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDetallesPanel(Proyecto proyecto) {
    String assignedName = 'N/A';
    final int? encargadoId = proyecto.encargadoProyecto;
    if (encargadoId != null && widget.systemUsers != null) {
      final userOpt = widget.systemUsers!.firstWhere(
        (u) => u['id'] == encargadoId,
        orElse: () => null,
      );
      if (userOpt != null) {
        assignedName = '${userOpt['firstName']} ${userOpt['lastName']}';
      }
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            child: Container(
              width: 400,
              height: double.infinity,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.05),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            proyecto.nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalles del Proyecto',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Descripción:',
                            proyecto.descripcion ?? 'N/A',
                          ),
                          const Divider(),
                          _buildDetailRow('Estado:', proyecto.estado),
                          _buildDetailRow('Encargado:', assignedName),
                          const Divider(),
                          _buildDetailRow(
                            'Inicio Estimado:',
                            proyecto.estimacionInicio != null
                                ? DateFormat('dd/MM/yyyy').format(
                                    proyecto.estimacionInicio!,
                                  )
                                : 'N/A',
                          ),
                          _buildDetailRow(
                            'Fin Estimado:',
                            proyecto.estimacionFin != null
                                ? DateFormat('dd/MM/yyyy').format(
                                    proyecto.estimacionFin!,
                                  )
                                : 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedProyectos = widget.onlyMyProjects
        ? _proyectos.where((p) {
            final encargadoId = p.encargadoProyecto;
            return encargadoId == widget.agentId && widget.agentId != null;
          }).toList()
        : _proyectos;

    return Column(
      children: [
        ScreenHeader(
          title: widget.onlyMyProjects
              ? 'Mis Proyectos'
              : 'Gestión de Proyectos',
          actionWidget: !widget.onlyMyProjects
              ? CustomButton(
                  onPressed: () => _showProyectoDialog(),
                  text: 'Crear Proyecto',
                  icon: Icons.add,
                )
              : null,
        ),
        Expanded(child: _buildProyectosTable(context, displayedProyectos)),
      ],
    );
  }

  Widget _buildProyectosTable(BuildContext context, List<Proyecto> data) {
    return CustomDataTable(
      isLoading: _isLoading,
      isEmpty: data.isEmpty,
      emptyTitle: 'No hay proyectos',
      emptySubtitle: 'No se encontraron registros de proyectos.',
      emptyIcon: Icons.assignment_outlined,
      columns: const [
        DataColumn(label: Text('Nombre')),
        DataColumn(label: Text('Encargado')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Estimación Fin')),
        DataColumn(label: Text('Acciones')),
      ],
      rows: data.map((proyecto) {
        final isPositive =
            proyecto.estado == 'Activo' ||
            proyecto.estado == 'En Desarrollo' ||
            proyecto.estado == 'Finalizado';

        String assignedName = 'N/A';
        final int? encargadoId = proyecto.encargadoProyecto;
        if (encargadoId != null && widget.systemUsers != null) {
          final userOpt = widget.systemUsers!.firstWhere(
            (u) => u['id'] == encargadoId,
            orElse: () => null,
          );
          if (userOpt != null) {
            assignedName = '${userOpt['firstName']} ${userOpt['lastName']}';
          }
        }

        return DataRow(
          cells: [
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    proyecto.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    proyecto.descripcion ?? 'Sin descripción',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            DataCell(Text(assignedName)),
            DataCell(
              StatusBadge(
                text: proyecto.estado,
                isPositive: isPositive,
                icon: Icons.circle,
              ),
            ),
            DataCell(
              Text(
                proyecto.estimacionFin != null
                    ? DateFormat(
                        'dd/MM/yyyy',
                      ).format(proyecto.estimacionFin!)
                    : 'N/A',
              ),
            ),
            DataCell(
              ActionButtonsCell(
                showView: true,
                showEdit: !widget.onlyMyProjects,
                showDelete: !widget.onlyMyProjects,
                onView: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => ProyectoTabsScreen(
                        proyecto: proyecto,
                        agentName: widget.agentName,
                        agentId: widget.agentId,
                      ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  );
                },
                onEdit: () => _showProyectoDialog(proyecto),
                onDelete: () => _deleteProyecto(proyecto.id),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
