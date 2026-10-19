import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'English';
  bool _improveModel = false;
  bool _cloudStorage = false;
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
      _selectedLanguage = prefs.getString('sayn_language') ?? 'English';
      _improveModel = prefs.getBool('sayn_improve_model') ?? false;
      _cloudStorage = prefs.getBool('sayn_cloud_storage') ?? false;
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
          icon: const Icon(Icons.arrow_back_rounded, color: SaynColors.wineMaroon, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: SaynColors.wineMaroon,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. GENERAL (Matching Screenshot 5) ───
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
                onTap: () => _showNotice('Typing Preferences', 'Smart capitalisation, double-space period, and suggestion bar are actively enabled.'),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: 'SAYN Burgundy (Default)',
                onTap: () => _showNotice('Theme', 'Currently using the official Warm Cream & Wine Burgundy palette.'),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.stay_current_portrait_rounded,
                title: 'Typing Sound & Haptic',
                subtitle: 'Keypress sound and vibration',
                onTap: () => Navigator.pop(context),
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
                onTap: () => _showNotice('Microphone Access', 'Microphone permissions are granted for voice flow dictation.'),
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.graphic_eq_rounded,
                title: 'Voice Settings',
                subtitle: 'Dictation language, speed, and more',
                onTap: () => _showNotice('Voice Settings', 'Continuous dictation and auto-silence punctuation commit active.'),
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
                icon: Icons.adjust_rounded,
                title: 'Flow Bubble Size',
                subtitle: 'Adjust the floating bubble size',
                onTap: _showBubbleSizeDialog,
              ),
              _buildDivider(),
              _buildSettingItem(
                icon: Icons.filter_tilt_shift_rounded,
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
                subtitle: 'v1.1.5',
                onTap: () => _showNotice('App Version', 'SAYN v1.1.5 (Build 16) is up to date on your device.'),
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
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8C7368),
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
        border: Border.all(color: SaynColors.paperBorder, width: 1.2),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF3E7DC),
                shape: BoxShape.circle,
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
                      fontWeight: FontWeight.w700,
                      color: SaynColors.wineMaroon,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8C7368),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: SaynColors.wineMaroon,
              size: 20,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF3E7DC),
              shape: BoxShape.circle,
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
                    fontWeight: FontWeight.w700,
                    color: SaynColors.wineMaroon,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF8C7368),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: SaynColors.wineMaroon,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD6C8B8),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: SaynColors.paperBorder, height: 1, indent: 68);
  }

  void _showNotice(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaynColors.paperCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'serif', color: SaynColors.wineMaroon, fontWeight: FontWeight.w800),
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

  void _showLanguageDialog() {
    final languages = ['English', 'Spanish', 'French', 'German', 'Arabic', 'Japanese'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: SaynColors.paperCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Select Language',
          style: TextStyle(fontFamily: 'serif', color: SaynColors.wineMaroon, fontWeight: FontWeight.w800),
        ),
        children: languages.map((lang) {
          final isSelected = lang == _selectedLanguage;
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedLanguage = lang);
              _saveSetting('sayn_language', lang);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? SaynColors.wineMaroon : SaynColors.paperText,
                  ),
                ),
                if (isSelected) const Icon(Icons.check_rounded, color: SaynColors.wineMaroon, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showBubbleSizeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: SaynColors.paperCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Flow Bubble Size',
            style: TextStyle(fontFamily: 'serif', color: SaynColors.wineMaroon, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_bubbleSize.round()} dp', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SaynColors.wineMaroon)),
              Slider(
                value: _bubbleSize,
                min: 44.0,
                max: 72.0,
                divisions: 7,
                activeColor: SaynColors.wineMaroon,
                inactiveColor: const Color(0xFFD6C8B8),
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
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: SaynColors.paperCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Flow Bubble Opacity',
            style: TextStyle(fontFamily: 'serif', color: SaynColors.wineMaroon, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(_bubbleOpacity * 100).round()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SaynColors.wineMaroon)),
              Slider(
                value: _bubbleOpacity,
                min: 0.4,
                max: 1.0,
                divisions: 6,
                activeColor: SaynColors.wineMaroon,
                inactiveColor: const Color(0xFFD6C8B8),
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
}
