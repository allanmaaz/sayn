import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/workspace/workspace_screen.dart';
import 'features/overlay/overlay_settings_screen.dart';
import 'features/keyboard/keyboard_settings_screen.dart';
import 'features/onboarding/onboarding_dialog.dart';
import 'services/auth_service.dart';
import 'services/update_service.dart';
import 'services/user_stats_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  UserStatsService.instance.init();
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
      themeMode: ThemeMode.light,
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
  String? _studioInitialText;
  String? _studioInitialStyle;

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onAuthChanged);
    AuthService.instance.init();
    UserStatsService.instance.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoUpdate();
      _checkOnboarding();
    });
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _checkOnboarding() async {
    final shouldShow = await OnboardingDialog.shouldShow();
    if (shouldShow && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const OnboardingDialog(),
      );
    }
  }

  Future<void> _checkAutoUpdate() async {
    if (kIsWeb) return;
    try {
      final info = await UpdateService.checkUpdate();
      if (info != null && info.hasUpdate && mounted) {
        UpdateService.showUpdateDialog(context, info);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onSwitchTab: (tabIndex) {
          setState(() => _currentIndex = tabIndex);
        },
        onSelectWritingTool: (toolMode) {
          setState(() {
            _studioInitialStyle = toolMode;
            _currentIndex = 1; // Switch to Studio
          });
        },
        onOpenNote: (note) {
          setState(() {
            _studioInitialText = note.resultText;
            _studioInitialStyle = note.mode;
            _currentIndex = 1; // Switch to Studio
          });
        },
      ),
      WorkspaceScreen(
        initialText: _studioInitialText,
        initialStyle: _studioInitialStyle,
      ),
      const OverlaySettingsScreen(),
      const KeyboardSettingsScreen(),
    ];

    return Scaffold(
      extendBody: false,
      backgroundColor: SaynColors.paperBg,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final navItems = [
      {'label': 'Voice', 'icon': Icons.graphic_eq_rounded},
      {'label': 'Studio', 'icon': Icons.edit_note_rounded},
      {'label': 'Overlay', 'icon': Icons.layers_outlined},
      {'label': 'Keys', 'icon': Icons.keyboard_rounded},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: SaynColors.paperBg,
        border: Border(
          top: BorderSide(color: Color(0xFFE8DFD1), width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = _currentIndex == index;
              final iconData = item['icon'] as IconData;
              final label = item['label'] as String;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = index);
                },
                child: isSelected
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                        decoration: BoxDecoration(
                          color: SaynColors.wineMaroon,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconData, size: 20, color: Colors.white),
                            const SizedBox(height: 2),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconData, size: 20, color: SaynColors.wineMaroon),
                            const SizedBox(height: 2),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: SaynColors.wineMaroon,
                              ),
                            ),
                          ],
                        ),
                      ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
