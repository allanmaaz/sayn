import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/platform_channels.dart';
import '../../services/update_service.dart';
import '../navigation/sayn_drawer.dart';

class KeyboardSettingsScreen extends StatefulWidget {
  const KeyboardSettingsScreen({super.key});

  @override
  State<KeyboardSettingsScreen> createState() => _KeyboardSettingsScreenState();
}

class _KeyboardSettingsScreenState extends State<KeyboardSettingsScreen> {
  bool _isEnabled = false;
  bool _hasMicPermission = false;
  bool _isLoading = true;
  String _defaultMode = 'standard';
  bool _keySoundEnabled = true;
  bool _keyVibrationEnabled = true;
  String _keyVibrationIntensity = 'medium';
  bool _autoCorrectEnabled = true;
  final TextEditingController _sandboxController = TextEditingController();

  final List<Map<String, String>> _modes = const [
    {'id': 'standard', 'label': 'Standard'},
    {'id': 'fluent', 'label': 'Fluent'},
    {'id': 'natural', 'label': 'Natural'},
    {'id': 'professional', 'label': 'Professional'},
    {'id': 'casual', 'label': 'Casual'},
    {'id': 'shorten', 'label': 'Shorten'},
    {'id': 'expand', 'label': 'Expand'},
    {'id': 'formal', 'label': 'Formal'},
  ];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _sandboxController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    final enabled = await PlatformChannels.isKeyboardEnabled();
    final mode = await PlatformChannels.getDefaultMode();
    final micGranted = await PlatformChannels.checkAudioPermission();
    final feedback = await PlatformChannels.getKeyboardFeedbackSettings();
    final sound = feedback['soundEnabled'] as bool? ?? true;
    final vibration = feedback['vibrationEnabled'] as bool? ?? true;
    final intensity = feedback['vibrationIntensity'] as String? ?? 'medium';
    final autoCorrect = feedback['autoCorrectEnabled'] as bool? ?? true;

    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _defaultMode = mode;
        _hasMicPermission = micGranted;
        _keySoundEnabled = sound;
        _keyVibrationEnabled = vibration;
        _keyVibrationIntensity = intensity;
        _autoCorrectEnabled = autoCorrect;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateFeedbackSettings({
    bool? sound,
    bool? vibration,
    String? intensity,
    bool? autoCorrect,
  }) async {
    final newSound = sound ?? _keySoundEnabled;
    final newVib = vibration ?? _keyVibrationEnabled;
    final newInt = intensity ?? _keyVibrationIntensity;
    final newAuto = autoCorrect ?? _autoCorrectEnabled;
    setState(() {
      _keySoundEnabled = newSound;
      _keyVibrationEnabled = newVib;
      _keyVibrationIntensity = newInt;
      _autoCorrectEnabled = newAuto;
    });
    await PlatformChannels.setKeyboardFeedbackSettings(
      soundEnabled: newSound,
      vibrationEnabled: newVib,
      vibrationIntensity: newInt,
      autoCorrectEnabled: newAuto,
    );
  }

