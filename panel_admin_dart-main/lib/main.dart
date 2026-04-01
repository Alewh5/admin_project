import 'package:flutter/material.dart';
import 'screens/Auth/login_screen.dart';
import 'services/api_client.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, unused) {
        return MaterialApp(
          title: 'Panel Admin',
          debugShowCheckedModeBanner: false,
          navigatorKey: ApiClient.navigatorKey,
          themeMode: currentMode,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(0.85)),
              child: child!,
            );
          },
          routes: {'/login': (_) => const LoginScreen()},
          theme: ThemeData(
            visualDensity: VisualDensity.compact,
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB),
              primary: const Color(0xFF2563EB),
              surface: const Color(0xFFF8FAFC),
              surfaceContainerHighest: const Color(0xFFF1F5F9),
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            dividerColor: const Color(0xFFE2E8F0),
            iconTheme: const IconThemeData(size: 20),
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                iconSize: 20,
                minimumSize: const Size(36, 36),
                padding: const EdgeInsets.all(8),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(64, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              color: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF0F172A),
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          darkTheme: ThemeData(
            visualDensity: VisualDensity.compact,
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: const Color(0xFF3B82F6),
              primary: const Color(0xFF3B82F6),
              surface: const Color(0xFF0F172A),
              surfaceContainerHighest: const Color(0xFF1E293B),
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            dividerColor: const Color(0xFF334155),
            iconTheme: const IconThemeData(size: 20, color: Colors.white),
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                iconSize: 20,
                minimumSize: const Size(36, 36),
                padding: const EdgeInsets.all(8),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(64, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF1E293B)),
              ),
              color: const Color(0xFF1E293B),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            tabBarTheme: const TabBarThemeData(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
            ),
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}
