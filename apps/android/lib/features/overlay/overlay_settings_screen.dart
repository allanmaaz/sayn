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
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── 1. OVERVIEW CARD ───
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SaynColors.paperCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.bubble_chart_rounded, color: SaynColors.wineMaroon, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'System-Wide Floating Bubble',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: SaynColors.paperText,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'SAYN displays a compact floating microphone bubble that appears over WhatsApp, Gmail, Slack, and any app on your phone so you can dictate and refine messages anywhere without switching screens.',
                          style: TextStyle(
                            fontSize: 12,
                            color: SaynColors.paperTextMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 2. DISPLAY OVER OTHER APPS PERMISSION ───
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SaynColors.paperCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Display Over Other Apps',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: SaynColors.paperText,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _hasPermission
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFDE8EC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _hasPermission ? 'Granted' : 'Required',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _hasPermission
                                      ? const Color(0xFF2E7D32)
                                      : SaynColors.wineMaroon,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Android requires permission to draw the floating microphone above third-party applications.',
                          style: TextStyle(
                            fontSize: 12,
                            color: SaynColors.paperTextMuted,
                            height: 1.4,
                          ),
                        ),
                        if (!_hasPermission) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _requestPermission,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SaynColors.wineMaroon,
                                foregroundColor: SaynColors.warmCream,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.open_in_new_rounded, size: 16),
                              label: const Text(
                                'Open Settings →',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 3. VOICE WHILE TYPING (ACCESSIBILITY SERVICE) ───
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SaynColors.paperCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.all_inclusive_rounded, color: SaynColors.wineMaroon, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Voice While Typing',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: SaynColors.paperText,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _hasAccessibilityPermission
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFDE8EC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _hasAccessibilityPermission ? 'Active' : 'Enable',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _hasAccessibilityPermission
                                      ? const Color(0xFF2E7D32)
                                      : SaynColors.wineMaroon,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Automatically reveals the voice pill whenever your keyboard opens in Gboard, Samsung Keyboard, or SwiftKey, typing your speech directly into chat fields.',
                          style: TextStyle(
                            fontSize: 12,
                            color: SaynColors.paperTextMuted,
                            height: 1.45,
                          ),
                        ),
                        if (!_hasAccessibilityPermission) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await PlatformChannels.openAccessibilitySettings();
                                    await Future.delayed(const Duration(milliseconds: 600));
                                    _checkStatus();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SaynColors.wineMaroon,
                                    foregroundColor: SaynColors.warmCream,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.accessibility_new_rounded, size: 16),
                                  label: const Text(
                                    'Enable →',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () => _showRestrictedSettingsDialog(context),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: SaynColors.paperSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: SaynColors.paperBorder),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.help_outline_rounded, size: 15, color: SaynColors.wineMaroon),
                                      SizedBox(width: 6),
                                      Text(
                                        'Grayed out?',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: SaynColors.wineMaroon,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showRestrictedSettingsDialog(context),
                            child: const Text(
                              'Android 13–15 says "Restricted setting"? Tap here for step-by-step unlock guide.',
                              style: TextStyle(
                                fontSize: 11,
                                color: SaynColors.wineMaroon,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 4. FLOATING MICROPHONE LIVE TOGGLE ───
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SaynColors.paperCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Floating Microphone',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: SaynColors.paperText,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Displays draggable microphone bubble across apps',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: SaynColors.paperTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isRunning,
                          activeColor: SaynColors.wineMaroon,
                          activeTrackColor: SaynColors.wineMaroon.withOpacity(0.35),
                          inactiveTrackColor: SaynColors.paperBorder,
                          onChanged: _hasPermission ? _toggleAssistant : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 5. QUICK TUTORIAL REPLAY ───
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SaynColors.paperCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Quick Tutorial',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: SaynColors.paperText,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Replay the step-by-step assistant guide',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: SaynColors.paperTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => OnboardingDialog.show(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SaynColors.paperSurface,
                            foregroundColor: SaynColors.wineMaroon,
                            elevation: 0,
                            side: const BorderSide(color: SaynColors.paperBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text(
                            'Replay >',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
