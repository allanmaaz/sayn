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
  bool _keySoundEnabled = true;
  bool _keyVibrationEnabled = true;
  String _keyVibrationIntensity = 'Subtle'; // Subtle, Crisp, Strong
  bool _autoCorrectEnabled = true;
  final TextEditingController _testController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    final enabled = await PlatformChannels.isKeyboardEnabled();
    final micGranted = await PlatformChannels.checkAudioPermission();
    final feedback = await PlatformChannels.getKeyboardFeedbackSettings();
    final sound = feedback['soundEnabled'] as bool? ?? true;
    final vibration = feedback['vibrationEnabled'] as bool? ?? true;
    final rawIntensity = feedback['vibrationIntensity'] as String? ?? 'subtle';
    final autoCorrect = feedback['autoCorrectEnabled'] as bool? ?? true;

    String intensity = 'Subtle';
    if (rawIntensity.toLowerCase() == 'strong') {
      intensity = 'Strong';
    } else if (rawIntensity.toLowerCase() == 'medium' || rawIntensity.toLowerCase() == 'crisp') {
      intensity = 'Crisp';
    }

    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _hasMicPermission = micGranted;
        _keySoundEnabled = sound;
        _keyVibrationEnabled = vibration;
        _keyVibrationIntensity = intensity;
        _autoCorrectEnabled = autoCorrect;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings({
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
      vibrationIntensity: newInt.toLowerCase(),
      autoCorrectEnabled: newAuto,
    );
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
            icon: const Icon(Icons.menu_rounded, color: SaynColors.wineMaroon, size: 28),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: SaynColors.wineMaroon,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.graphic_eq_rounded,
                  color: SaynColors.warmCream,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'S A Y N',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
                color: SaynColors.wineMaroon,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: SaynColors.wineMaroon),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header (Matching Screenshot 2: Smart Keyboard (IME))
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Smart Keyboard (IME)',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: SaynColors.wineMaroon,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ─── 1. KEYBOARD SETUP CARD ───
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _buildIconCircle(Icons.keyboard_outlined),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Keyboard setup',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: SaynColors.wineMaroon,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                await PlatformChannels.openKeyboardSettings();
                                _loadState();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E7DC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isEnabled ? 'Activated' : 'Not activated',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: SaynColors.wineMaroon,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: SaynColors.wineMaroon,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () async {
                              await PlatformChannels.openKeyboardSettings();
                              _loadState();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SaynColors.wineMaroon,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Open keyboard settings  →',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 2. MICROPHONE (SAYN VOICE) CARD ───
                  _buildCard(
                    child: Row(
                      children: [
                        _buildIconCircle(Icons.mic_none_rounded),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Microphone (SAYN Voice)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: SaynColors.wineMaroon,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            await PlatformChannels.requestAudioPermission();
                            _loadState();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E7DC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _hasMicPermission ? 'Granted' : 'Needs access',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: SaynColors.wineMaroon,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: SaynColors.wineMaroon,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 3. TYPING SOUND & HAPTIC CARD ───
                  _buildCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildIconCircle(Icons.stay_current_portrait_rounded),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Typing sound & haptic',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: SaynColors.wineMaroon,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Keypress vibration',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: SaynColors.wineMaroon,
                              ),
                            ),
                            _buildMaroonSwitch(
                              value: _keyVibrationEnabled,
                              onChanged: (val) => _updateSettings(vibration: val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Vibration intensity',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: SaynColors.wineMaroon,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildIntensitySegment('Subtle'),
                                const SizedBox(width: 4),
                                _buildIntensitySegment('Crisp'),
                                const SizedBox(width: 4),
                                _buildIntensitySegment('Strong'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: SaynColors.paperBorder, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Keypress click sound',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: SaynColors.wineMaroon,
                              ),
                            ),
                            _buildMaroonSwitch(
                              value: _keySoundEnabled,
                              onChanged: (val) => _updateSettings(sound: val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 4. AUTO-CORRECT CARD ───
                  _buildCard(
                    child: Row(
                      children: [
                        _buildIconCircle(Icons.auto_awesome_rounded),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Auto-correct',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: SaynColors.wineMaroon,
                            ),
                          ),
                        ),
                        _buildMaroonSwitch(
                          value: _autoCorrectEnabled,
                          onChanged: (val) => _updateSettings(autoCorrect: val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 5. TRY SAYN KEYBOARD TEST CARD ───
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildIconCircle(Icons.edit_outlined),
                            const SizedBox(width: 14),
                            const Text(
                              'Try SAYN Keyboard',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: SaynColors.wineMaroon,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EAE0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE8DFD1), width: 1),
                          ),
                          child: TextField(
                            controller: _testController,
                            style: const TextStyle(
                              fontSize: 14,
                              color: SaynColors.wineMaroon,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Type here to test...',
                              hintStyle: TextStyle(
                                color: Color(0xFFB09D8B),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 6. PRIVACY CARD ───
                  _buildCard(
                    onTap: _showPrivacyDialog,
                    child: Row(
                      children: [
                        _buildIconCircle(Icons.shield_outlined),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Privacy',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: SaynColors.wineMaroon,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: SaynColors.wineMaroon,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── 7. APP UPDATES CARD ───
                  _buildCard(
                    child: Row(
                      children: [
                        _buildIconCircle(Icons.cloud_download_outlined),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'App updates',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: SaynColors.wineMaroon,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => UpdateService.checkForUpdate(context, manual: true),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: SaynColors.wineMaroon, width: 1.2),
                            foregroundColor: SaynColors.wineMaroon,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text(
                            'Check for updates  →',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({required Widget child, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: SaynColors.paperCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SaynColors.paperBorder, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildIconCircle(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFF3E7DC),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: SaynColors.wineMaroon, size: 22),
    );
  }

  Widget _buildMaroonSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: SaynColors.wineMaroon,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: const Color(0xFFD6C8B8),
    );
  }

  Widget _buildIntensitySegment(String label) {
    final isSelected = _keyVibrationIntensity == label;
    return GestureDetector(
      onTap: () => _updateSettings(intensity: label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? SaynColors.wineMaroon : const Color(0xFFFAF5EE),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? SaynColors.wineMaroon : const Color(0xFFE8DFD1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : SaynColors.wineMaroon,
          ),
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaynColors.paperCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keyboard Privacy',
          style: TextStyle(fontFamily: 'serif', color: SaynColors.wineMaroon, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'SAYN Smart Keyboard operates locally with full device isolation. Keystrokes, passwords, and private messages are never logged or stored. Only requested AI rewrites and speech dictations are sent to secure servers.',
          style: TextStyle(fontSize: 13, height: 1.45, color: SaynColors.paperText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: SaynColors.wineMaroon, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
