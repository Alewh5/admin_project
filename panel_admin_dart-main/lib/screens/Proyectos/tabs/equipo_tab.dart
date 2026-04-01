import 'package:flutter/material.dart';
import '../../../models/proyecto_model.dart';
import '../../../services/proyectos_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/common/form_dialog_layout.dart';

class EquipoTab extends StatefulWidget {
  final Proyecto proyecto;
  const EquipoTab({super.key, required this.proyecto});

  @override
  State<EquipoTab> createState() => _EquipoTabState();
}

class _EquipoTabState extends State<EquipoTab> {
  final ProyectosService _proyectosService = ProyectosService();
  final UserService _userService = UserService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _teamMembers = [];
  List<dynamic> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final team = await _proyectosService.getProjectTeam(widget.proyecto.id);
      final users = await _userService.getInvitableUsers();
      setState(() {
        _teamMembers = team;
        _allUsers = users;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando equipo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddMemberModal() {
    final teamUserIds = _teamMembers.map((m) => m['id']).toSet();
    final availableUsers = _allUsers
        .where((u) => !teamUserIds.contains(u['id']))
        .toList();

    final roles = availableUsers
        .map((u) => u['role']?['name'] as String? ?? 'Sin Rol')
        .toSet()
        .toList();

    if (roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay usuarios disponibles para agregar.'),
        ),
      );
      return;
    }

    String? selectedRole = roles.first;
    int? selectedUserId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final usersForRole = availableUsers
                .where((u) => (u['role']?['name'] ?? 'Sin Rol') == selectedRole)
                .toList();

            if (selectedUserId == null ||
                !usersForRole.any((u) => u['id'] == selectedUserId)) {
              selectedUserId = usersForRole.isNotEmpty
                  ? usersForRole.first['id']
                  : null;
            }

            return FormDialogLayout(
              title: 'Invitar al Equipo',
              errorMessage: 'Error al agregar miembro.',
              onSave: () async {
                if (selectedUserId == null) return false;

                return await _proyectosService.addTeamMember(
                  widget.proyecto.id,
                  selectedUserId!,
                  selectedRole ?? 'Colaborador',
                );
              },
              onSuccess: () {
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Miembro agregado exitosamente.'),
                  ),
                );
              },
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedRole,
                    items: roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedRole = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedUserId,
                    items: usersForRole
                        .map(
                          (u) => DropdownMenuItem<int>(
                            value: u['id'],
                            child: Text('${u['firstName']} ${u['lastName']}'),
                          ),
                        )
                        .toList(),
                    onChanged: usersForRole.isEmpty
                        ? null
                        : (val) {
                            setModalState(() {
                              selectedUserId = val;
                            });
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

  void _removeMember(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover del equipo'),
        content: const Text(
          '¿Estás seguro de remover a este usuario del proyecto? Perderá acceso a los Sprints y Tareas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await _proyectosService.removeTeamMember(
      widget.proyecto.id,
      userId,
    );
    if (success) {
      _loadData();
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al remover miembro.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Equipo Asignado',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddMemberModal,
                icon: const Icon(Icons.person_add),
                label: const Text('Agregar Miembro'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_teamMembers.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off, size: 64, color: theme.dividerColor),
                    const SizedBox(height: 16),
                    Text(
                      'No hay miembros en este proyecto.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _teamMembers.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final member = _teamMembers[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.1,
                      ),
                      child: Text(
                        member['firstName']
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '${member['firstName']} ${member['lastName']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${member['role']} • ${member['email']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove, color: Colors.red),
                      onPressed: () => _removeMember(member['id']),
                      tooltip: 'Remover miembro',
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
