import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/platform_channels.dart';
import '../onboarding/onboarding_dialog.dart';

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
    // Re-check status on returning
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
      appBar: AppBar(
        title: const Text(
          'Floating Assistant',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Overview Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SaynColors.darkSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SaynColors.darkDivider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'System-Wide Floating Bubble',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SaynColors.darkText,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'SAYN displays a compact floating microphone bubble that appears over WhatsApp, Gmail, Slack, and other supported apps so you can dictate and refine messages anywhere.',
                          style: TextStyle(
                            fontSize: 12,
                            color: SaynColors.darkSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Permission Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SaynColors.darkSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SaynColors.darkDivider),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SaynColors.darkText,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _hasPermission
                                    ? SaynColors.darkSuccess.withOpacity(0.15)
                                    : SaynColors.darkWarning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _hasPermission ? 'Granted' : 'Permission Required',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _hasPermission
                                      ? SaynColors.darkSuccess
                                      : SaynColors.darkWarning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Android requires explicit user authorization to draw system overlays above third-party applications.',
                          style: TextStyle(
                            fontSize: 11,
                            color: SaynColors.darkSecondary,
                          ),
                        ),
                        if (!_hasPermission) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _requestPermission,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: SaynColors.darkAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Open System Settings',
                              style: TextStyle(
                                  fontSize: 12, color: SaynColors.darkAccent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Universal Accessibility Card (SAYN Voice style across ALL keyboards)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SaynColors.darkSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SaynColors.darkDivider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.all_inclusive_rounded, color: SaynColors.darkAccent, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Universal Voice Across Any Keyboard',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _hasAccessibilityPermission
                                    ? SaynColors.darkSuccess.withOpacity(0.15)
                                    : const Color(0x33A83249),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _hasAccessibilityPermission ? 'Active' : 'Enable',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _hasAccessibilityPermission
                                      ? SaynColors.darkSuccess
                                      : SaynColors.warmCream,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Allows the SAYN voice pill to automatically show whenever you type using Gboard, Samsung Keyboard, or SwiftKey, and types your speech directly into the chat.',
                          style: TextStyle(
                            fontSize: 11,
                            color: SaynColors.darkSecondary,
                            height: 1.4,
                          ),
                        ),
                        if (!_hasAccessibilityPermission) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await PlatformChannels.openAccessibilitySettings();
                                    await Future.delayed(const Duration(milliseconds: 600));
                                    _checkStatus();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: SaynColors.darkAccent),
                                    backgroundColor: SaynColors.darkAccent.withOpacity(0.12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Open Accessibility',
                                    style: TextStyle(
                                        fontSize: 12, color: SaynColors.warmCream, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showRestrictedSettingsDialog(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: SaynColors.darkElevated,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: SaynColors.darkDivider),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.help_outline_rounded, size: 14, color: SaynColors.darkWarning),
                                      SizedBox(width: 4),
                                      Text(
                                        'Grayed out?',
                                        style: TextStyle(fontSize: 11, color: SaynColors.darkWarning, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _showRestrictedSettingsDialog(context),
                            child: const Text(
                              'Android 13–15 says "Restricted setting"? Tap here for 3-step unlock guide.',
                              style: TextStyle(fontSize: 10.5, color: SaynColors.darkMuted, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Service Toggle Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SaynColors.darkSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SaynColors.darkDivider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Enable Assistant Bubble',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SaynColors.darkText,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Displays draggable microphone bubble',
                              style: TextStyle(
                                fontSize: 11,
                                color: SaynColors.darkSecondary,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isRunning,
                          activeColor: SaynColors.darkAccent,
                          onChanged: _hasPermission ? _toggleAssistant : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Onboarding Replay Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SaynColors.darkSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SaynColors.darkBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Interactive Walkthrough Tour',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Replay the step-by-step introduction guide',
                              style: TextStyle(
                                fontSize: 11,
                                color: SaynColors.darkSecondary,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => OnboardingDialog.show(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SaynColors.darkAccent.withOpacity(0.18),
                            foregroundColor: SaynColors.darkAccent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Replay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
      backgroundColor: SaynColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.security_rounded, color: SaynColors.darkWarning, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Unlock Restricted Setting',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'On Android 13, 14, and 15, accessibility for sideloaded apps is temporarily restricted by default. Follow these 3 quick steps to enable it:',
                style: TextStyle(fontSize: 12, color: SaynColors.darkSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              _buildStepItem('1', 'Tap "Open App Info" below to view SAYN in Android settings.'),
              _buildStepItem('2', 'Tap the three vertical dots (⋮) in the top-right corner.'),
              _buildStepItem('3', 'Tap "Allow restricted settings" and verify your PIN or fingerprint.'),
              _buildStepItem('4', 'Return here and tap "Open Accessibility" to turn on SAYN.'),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        PlatformChannels.openAppDetailsSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SaynColors.darkAccent,
                        foregroundColor: SaynColors.warmCream,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.settings_applications_rounded, size: 18),
                      label: const Text(
                        '1. Open App Info',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                        side: const BorderSide(color: SaynColors.darkDivider),
                        foregroundColor: SaynColors.warmCream,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.accessibility_new_rounded, size: 18),
                      label: const Text(
                        '2. Accessibility',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: SaynColors.darkElevated,
              shape: BoxShape.circle,
              border: Border.all(color: SaynColors.darkDivider),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: SaynColors.darkAccent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: SaynColors.darkText, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
