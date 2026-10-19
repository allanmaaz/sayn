import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'English (US)';
  bool _improveModel = false;
  bool _cloudStorage = true;
  double _bubbleSize = 56.0;
  double _bubbleOpacity = 0.95;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('sayn_language') ?? 'English (US)';
      _improveModel = prefs.getBool('sayn_improve_model') ?? false;
      _cloudStorage = prefs.getBool('sayn_cloud_storage') ?? true;
      _bubbleSize = prefs.getDouble('sayn_bubble_size') ?? 56.0;
      _bubbleOpacity = prefs.getDouble('sayn_bubble_opacity') ?? 0.95;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaynColors.paperBg,
      appBar: AppBar(
        backgroundColor: SaynColors.paperBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SaynColors.wineMaroon),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: SaynColors.wineMaroon,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. GENERAL ───
            _buildSectionHeader('GENERAL'),
            _buildGroupCard([
              _buildSettingItem(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: _selectedLanguage,
                onTap: _showLanguageDialog,
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.chat_outlined,
                title: 'Typing Preferences',
                subtitle: 'Auto-correct, suggestions, and more',
                onTap: () => _showSimpleNotice('Typing Preferences', 'Smart capitalisation, double-space period, and suggestion bar are actively enabled.'),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: 'SAYN Burgundy (Default)',
                onTap: () => _showSimpleNotice('Theme', 'Currently using the official Warm Cream & Wine Burgundy palette.'),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.vibration_rounded,
                title: 'Typing Sound & Haptic',
                subtitle: 'Keypress sound and vibration',
                onTap: () => Navigator.pop(context), // takes back to Smart Keyboard tab
              ),
            ]),
            const SizedBox(height: 20),

            // ─── 2. VOICE & INPUT ───
            _buildSectionHeader('VOICE & INPUT'),
            _buildGroupCard([
              _buildSettingItem(
                icon: Icons.mic_none_rounded,
                title: 'Microphone (SAYN Voice)',
                subtitle: 'Manage microphone access',
                onTap: () => _showSimpleNotice('Microphone Access', 'Microphone permissions are granted for voice flow dictation.'),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.graphic_eq_rounded,
                title: 'Voice Settings',
                subtitle: 'Dictation language, speed, and more',
                onTap: () => _showSimpleNotice('Voice Settings', 'Continuous dictation and auto-silence punctuation commit active.'),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.keyboard_outlined,
                title: 'Keyboard Settings',
                subtitle: 'Keypress behaviour and layout',
                onTap: () => Navigator.pop(context),
              ),
            ]),
            const SizedBox(height: 20),

            // ─── 3. APPEARANCE ───
            _buildSectionHeader('APPEARANCE'),
            _buildGroupCard([
              _buildSettingItem(
                icon: Icons.circle_outlined,
                title: 'Flow Bubble Size',
                subtitle: 'Adjust the floating bubble size',
                onTap: _showBubbleSizeDialog,
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.blur_on_rounded,
                title: 'Flow Bubble Opacity',
                subtitle: 'Adjust the bubble transparency',
                onTap: _showBubbleOpacityDialog,
              ),
            ]),
            const SizedBox(height: 20),

            // ─── 4. PRIVACY & DATA ───
            _buildSectionHeader('PRIVACY & DATA'),
            _buildGroupCard([
              _buildSwitchItem(
                icon: Icons.shield_outlined,
                title: 'Improve the model for everyone',
                subtitle: 'When on, your voice, transcripts and edits may be used to improve SAYN.',
                value: _improveModel,
                onChanged: (val) {
                  setState(() => _improveModel = val);
                  _saveSetting('sayn_improve_model', val);
                },
              ),
              _buildDivider(),
              _buildSwitchItem(
                icon: Icons.cloud_outlined,
                title: 'Dictation cloud storage',
                subtitle: 'Stores transcription data on SAYN servers to enable cross device access.',
                value: _cloudStorage,
                onChanged: (val) {
                  setState(() => _cloudStorage = val);
                  _saveSetting('sayn_cloud_storage', val);
                },
              ),
            ]),
            const SizedBox(height: 20),

            // ─── 5. ABOUT ───
            _buildSectionHeader('ABOUT'),
            _buildGroupCard([
              _buildSettingItem(
                icon: Icons.info_outline_rounded,
                title: 'App version',
                subtitle: 'v1.1.4',
                onTap: () => _showSimpleNotice('App Version', 'SAYN v1.1.4 is up to date on your device.'),
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: SaynColors.paperTextMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: SaynColors.paperCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SaynColors.paperBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SaynColors.paperSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: SaynColors.wineMaroon, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: SaynColors.paperText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SaynColors.paperTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: SaynColors.paperTextMuted,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SaynColors.paperSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: SaynColors.wineMaroon, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SaynColors.paperText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: SaynColors.paperTextMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            activeColor: SaynColors.wineMaroon,
            activeTrackColor: SaynColors.wineMaroonLight.withOpacity(0.35),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD6C7B2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: SaynColors.paperBorder,
      indent: 64,
    );
  }

  void _showLanguageDialog() {
    final languages = ['English (US)', 'English (UK)', 'English (India)', 'Spanish', 'French', 'German'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaynColors.paperCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Select Language',
          style: TextStyle(fontFamily: 'serif', color: SaynColors.wineMaroon, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final isSelected = lang == _selectedLanguage;
            return ListTile(
              title: Text(lang, style: TextStyle(color: isSelected ? SaynColors.wineMaroon : SaynColors.paperText, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              trailing: isSelected ? const Icon(Icons.check_rounded, color: SaynColors.wineMaroon) : null,
              onTap: () {
                setState(() => _selectedLanguage = lang);
                _saveSetting('sayn_language', lang);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showBubbleSizeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: SaynColors.paperCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Flow Bubble Size',
            style: TextStyle(fontFamily: 'serif', color: SaynColors.wineMaroon, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_bubbleSize.toInt()} dp', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: SaynColors.wineMaroon)),
              Slider(
                value: _bubbleSize,
                min: 44.0,
                max: 72.0,
                divisions: 4,
                activeColor: SaynColors.wineMaroon,
                onChanged: (val) {
                  setDialogState(() => _bubbleSize = val);
                  setState(() => _bubbleSize = val);
                  _saveSetting('sayn_bubble_size', val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done', style: TextStyle(color: SaynColors.wineMaroon, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBubbleOpacityDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: SaynColors.paperCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Flow Bubble Opacity',
            style: TextStyle(fontFamily: 'serif', color: SaynColors.wineMaroon, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(_bubbleOpacity * 100).toInt()}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: SaynColors.wineMaroon)),
              Slider(
                value: _bubbleOpacity,
                min: 0.4,
                max: 1.0,
                divisions: 6,
                activeColor: SaynColors.wineMaroon,
                onChanged: (val) {
                  setDialogState(() => _bubbleOpacity = val);
                  setState(() => _bubbleOpacity = val);
                  _saveSetting('sayn_bubble_opacity', val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done', style: TextStyle(color: SaynColors.wineMaroon, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSimpleNotice(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaynColors.paperCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'serif', color: SaynColors.wineMaroon, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: const TextStyle(fontSize: 13, height: 1.4)),
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
