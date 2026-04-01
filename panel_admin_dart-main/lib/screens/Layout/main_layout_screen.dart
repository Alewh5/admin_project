import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../Auth/login_screen.dart';
import '../Chat/chat_screen.dart';
import '../Tickets/tickets_screen.dart';
import '../Users/users_screen.dart';
import '../History/history_screen.dart';
import '../Proyectos/proyectos_screen.dart';
import '../Dashboard/dashboard_home_screen.dart';
import '../../widgets/left_menu.dart';
import '../../widgets/right_menu.dart';
import '../../models/chat_model.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _agentName = 'Agente';
  int? _agentId;
  String _agentRole = '';
  int _selectedIndex = 0;
  List<ChatRoom> _activeRooms = [];
  List<dynamic> _systemUsers = [];

  @override
  void initState() {
    super.initState();
    _initializeLayout();
  }

  Future<void> _initializeLayout() async {
    final name = await _storage.read(key: 'firstName');
    final role = await _storage.read(key: 'role');
    final idString = await _storage.read(key: 'userId');
    if (mounted) {
      setState(() {
        _agentName = name ?? 'Agente';
        _agentRole = role ?? '';
        if (idString != null) _agentId = int.tryParse(idString);
      });
    }

    await _chatService.connectSocket(
      onUserJoined: (data) {
        _loadActiveRooms();
      },
      onRoomClosed: (data) {
        _onRoomClosed(data);
      },
      onRoomListUpdated: () {
        _loadActiveRooms();
      },
      onGlobalMessage: (message) {
        _onGlobalMessage(message);
      },
      onRoomAssignedNotification: (data) {
        _onRoomAssignedNotification(data);
        _loadActiveRooms();
      },
    );

    _loadActiveRooms();
    _loadSystemUsers();
  }

  Future<void> _loadActiveRooms() async {
    final rooms = await _chatService.getActiveRooms();
    if (mounted) {
      setState(() {
        _activeRooms = rooms;
      });
    }
  }

  Future<void> _loadSystemUsers() async {
    final users = await _userService.getUsers();
    if (mounted) {
      setState(() {
        _systemUsers = users;
      });
    }
  }

  void _onGlobalMessage(ChatMessage message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mensaje de ${message.roomId}: ${message.message.isNotEmpty ? message.message : 'Archivo recibido'}',
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onRoomAssignedNotification(dynamic data) {
    if (mounted) {
      bool isAssignedToMe = data['agentName'] == _agentName;
      bool isProyecto = data['isProyecto'] == true;

      if (isAssignedToMe) {
        _chatService.playNewChatSound();
      }

      String message;
      if (isProyecto) {
        message = isAssignedToMe
            ? '¡Atención! ${data['assignedBy']} te ha asignado el proyecto: ${data['proyectoNombre']}.'
            : '${data['assignedBy']} ha asignado el proyecto ${data['proyectoNombre']} a ${data['agentName']}';
      } else {
        message = isAssignedToMe
            ? '¡Atención! ${data['assignedBy']} te ha asignado un nuevo chat.'
            : '${data['assignedBy']} ha asignado un chat a ${data['agentName']}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isAssignedToMe ? Colors.green[700] : Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: isAssignedToMe ? 5 : 3),
        ),
      );
    }
  }

  void _onRoomClosed(dynamic data) {
    _loadActiveRooms();
  }

  void _logout() async {
    _chatService.disconnect();
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Widget _buildWorkspace() {
    switch (_selectedIndex) {
      case 1:
        return ChatScreen(
          activeRooms: _activeRooms,
          agentName: _agentName,
          agentRole: _agentRole,
        );
      case 2:
        return HistoryScreen(agentName: _agentName, agentRole: _agentRole);
      case 3:
        return TicketsScreen(agentRole: _agentRole, agentName: _agentName);
      case 4:
        return const UsersScreen();
      case 6:
        return ProyectosScreen(
          agentRole: _agentRole,
          agentName: _agentName,
          agentId: _agentId,
          systemUsers: _systemUsers,
        );
      case 7:
        return ProyectosScreen(
          agentRole: _agentRole,
          agentName: _agentName,
          agentId: _agentId,
          systemUsers: _systemUsers,
          onlyMyProjects: true,
        );
      case 0:
      default:
        return DashboardHomeScreen(
          agentName: _agentName,
          agentRole: _agentRole,
          activeRooms: _activeRooms,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text('Panel de Administración'),
                  actions: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                      ),
                    ),
                  ],
                ),
          drawer: isDesktop
              ? null
              : Drawer(
                  child: LeftMenu(
                    selectedIndex: _selectedIndex,
                    agentRole: _agentRole,
                    unassignedCount: _activeRooms
                        .where((r) => r.agentId == null)
                        .length,
                    onItemSelected: (index) {
                      setState(() => _selectedIndex = index);
                      if (index == 1) _loadActiveRooms();
                      Navigator.pop(context);
                    },
                  ),
                ),
          endDrawer: Drawer(
            child: RightMenu(
              agentName: _agentName,
              agentRole: _agentRole,
              onLogout: _logout,
            ),
          ),
          body: Row(
            children: [
              if (isDesktop)
                LeftMenu(
                  selectedIndex: _selectedIndex,
                  agentRole: _agentRole,
                  unassignedCount: _activeRooms
                      .where((r) => r.agentId == null)
                      .length,
                  onItemSelected: (index) {
                    setState(() => _selectedIndex = index);
                    if (index == 1) _loadActiveRooms();
                  },
                ),
              if (isDesktop) const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop)
                      Container(
                        height: 60,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Text(
                              _selectedIndex == 0
                                  ? 'Inicio'
                                  : _selectedIndex == 1
                                  ? 'Chats Activos'
                                  : _selectedIndex == 2
                                  ? 'Historial'
                                  : _selectedIndex == 3
                                  ? 'Gestión de Tickets'
                                  : _selectedIndex == 4
                                  ? 'Usuarios'
                                  : _selectedIndex == 6
                                  ? 'Proyectos'
                                  : _selectedIndex == 7
                                  ? 'Mis proyectos'
                                  : 'Utilidades',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Conectado como: $_agentName',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Builder(
                              builder: (context) => IconButton(
                                icon: const Icon(
                                  Icons.account_circle,
                                  size: 30,
                                ),
                                color: Theme.of(context).colorScheme.primary,
                                onPressed: () =>
                                    Scaffold.of(context).openEndDrawer(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isDesktop) const Divider(height: 1, thickness: 1),
                    Expanded(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: _buildWorkspace(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _chatService.disconnect();
    super.dispose();
  }
}
