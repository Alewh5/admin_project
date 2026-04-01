import 'package:flutter/material.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/custom_data_table.dart';
import '../../widgets/common/screen_header.dart';
import '../../widgets/common/action_buttons_cell.dart';
import '../../widgets/common/user_avatar_cell.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../services/user_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _userService = UserService();
  List<dynamic> _systemUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSystemUsers();
  }

  Future<void> _loadSystemUsers() async {
    setState(() => _isLoading = true);
    final users = await _userService.getUsers();
    if (mounted) {
      setState(() {
        _systemUsers = users;
        _isLoading = false;
      });
    }
  }

  void _deleteUser(int id) async {
    final success = await _userService.deleteUser(id);
    if (success) _loadSystemUsers();
  }

  void _toggleUserStatus(int id) async {
    final success = await _userService.toggleUserStatus(id);
    if (success) _loadSystemUsers();
  }

  void _showCreateUserDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    int selectedRole = 4;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Crear Nuevo Agente'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: firstNameController,
                    labelText: 'Nombre',
                    hintText: 'Juan',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: lastNameController,
                    labelText: 'Apellido',
                    hintText: 'Pérez',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: emailController,
                    labelText: 'Correo Electrónico',
                    hintText: 'juan@empresa.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: passwordController,
                    labelText: 'Contraseña',
                    hintText: 'Contraseña segura',
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Rol del Usuario',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('ROOT')),
                      DropdownMenuItem(value: 2, child: Text('OWNER')),
                      DropdownMenuItem(value: 3, child: Text('SUPERVISOR')),
                      DropdownMenuItem(value: 4, child: Text('AGENT')),
                    ],
                    onChanged: (value) {
                      if (value != null) selectedRole = value;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            CustomButton(
              text: 'Guardar',
              width: 120,
              height: 40,
              onPressed: () async {
                final navigator = Navigator.of(context);
                final success = await _userService.createUser({
                  'firstName': firstNameController.text,
                  'lastName': lastNameController.text,
                  'email': emailController.text,
                  'password': passwordController.text,
                  'roleId': selectedRole,
                });
                if (success && mounted) {
                  navigator.pop();
                  _loadSystemUsers();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditUserDialog(dynamic user) {
    final firstNameController = TextEditingController(text: user['firstName']);
    final lastNameController = TextEditingController(text: user['lastName']);
    final emailController = TextEditingController(text: user['email']);
    final passwordController = TextEditingController();
    int selectedRole = user['roleId'] ?? 4;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Editar Usuario'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: firstNameController,
                    labelText: 'Nombre',
                    hintText: 'Juan',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: lastNameController,
                    labelText: 'Apellido',
                    hintText: 'Pérez',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: emailController,
                    labelText: 'Correo Electrónico',
                    hintText: 'juan@empresa.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: passwordController,
                    labelText: 'Nueva Contraseña',
                    hintText: 'Dejar en blanco para no cambiar',
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Rol del Usuario',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('ROOT')),
                      DropdownMenuItem(value: 2, child: Text('OWNER')),
                      DropdownMenuItem(value: 3, child: Text('SUPERVISOR')),
                      DropdownMenuItem(value: 4, child: Text('AGENT')),
                    ],
                    onChanged: (value) {
                      if (value != null) selectedRole = value;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            CustomButton(
              text: 'Guardar Cambios',
              width: 170,
              height: 40,
              onPressed: () async {
                final navigator = Navigator.of(context);
                final updateData = {
                  'firstName': firstNameController.text,
                  'lastName': lastNameController.text,
                  'email': emailController.text,
                  'roleId': selectedRole,
                };
                if (passwordController.text.isNotEmpty) {
                  updateData['password'] = passwordController.text;
                }
                final success = await _userService.updateUser(
                  user['id'],
                  updateData,
                );
                if (success && mounted) {
                  navigator.pop();
                  _loadSystemUsers();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Gestión de Usuarios',
          actionWidget: CustomButton(
            onPressed: _showCreateUserDialog,
            text: 'Crear Agente',
            icon: Icons.add,
          ),
        ),
        Expanded(child: _buildUserTable(context)),
      ],
    );
  }

  Widget _buildUserTable(BuildContext context) {
    return CustomDataTable(
      isLoading: _isLoading,
      isEmpty: _systemUsers.isEmpty,
      emptyTitle: 'No hay usuarios',
      emptySubtitle: 'No se han registrado agentes aún.',
      emptyIcon: Icons.people_alt_outlined,
      columns: const [
        DataColumn(label: Text('Usuario')),
        DataColumn(label: Text('Correo')),
        DataColumn(label: Text('Rol')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Acciones')),
      ],
      rows: _systemUsers.map((user) {
        final role = user['role'] != null
            ? user['role']['name']
            : 'Desconocido';
        final isActive = user['isActive'] ?? false;

        return DataRow(
          cells: [
            DataCell(
              UserAvatarCell(
                name: '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                    .trim(),
              ),
            ),
            DataCell(Text(user['email'] ?? '')),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            DataCell(
              StatusBadge(
                text: isActive ? 'Activo' : 'Inactivo',
                isPositive: isActive,
                icon: Icons.circle,
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionButtonsCell(
                    showView: false,
                    showEdit: true,
                    showDelete: true,
                    onEdit: () => _showEditUserDialog(user),
                    onDelete: () => _deleteUser(user['id']),
                    editTooltip: 'Editar Agente',
                    deleteTooltip: 'Eliminar Agente',
                  ),
                  IconButton(
                    icon: Icon(
                      isActive
                          ? Icons.person_off_outlined
                          : Icons.person_outline,
                      color: isActive ? Colors.orange : Colors.green,
                    ),
                    onPressed: () => _toggleUserStatus(user['id']),
                    tooltip: isActive ? 'Desactivar' : 'Activar',
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
