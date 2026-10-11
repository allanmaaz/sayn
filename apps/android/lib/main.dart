import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/workspace/workspace_screen.dart';
import 'features/overlay/overlay_settings_screen.dart';
import 'features/keyboard/keyboard_settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SaynApp());
}

class SaynApp extends StatelessWidget {
  const SaynApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAYN',
      debugShowCheckedModeBanner: false,
      theme: SaynTheme.lightTheme,
      darkTheme: SaynTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    WorkspaceScreen(),
    OverlaySettingsScreen(),
    KeyboardSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: SaynColors.darkSurface,
        indicatorColor: SaynColors.darkAccent.withOpacity(0.2),
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit, color: SaynColors.darkAccent),
            label: 'Workspace',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers, color: SaynColors.darkAccent),
            label: 'Overlay',
          ),
          NavigationDestination(
            icon: Icon(Icons.keyboard_outlined),
            selectedIcon: Icon(Icons.keyboard, color: SaynColors.darkAccent),
            label: 'Keyboard',
          ),
        ],
      ),
    );
  }
}
