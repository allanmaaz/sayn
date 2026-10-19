import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/workspace/workspace_screen.dart';
import 'features/overlay/overlay_settings_screen.dart';
import 'features/keyboard/keyboard_settings_screen.dart';
import 'features/onboarding/onboarding_dialog.dart';
import 'features/auth/login_screen.dart';
import 'services/auth_service.dart';
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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initScreens();
    AuthService.instance.addListener(_onAuthChanged);
    AuthService.instance.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoUpdate();
      if (AuthService.instance.isAuthenticated) {
        _checkOnboarding();
      }
    });
  }

  void _initScreens() {
    _screens = [
      HomeScreen(
        onSwitchTab: (tabIndex) {
          setState(() => _currentIndex = tabIndex);
        },
        onSelectWritingTool: (toolMode) {
          setState(() {
            _currentIndex = 1; // Switch to Studio
          });
        },
      ),
      const WorkspaceScreen(),
      const OverlaySettingsScreen(),
      const KeyboardSettingsScreen(),
    ];
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
      await OnboardingDialog.show(context);
    }
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
    if (!AuthService.instance.isAuthenticated) {
      return LoginScreen(
        onAuthenticated: () {
          setState(() {});
          _checkOnboarding();
        },
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: SaynColors.paperBg,
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
      {'label': 'Studio', 'icon': Icons.edit_note_rounded},
      {'label': 'Overlay', 'icon': Icons.layers_rounded},
      {'label': 'Keys', 'icon': Icons.keyboard_rounded},
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: SaynColors.wineMaroon.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xF6F5EBDD), // Warm Paper Surface
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: SaynColors.paperBorder,
                  width: 1.5,
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SaynColors.wineMaroon
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              iconData,
                              size: 19,
                              color: isSelected
                                  ? SaynColors.warmCream
                                  : SaynColors.paperTextMuted,
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
