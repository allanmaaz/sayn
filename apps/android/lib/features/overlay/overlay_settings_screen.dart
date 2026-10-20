import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/platform_channels.dart';
import '../onboarding/onboarding_dialog.dart';
import '../navigation/sayn_drawer.dart';

class OverlaySettingsScreen extends StatefulWidget {
  const OverlaySettingsScreen({super.key});

  @override
  State<OverlaySettingsScreen> createState() => _OverlaySettingsScreenState();
}

class _OverlaySettingsScreenState extends State<OverlaySettingsScreen> {
  bool _hasPermission = false;
  bool _hasAccessibilityPermission = false;
  bool _isRunning = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    final hasPerm = await PlatformChannels.checkOverlayPermission();
    final hasAccess = await PlatformChannels.checkAccessibilityPermission();
    final running = await PlatformChannels.isOverlayRunning();
    if (mounted) {
      setState(() {
        _hasPermission = hasPerm;
        _hasAccessibilityPermission = hasAccess;
        _isRunning = running;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    await PlatformChannels.requestOverlayPermission();
    await Future.delayed(const Duration(milliseconds: 500));
    _checkStatus();
  }

  Future<void> _toggleAssistant(bool enable) async {
    if (enable) {
      if (!_hasPermission) {
        await _requestPermission();
        return;
      }
      final started = await PlatformChannels.startFloatingAssistant();
      setState(() => _isRunning = started);
    } else {
      final stopped = await PlatformChannels.stopFloatingAssistant();
      setState(() => _isRunning = !stopped);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaynColors.paperBg,
      drawer: const SaynDrawer(),
      appBar: AppBar(
        backgroundColor: SaynColors.paperBg,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: SaynColors.wineMaroon, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text(
          'Floating Assistant',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: SaynColors.wineMaroon,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: SaynColors.wineMaroon),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── 1. SHOW MIC OVER OTHER APPS ───
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SaynColors.paperCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.015),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBF1EC),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.filter_none_rounded,
                                color: SaynColors.wineMaroon,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Show mic over other apps',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: SaynColors.paperText,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Use your mic while chatting in any app.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: SaynColors.paperTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _requestPermission,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SaynColors.wineMaroon,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(
                              _hasPermission
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.open_in_new_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _hasPermission
                                  ? 'Permission allowed'
                                  : 'Allow permission',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 2. VOICE WHILE TYPING ───
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SaynColors.paperCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.015),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBF1EC),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.mic_none_rounded,
                                color: SaynColors.wineMaroon,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Voice while typing',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: SaynColors.paperText,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Show the voice button when your keyboard opens.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: SaynColors.paperTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (!_hasAccessibilityPermission) {
                                await PlatformChannels.openAccessibilitySettings();
                                await Future.delayed(const Duration(milliseconds: 600));
                                _checkStatus();
                              } else {
                                _toggleAssistant(!_isRunning);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SaynColors.wineMaroon,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.mic_rounded, size: 18),
                            label: Text(
                              _hasAccessibilityPermission ? 'Active' : 'Turn on',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showRestrictedSettingsDialog(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Button unavailable? See how to fix it',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: SaynColors.wineMaroon,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: SaynColors.wineMaroon,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 3. FLOATING MIC ───
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: SaynColors.paperCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.015),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF1EC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.mic_none_rounded,
                            color: SaynColors.wineMaroon,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Floating mic',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: SaynColors.paperText,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Keep a small mic on your screen.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: SaynColors.paperTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _isRunning,
                          activeColor: SaynColors.wineMaroon,
                          activeTrackColor: SaynColors.wineMaroon.withOpacity(0.35),
                          inactiveTrackColor: const Color(0xFFE5DDD0),
                          inactiveThumbColor: const Color(0xFF8C827A),
                          onChanged: _hasPermission ? _toggleAssistant : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 4. NEED HELP? ───
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SaynColors.paperCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.015),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF1EC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.help_outline_rounded,
                            color: SaynColors.wineMaroon,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Need help?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: SaynColors.paperText,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Get a simple step-by-step guide.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: SaynColors.paperTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => OnboardingDialog.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EBDD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: SaynColors.paperBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Show me how',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: SaynColors.wineMaroon,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: SaynColors.wineMaroon,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showRestrictedSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SaynColors.paperCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.security_rounded, color: SaynColors.wineMaroon, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Unlock Restricted Setting',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: SaynColors.wineMaroon,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'On Android 13, 14, and 15, accessibility for sideloaded apps is restricted by default. Follow these 4 quick steps to enable it:',
                style: TextStyle(
                  fontSize: 12,
                  color: SaynColors.paperTextMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              _buildStepItem('1', 'Tap "Open App Info" below to view SAYN in Android settings.'),
              _buildStepItem('2', 'Tap the three vertical dots (⋮) in the top-right corner.'),
              _buildStepItem('3', 'Tap "Allow restricted settings" and verify your PIN or fingerprint.'),
              _buildStepItem('4', 'Return here and tap "Accessibility" to turn on SAYN.'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        PlatformChannels.openAppDetailsSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SaynColors.wineMaroon,
                        foregroundColor: SaynColors.warmCream,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.settings_applications_rounded, size: 17),
                      label: const Text(
                        '1. Open App Info',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        PlatformChannels.openAccessibilitySettings();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: SaynColors.wineMaroon),
                        foregroundColor: SaynColors.wineMaroon,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.accessibility_new_rounded, size: 17),
                      label: const Text(
                        '2. Accessibility',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: SaynColors.wineMaroon,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: SaynColors.paperText,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
