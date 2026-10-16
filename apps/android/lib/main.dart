import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'features/voice/voice_flow_screen.dart';
import 'features/workspace/workspace_screen.dart';
import 'features/overlay/overlay_settings_screen.dart';
import 'features/keyboard/keyboard_settings_screen.dart';
import 'services/update_service.dart';

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
    VoiceFlowScreen(),
    WorkspaceScreen(),
    OverlaySettingsScreen(),
    KeyboardSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoUpdate();
    });
  }

  Future<void> _checkAutoUpdate() async {
    try {
      final info = await UpdateService.checkUpdate();
      if (info != null && info.hasUpdate && mounted) {
        UpdateService.showUpdateDialog(context, info);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: SaynColors.darkBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildFloatingBottomNav(),
    );
  }

  Widget _buildFloatingBottomNav() {
    final navItems = [
      {'label': 'Flow', 'icon': Icons.graphic_eq_rounded},
      {'label': 'Workspace', 'icon': Icons.edit_note_rounded},
      {'label': 'Overlay', 'icon': Icons.layers_rounded},
      {'label': 'Keyboard', 'icon': Icons.keyboard_rounded},
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: SaynColors.darkAccent.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xEE180B0F),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: SaynColors.darkDivider,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  final isSelected = _currentIndex == index;
                  final iconData = item['icon'] as IconData;
                  final label = item['label'] as String;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _currentIndex = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SaynColors.darkAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              iconData,
                              size: 20,
                              color: isSelected
                                  ? SaynColors.warmCream
                                  : SaynColors.darkSecondary,
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                    color: SaynColors.warmCream,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
