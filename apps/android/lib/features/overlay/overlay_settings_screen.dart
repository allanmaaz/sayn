import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/platform_channels.dart';

class OverlaySettingsScreen extends StatefulWidget {
  const OverlaySettingsScreen({super.key});

  @override
  State<OverlaySettingsScreen> createState() => _OverlaySettingsScreenState();
}

class _OverlaySettingsScreenState extends State<OverlaySettingsScreen> {
  bool _hasPermission = false;
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
    final running = await PlatformChannels.isOverlayRunning();
    if (mounted) {
      setState(() {
        _hasPermission = hasPerm;
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
              padding: const EdgeInsets.all(16),
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
                ],
              ),
            ),
    );
  }
}
