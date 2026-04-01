import 'package:flutter/material.dart';
import '../../models/proyecto_model.dart';
import '../../widgets/common/screen_header.dart';
import 'tabs/kanban_board_tab.dart';
import 'tabs/documentos_tab.dart';
import 'tabs/conversaciones_tab.dart';
import 'tabs/rendimiento_tab.dart';
import 'tabs/equipo_tab.dart';

class ProyectoTabsScreen extends StatelessWidget {
  final Proyecto proyecto;
  final String agentName;
  final int? agentId;

  const ProyectoTabsScreen({
    super.key,
    required this.proyecto,
    required this.agentName,
    this.agentId,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text('Proyecto: ${proyecto.nombre}'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.view_kanban), text: 'Tablero'),
              Tab(icon: Icon(Icons.folder), text: 'Documentos'),
              Tab(icon: Icon(Icons.chat), text: 'Conversaciones'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Rendimiento'),
              Tab(icon: Icon(Icons.groups), text: 'Equipo'),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            KanbanBoardTab(proyecto: proyecto, agentId: agentId),
            DocumentosTab(proyecto: proyecto),
            ConversacionesTab(proyecto: proyecto, agentName: agentName, agentId: agentId),
            RendimientoTab(proyecto: proyecto),
            EquipoTab(proyecto: proyecto),
          ],
        ),
      ),
      ),
    );
  }
}
