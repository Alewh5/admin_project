import 'package:flutter/material.dart';
import '../config/app_roles.dart';

class LeftMenu extends StatefulWidget {
  final int selectedIndex;
  final String agentRole;
  final int unassignedCount;
  final Function(int) onItemSelected;

  const LeftMenu({
    super.key,
    required this.selectedIndex,
    required this.agentRole,
    required this.unassignedCount,
    required this.onItemSelected,
  });

  @override
  State<LeftMenu> createState() => _LeftMenuState();
}

class _LeftMenuState extends State<LeftMenu> {
  bool _isCollapsed = false;
  bool _isChatMenuExpanded = false;
  bool _isUtilidadesMenuExpanded = false;

  void _toggleSidebar() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      if (_isCollapsed) {
        _isChatMenuExpanded = false; // Collapse submenus when sidebar collapses
        _isUtilidadesMenuExpanded = false;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Expand menus if active
    if (widget.selectedIndex == 1 || widget.selectedIndex == 2) {
      _isChatMenuExpanded = true;
    }
    if (widget.selectedIndex == 6) {
      _isUtilidadesMenuExpanded = true;
    }
  }

  @override
  void didUpdateWidget(covariant LeftMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex == 1 || widget.selectedIndex == 2) {
      if (!_isCollapsed) {
         _isChatMenuExpanded = true;
      }
    }
    if (widget.selectedIndex == 6 || widget.selectedIndex == 7) {
      if (!_isCollapsed) {
         _isUtilidadesMenuExpanded = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRootOrOwner = AppRoles.isRootOrOwner(widget.agentRole);
    final bool isSupervisorOrHigher = AppRoles.isSupervisorOrHigher(widget.agentRole);
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isCollapsed ? 80 : 250,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          right: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header / Avatar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: theme.colorScheme.primary,
                size: _isCollapsed ? 24 : 36,
              ),
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: 'Inicio',
                  index: 0,
                ),
                _buildChatExpandableItem(),
                _buildNavItem(
                  icon: Icons.confirmation_number_outlined,
                  selectedIcon: Icons.confirmation_number_rounded,
                  label: 'Tickets',
                  index: 3,
                ),
                if (isRootOrOwner)
                  _buildNavItem(
                    icon: Icons.people_alt_outlined,
                    selectedIcon: Icons.people_alt_rounded,
                    label: 'Usuarios',
                    index: 4,
                  ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildUtilidadesExpandableItem(isSupervisorOrHigher),
              ],
            ),
          ),
          // Collapse Toggle Button
          InkWell(
            onTap: _toggleSidebar,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Icon(
                    _isCollapsed ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  if (!_isCollapsed) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Ocultar Menú',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    int indent = 0,
  }) {
    final bool isSelected = widget.selectedIndex == index;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => widget.onItemSelected(index),
      child: Container(
        padding: EdgeInsets.only(
          left: _isCollapsed ? 0 : 16.0 + indent,
          right: _isCollapsed ? 0 : 16.0,
          top: 12.0,
          bottom: 12.0,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? theme.colorScheme.primary : Colors.grey,
              size: 24,
            ),
            if (!_isCollapsed) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? theme.colorScheme.primary : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildChatExpandableItem() {
    final theme = Theme.of(context);
    final isChildSelected = widget.selectedIndex == 1 || widget.selectedIndex == 2;
    
    if (_isCollapsed) {
       // When collapsed, just show a single icon that acts as a dropdown trigger or navigates directly
       return InkWell(
         onTap: () {
           _toggleSidebar();
           setState(() {
             _isChatMenuExpanded = true;
           });
         },
         child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isChildSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isChildSelected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
              color: isChildSelected ? theme.colorScheme.primary : Colors.grey,
              size: 24,
            ),
         ),
       );
    }

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _isChatMenuExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isChatMenuExpanded = expanded;
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 24),
        leading: Icon(
          isChildSelected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
          color: isChildSelected ? theme.colorScheme.primary : Colors.grey,
        ),
        title: Text(
          'Chats',
          style: TextStyle(
            color: isChildSelected ? theme.colorScheme.primary : Colors.grey[700],
            fontWeight: isChildSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: Icon(
           _isChatMenuExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
           color: isChildSelected ? theme.colorScheme.primary : Colors.grey,
        ),
        children: [
          _buildNavItem(
            icon: widget.unassignedCount > 0 ? Icons.mark_chat_unread_outlined : Icons.forum_outlined,
            selectedIcon: widget.unassignedCount > 0 ? Icons.mark_chat_unread_rounded : Icons.forum_rounded,
            label: widget.unassignedCount > 0 ? 'Activos (${widget.unassignedCount})' : 'Activos',
            index: 1,
            indent: 16,
          ),
          _buildNavItem(
            icon: Icons.history_outlined,
            selectedIcon: Icons.history_rounded,
            label: 'Historial',
            index: 2,
            indent: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildUtilidadesExpandableItem(bool isSupervisorOrHigher) {
    final theme = Theme.of(context);
    final isChildSelected = widget.selectedIndex == 6 || widget.selectedIndex == 7;
    
    if (_isCollapsed) {
       return InkWell(
         onTap: () {
           _toggleSidebar();
           setState(() {
             _isUtilidadesMenuExpanded = true;
           });
         },
         child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isChildSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isChildSelected ? Icons.build_circle_rounded : Icons.build_circle_outlined,
              color: isChildSelected ? theme.colorScheme.primary : Colors.grey,
              size: 24,
            ),
         ),
       );
    }

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _isUtilidadesMenuExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isUtilidadesMenuExpanded = expanded;
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 24),
        leading: Icon(
          isChildSelected ? Icons.build_circle_rounded : Icons.build_circle_outlined,
          color: isChildSelected ? theme.colorScheme.primary : Colors.grey,
        ),
        title: Text(
          'Utilidades',
          style: TextStyle(
            color: isChildSelected ? theme.colorScheme.primary : Colors.grey[700],
            fontWeight: isChildSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: Icon(
           _isUtilidadesMenuExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
           color: isChildSelected ? theme.colorScheme.primary : Colors.grey,
        ),
        children: [
          if (isSupervisorOrHigher)
            _buildNavItem(
              icon: Icons.assignment_outlined,
              selectedIcon: Icons.assignment_rounded,
              label: 'Proyectos',
              index: 6,
              indent: 16,
            ),
          _buildNavItem(
            icon: Icons.folder_shared_outlined,
            selectedIcon: Icons.folder_shared_rounded,
            label: 'Mis proyectos',
            index: 7,
            indent: 16,
          ),
        ],
      ),
    );
  }
}
