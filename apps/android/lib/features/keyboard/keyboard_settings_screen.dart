import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/platform_channels.dart';
import '../../services/update_service.dart';

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
      appBar: AppBar(
        title: const Text(
          'Smart Keyboard (IME)',
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
                          'Minimal Obsidian Chiclet Keyboard',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SaynColors.darkText,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'SAYN Smart Keyboard provides an authentic obsidian chiclet typing experience with instant keycase switching, smart candidate suggestions, swipe spacebar navigation, and seamless universal voice overlay integration.',
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

                  // Activation Guide Card
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
                              'Keyboard Status',
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
                                color: _isEnabled
                                    ? SaynColors.darkSuccess.withOpacity(0.15)
                                    : SaynColors.darkWarning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _isEnabled ? 'Enabled' : 'Not Activated',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _isEnabled
                                      ? SaynColors.darkSuccess
                                      : SaynColors.darkWarning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '1. Tap "Open Keyboard Settings" below.\n2. Enable "SAYN Smart Keyboard" in On-Screen Keyboards.\n3. Switch to SAYN using the globe/keyboard switcher key.',
                          style: TextStyle(
                            fontSize: 12,
                            color: SaynColors.darkSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: () async {
                            await PlatformChannels.openKeyboardSettings();
                            _loadState();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SaynColors.darkAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Open Keyboard Settings',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Microphone Permission Card
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
                              'Microphone (SAYN Voice)',
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
                                color: _hasMicPermission
                                    ? SaynColors.darkSuccess.withOpacity(0.15)
                                    : SaynColors.darkWarning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _hasMicPermission ? 'Granted' : 'Permission Needed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _hasMicPermission
                                      ? SaynColors.darkSuccess
                                      : SaynColors.darkWarning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Required for in-keyboard speech-to-text dictation. Tap below to grant permission if not already enabled.',
                          style: TextStyle(
                            fontSize: 12,
                            color: SaynColors.darkSecondary,
                            height: 1.4,
                          ),
                        ),
                        if (!_hasMicPermission) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await PlatformChannels.requestAudioPermission();
                              await Future.delayed(const Duration(milliseconds: 500));
                              _loadState();
                            },
                            icon: const Icon(Icons.mic, size: 16, color: Colors.white),
                            label: const Text(
                              'Grant Microphone Access',
                              style: TextStyle(fontSize: 12, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SaynColors.darkAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),



                  // Typing Feedback (Haptic Vibration & Click Sound)
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
                          children: const [
                            Icon(Icons.vibration, size: 18, color: SaynColors.darkAccent),
                            SizedBox(width: 8),
                            Text(
                              'Typing Sound & Haptic Vibration',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SaynColors.darkText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Keypress Vibration',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SaynColors.darkText),
                          ),
                          subtitle: const Text(
                            'Tactile physical haptic pulse on keypress',
                            style: TextStyle(fontSize: 11, color: SaynColors.darkSecondary),
                          ),
                          value: _keyVibrationEnabled,
                          activeColor: SaynColors.darkAccent,
                          onChanged: (val) => _updateFeedbackSettings(vibration: val),
                        ),
                        if (_keyVibrationEnabled) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text(
                                'Vibration Intensity: ',
                                style: TextStyle(fontSize: 11, color: SaynColors.darkSecondary),
                              ),
                              const Spacer(),
                              ...['subtle', 'medium', 'strong'].map((lvl) {
                                final isSelected = _keyVibrationIntensity == lvl;
                                final label = lvl == 'subtle' ? 'Subtle' : (lvl == 'medium' ? 'Crisp' : 'Strong');
                                return Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: ChoiceChip(
                                    label: Text(label),
                                    selected: isSelected,
                                    selectedColor: SaynColors.darkAccent,
                                    labelStyle: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? Colors.white : SaynColors.darkSecondary,
                                    ),
                                    backgroundColor: SaynColors.darkSurface2,
                                    side: const BorderSide(color: SaynColors.darkDivider),
                                    onSelected: (val) {
                                      if (val) _updateFeedbackSettings(intensity: lvl);
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                        const Divider(color: SaynColors.darkDivider, height: 20),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Keypress Click Sound',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SaynColors.darkText),
                          ),
                          subtitle: const Text(
                            'Play mechanical iOS click audio on keypress',
                            style: TextStyle(fontSize: 11, color: SaynColors.darkSecondary),
                          ),
                          value: _keySoundEnabled,
                          activeColor: SaynColors.darkAccent,
                          onChanged: (val) => _updateFeedbackSettings(sound: val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Keyboard Auto-Correct Settings (Strictly inside keyboard)
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
                          children: const [
                            Icon(Icons.spellcheck_rounded, size: 18, color: SaynColors.darkAccent),
                            SizedBox(width: 8),
                            Text(
                              'Keyboard Auto-Correct',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SaynColors.darkText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Enable Auto-Correct',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SaynColors.darkText),
                          ),
                          subtitle: const Text(
                            'Automatically fixes common typos, missing apostrophes, and capitalizes "I" only when typing on this keyboard.',
                            style: TextStyle(fontSize: 11, color: SaynColors.darkSecondary),
                          ),
                          value: _autoCorrectEnabled,
                          activeColor: SaynColors.darkAccent,
                          onChanged: (val) => _updateFeedbackSettings(autoCorrect: val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Interactive Typing Sandbox
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
                        const Text(
                          'Interactive Typing Sandbox',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: SaynColors.darkAccent,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap the field below to bring up the SAYN Keyboard and test typing, styles, and instant text replacement.',
                          style: TextStyle(fontSize: 11, color: SaynColors.darkSecondary),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: SaynColors.darkSurface2,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: SaynColors.darkDivider),
                          ),
                          child: TextField(
                            controller: _sandboxController,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 13, color: SaynColors.darkText),
                            decoration: const InputDecoration(
                              hintText: 'Type here to test SAYN Smart Keyboard...',
                              hintStyle: TextStyle(fontSize: 13, color: SaynColors.darkMuted),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Security & Sensitive Fields Notice
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
                          'Privacy & Sensitive Field Guard',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: SaynColors.darkSuccess,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '• Zero keystroke logging: your typing is never recorded.\n• Sensitive fields (passwords, PINs, card numbers) automatically hide the AI toolbar.\n• AI refinement is triggered only on explicit user tap.',
                          style: TextStyle(
                            fontSize: 11,
                            color: SaynColors.darkSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // In-App Auto-Updates Card
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
                          children: [
                            const Icon(Icons.autorenew_rounded, color: SaynColors.roseMaroon, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'App Updates & Releases',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SaynColors.warmCream,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'SAYN automatically checks for the latest updates. You can also manually check to get the newest features immediately.',
                          style: TextStyle(
                            fontSize: 11,
                            color: SaynColors.darkSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
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
                                  backgroundColor: SaynColors.darkSuccess,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.cloud_download_outlined, size: 16, color: SaynColors.warmCream),
                          label: const Text(
                            'Check for Updates Now',
                            style: TextStyle(color: SaynColors.warmCream, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: SaynColors.roseMaroon),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
