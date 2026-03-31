import 'package:flutter/material.dart';
import '../../main.dart';

class RightMenu extends StatelessWidget {
  final String agentName;
  final String agentRole;
  final VoidCallback onLogout;

  const RightMenu({
    super.key,
    required this.agentName,
    required this.agentRole,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 24.0),
      children: [
        Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Mi Perfil',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '$agentName - $agentRole',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 32),
        ListTile(
          leading: const Icon(Icons.settings_rounded),
          title: const Text(
            'Ajustes',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () {},
        ),
        const SizedBox(height: 4),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (_, ThemeMode currentMode, unused) {
            final isDark =
                currentMode == ThemeMode.dark ||
                (currentMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness ==
                        Brightness.dark);

            return ListTile(
              leading: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              ),
              title: const Text(
                'Cambiar Tema',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
              },
            );
          },
        ),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: onLogout,
        ),
      ],
    );
  }
}