  Future<void> _updateDefaultMode(String mode) async {
    setState(() => _defaultMode = mode);
    await PlatformChannels.setDefaultMode(mode);
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
          'Smart Keyboard',
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
                            Icon(Icons.keyboard_rounded, color: SaynColors.wineMaroon, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Obsidian Chiclet Keyboard',
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
                          'SAYN Smart Keyboard provides a tactile typing experience with smart suggestions, spacebar trackpad cursor control, and seamless one-tap voice overlay integration.',
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

                  // ─── 2. KEYBOARD SETUP & ACTIVATION CARD ───
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
                              'Keyboard Setup',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: SaynColors.paperText,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isEnabled
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFDE8EC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isEnabled ? 'Activated' : 'Not Activated',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _isEnabled
                                      ? const Color(0xFF2E7D32)
                                      : SaynColors.wineMaroon,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '1. Tap "Open Keyboard Settings →" below.\n2. Enable "SAYN Smart Keyboard" in On-Screen Keyboards.\n3. Switch to SAYN using the globe/keyboard switcher key.',
                          style: TextStyle(
                            fontSize: 12,
                            color: SaynColors.paperTextMuted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await PlatformChannels.openKeyboardSettings();
                              _loadState();
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
                            icon: const Icon(Icons.settings_input_component_rounded, size: 16),
                            label: const Text(
                              'Open Keyboard Settings →',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 3. MICROPHONE (SAYN VOICE) ACCESS CARD ───
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
                                Icon(Icons.mic_rounded, color: SaynColors.wineMaroon, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Microphone (SAYN Voice)',
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
                                color: _hasMicPermission
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFDE8EC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _hasMicPermission ? 'Granted' : 'Needs Permission',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _hasMicPermission
                                      ? const Color(0xFF2E7D32)
                                      : SaynColors.wineMaroon,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Required for in-keyboard speech-to-text dictation. Allows instant dictation directly from your keyboard toolbar.',
                          style: TextStyle(
                            fontSize: 12,
                            color: SaynColors.paperTextMuted,
                            height: 1.4,
                          ),
                        ),
                        if (!_hasMicPermission) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await PlatformChannels.requestAudioPermission();
                                await Future.delayed(const Duration(milliseconds: 500));
                                _loadState();
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
                              icon: const Icon(Icons.mic, size: 16),
                              label: const Text(
                                'Grant Microphone Access',
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

                  // ─── 4. TYPING SOUND & HAPTIC VIBRATION CARD ───
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
                        const Row(
                          children: [
                            Icon(Icons.vibration_rounded, size: 18, color: SaynColors.wineMaroon),
                            SizedBox(width: 8),
                            Text(
                              'Typing Sound & Haptic',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: SaynColors.paperText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Keypress Vibration',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: SaynColors.paperText,
                            ),
                          ),
                          subtitle: const Text(
                            'Tactile physical haptic pulse on keypress',
                            style: TextStyle(fontSize: 11.5, color: SaynColors.paperTextMuted),
                          ),
                          value: _keyVibrationEnabled,
                          activeColor: SaynColors.wineMaroon,
                          activeTrackColor: SaynColors.wineMaroon.withOpacity(0.35),
                          inactiveTrackColor: SaynColors.paperBorder,
                          onChanged: (val) => _updateFeedbackSettings(vibration: val),
                        ),
                        if (_keyVibrationEnabled) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Vibration Intensity: ',
                                style: TextStyle(fontSize: 11.5, color: SaynColors.paperTextMuted),
                              ),
                              const Spacer(),
                              ...['subtle', 'medium', 'strong'].map((lvl) {
                                final isSelected = _keyVibrationIntensity == lvl;
                                final label = lvl == 'subtle'
                                    ? 'Subtle'
                                    : (lvl == 'medium' ? 'Crisp' : 'Strong');
                                return Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: ChoiceChip(
                                    label: Text(label),
                                    selected: isSelected,
                                    selectedColor: SaynColors.wineMaroon,
                                    labelStyle: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : SaynColors.wineMaroon,
                                    ),
                                    backgroundColor: SaynColors.paperSurface,
                                    side: BorderSide(
                                      color: isSelected ? SaynColors.wineMaroon : SaynColors.paperBorder,
                                    ),
                                    onSelected: (val) {
                                      if (val) _updateFeedbackSettings(intensity: lvl);
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                        const Divider(color: SaynColors.paperBorder, height: 22),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Keypress Click Sound',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: SaynColors.paperText,
                            ),
                          ),
                          subtitle: const Text(
                            'Subtle mechanical click audio on keypress',
                            style: TextStyle(fontSize: 11.5, color: SaynColors.paperTextMuted),
                          ),
                          value: _keySoundEnabled,
                          activeColor: SaynColors.wineMaroon,
                          activeTrackColor: SaynColors.wineMaroon.withOpacity(0.35),
                          inactiveTrackColor: SaynColors.paperBorder,
                          onChanged: (val) => _updateFeedbackSettings(sound: val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 5. KEYBOARD AUTO-CORRECT CARD ───
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
                        const Row(
                          children: [
                            Icon(Icons.spellcheck_rounded, size: 18, color: SaynColors.wineMaroon),
                            SizedBox(width: 8),
                            Text(
                              'Auto-Correct',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: SaynColors.paperText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Instant Typing Corrections',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: SaynColors.paperText,
                            ),
                          ),
                          subtitle: const Text(
                            'Automatically fixes common typos and capitalizes letters while you type on SAYN Keyboard.',
                            style: TextStyle(fontSize: 11.5, color: SaynColors.paperTextMuted),
                          ),
                          value: _autoCorrectEnabled,
                          activeColor: SaynColors.wineMaroon,
                          activeTrackColor: SaynColors.wineMaroon.withOpacity(0.35),
                          inactiveTrackColor: SaynColors.paperBorder,
                          onChanged: (val) => _updateFeedbackSettings(autoCorrect: val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 6. INTERACTIVE "TRY SAYN KEYBOARD" TEST BOX ───
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
                        const Row(
                          children: [
                            Icon(Icons.touch_app_rounded, color: SaynColors.wineMaroon, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Try SAYN Keyboard',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: SaynColors.paperText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap the field below to bring up the SAYN Keyboard and test typing, spacebar trackpad sliding, and voice flow.',
                          style: TextStyle(fontSize: 11.5, color: SaynColors.paperTextMuted),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: SaynColors.paperSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: SaynColors.paperBorder),
                          ),
                          child: TextField(
                            controller: _sandboxController,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 13.5, color: SaynColors.paperText),
                            decoration: const InputDecoration(
                              hintText: 'Type here to test SAYN Smart Keyboard...',
                              hintStyle: TextStyle(fontSize: 13, color: SaynColors.paperTextMuted),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 7. PRIVACY & SENSITIVE FIELD GUARD CARD ───
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
                            Icon(Icons.shield_outlined, color: SaynColors.wineMaroon, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Privacy & Security Guard',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: SaynColors.paperText,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Zero keystroke logging: your typing is strictly on-device.\n• Sensitive fields (passwords, PINs, card numbers) automatically hide AI toolbars.\n• AI refinement is triggered only on your explicit tap.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: SaynColors.paperTextMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 8. APP UPDATES CARD ───
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
                        const Row(
                          children: [
                            Icon(Icons.autorenew_rounded, color: SaynColors.wineMaroon, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'App Updates & Releases',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: SaynColors.paperText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'SAYN automatically checks for the latest updates. You can also manually check to get the newest features immediately.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: SaynColors.paperTextMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Checking for updates...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              final info = await UpdateService.checkUpdate();
                              if (!mounted) return;
                              if (info != null && info.hasUpdate) {
                                UpdateService.showUpdateDialog(context, info);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      info != null
                                          ? 'You are on the latest version (v${info.currentVersion})'
                                          : 'Could not connect to update server',
                                    ),
                                    backgroundColor: SaynColors.wineMaroon,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.cloud_download_outlined, size: 16),
                            label: const Text(
                              'Check for Updates Now →',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: SaynColors.wineMaroon),
                              foregroundColor: SaynColors.wineMaroon,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
}
