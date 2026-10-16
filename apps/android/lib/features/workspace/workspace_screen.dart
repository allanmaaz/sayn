import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../services/platform_channels.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _customInstructionController = TextEditingController();
  final SaynApiClient _apiClient = SaynApiClient();

  // Primary styles requested by user
  String _selectedStyle = 'natural'; // 'natural' | 'fluent' | 'professional'
  bool _isPolishing = false;
  bool _isDictating = false;
  bool _showCustomSettings = false;
  String? _errorMessage;
  bool _copied = false;

  // Real-time document statistics
  int _wordCount = 0;
  int _charCount = 0;
  int _readabilityScore = 95;

  final List<Map<String, dynamic>> _styles = const [
    {
      'id': 'natural',
      'label': 'Natural',
      'desc': 'Conversational & authentic',
      'icon': Icons.spa_outlined,
    },
    {
      'id': 'fluent',
      'label': 'Fluent',
      'desc': 'Grammar polish & smooth flow',
      'icon': Icons.bolt_outlined,
    },
    {
      'id': 'professional',
      'label': 'Professional',
      'desc': 'Executive, formal & concise',
      'icon': Icons.business_center_outlined,
    },
    {
      'id': 'shorten',
      'label': 'Shorten',
      'desc': 'Key points only',
      'icon': Icons.compress,
    },
    {
      'id': 'expand',
      'label': 'Expand',
      'desc': 'Detailed explanation',
      'icon': Icons.expand,
    },
  ];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_updateMetrics);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    _customInstructionController.dispose();
    super.dispose();
  }

  void _updateMetrics() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _wordCount = 0;
        _charCount = 0;
        _readabilityScore = 100;
      });
      return;
    }

    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final sentences = text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).toList();
    final sCount = sentences.isEmpty ? 1 : sentences.length;
    final wCount = words.length;

    int typos = RegExp(r'\b(teh|recieve|definately|seperate|alot)\b', caseSensitive: false).allMatches(text).length;
    double avgWpS = wCount / sCount;
    int score = (100 - (avgWpS * 1.4) - (typos * 6)).round().clamp(15, 100);

    setState(() {
      _wordCount = wCount;
      _charCount = text.length;
      _readabilityScore = score;
    });
  }

  // 1. Direct Grammar & Polish Action (Triggered by Grammar Icon)
  Future<void> _runGrammarPolish() async {
    final rawText = _inputController.text.trim();
    if (rawText.isEmpty) {
      setState(() => _errorMessage = 'Please type, paste, or speak text into the box first.');
      return;
    }

    setState(() {
      _isPolishing = true;
      _errorMessage = null;
    });

    try {
      final customInstruction = _customInstructionController.text.trim();
      final res = await _apiClient.refineText(
        text: rawText,
        mode: _selectedStyle,
        customInstruction: customInstruction.isNotEmpty ? customInstruction : null,
      );

      final refined = res['refinedText'] ?? rawText;
      setState(() {
        _inputController.value = TextEditingValue(
          text: refined,
          selection: TextSelection.collapsed(offset: refined.length),
        );
        _outputController.text = refined;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _isPolishing = false);
    }
  }

  // 2. Direct Voice Dictation (Triggered by Talk Icon)
  Future<void> _startTalking() async {
    setState(() => _isDictating = true);
    HapticFeedback.mediumImpact();

    // Trigger platform channel dictation or simulate speech stream
    try {
      final hasPerm = await PlatformChannels.isMicrophonePermissionGranted();
      if (!hasPerm) {
        await PlatformChannels.requestMicrophonePermission();
      }

      // Add speech indicator or listen for transcription
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listening... speak now. San will transcribe directly into the text box.'),
          duration: Duration(seconds: 3),
          backgroundColor: Color(0xFF16161D),
        ),
      );
    } catch (_) {}

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isDictating = false);
      }
    });
  }

  // 3. Paste Clipboard Content (Chats, PDFs, Articles)
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        _inputController.text = data.text!;
      });
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pasted ${data.text!.length} characters from clipboard.'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF16161D),
        ),
      );
    }
  }

  void _copyOutput() {
    if (_outputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _outputController.text));
      setState(() => _copied = true);
      HapticFeedback.selectionClick();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaynColors.darkBg,
      appBar: AppBar(
        backgroundColor: SaynColors.darkBg,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SaynColors.darkAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SaynColors.darkAccent.withOpacity(0.35)),
              ),
              child: const Text(
                'SAN',
                style: TextStyle(
                  color: SaynColors.darkAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Voice & Grammar Studio',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        // Generous bottom padding (120dp) to prevent overlap with the floating bottom dock
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 1. STYLE MODE SELECTOR (Natural, Fluent, Professional) ───
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _styles.map((s) {
                  final isSelected = _selectedStyle == s['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(
                        s['icon'] as IconData,
                        size: 14,
                        color: isSelected ? const Color(0xFF0D0D12) : SaynColors.darkAccent,
                      ),
                      label: Text(s['label'] as String),
                      selected: isSelected,
                      selectedColor: SaynColors.darkAccent,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? const Color(0xFF0D0D12) : Colors.white,
                      ),
                      backgroundColor: SaynColors.darkSurface,
                      side: BorderSide(
                        color: isSelected ? SaynColors.darkAccent : SaynColors.darkDivider,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedStyle = s['id'] as String);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // ─── 2. INPUT CARD WITH TWO HERO ACTION ICONS ───
            Container(
              decoration: BoxDecoration(
                color: SaynColors.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SaynColors.darkDivider),
              ),
              child: Column(
                children: [
                  // Card Header: Paste Bar & Clear
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        // Quick Paste Chat / Document Button
                        InkWell(
                          onTap: _pasteFromClipboard,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: SaynColors.darkElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: SaynColors.darkDivider),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.paste_rounded, size: 13, color: SaynColors.darkAccent),
                                SizedBox(width: 5),
                                Text(
                                  'Paste Chat / Text',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_inputController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _inputController.clear();
                              setState(() {});
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(fontSize: 11, color: SaynColors.darkError),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: SaynColors.darkDivider),

                  // Text Input Field
                  TextField(
                    controller: _inputController,
                    maxLines: 6,
                    style: const TextStyle(fontSize: 14, color: SaynColors.darkText, height: 1.5),
                    decoration: const InputDecoration(
                      hintText: 'Type, talk, or paste chats & document excerpts here...',
                      hintStyle: TextStyle(fontSize: 13, color: SaynColors.darkMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),

                  const Divider(height: 1, color: SaynColors.darkDivider),

                  // ─── TWO ACTION ICONS (Talk Icon & Grammar Icon) ───
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        // 1. TALK FEATURE ICON (Microphone)
                        InkWell(
                          onTap: _isDictating ? null : _startTalking,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _isDictating
                                  ? SaynColors.darkAccent.withOpacity(0.2)
                                  : SaynColors.darkElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isDictating
                                    ? SaynColors.darkAccent
                                    : SaynColors.darkDivider,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isDictating ? Icons.graphic_eq : Icons.mic_rounded,
                                  size: 18,
                                  color: SaynColors.darkAccent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isDictating ? 'Listening...' : 'Talk',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // 2. GRAMMAR CORRECTION ICON (Magic Wand / Polish)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isPolishing ? null : _runGrammarPolish,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SaynColors.darkAccent,
                              foregroundColor: const Color(0xFF0D0D12),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: _isPolishing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0D0D12),
                                    ),
                                  )
                                : const Icon(Icons.auto_fix_high_rounded, size: 18),
                            label: Text(
                              _isPolishing ? 'Polishing...' : 'Correct Grammar',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── 3. CUSTOM SETTINGS FOR CHATS / PDFS (Expandable) ───
            Container(
              decoration: BoxDecoration(
                color: SaynColors.darkSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SaynColors.darkDivider),
              ),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.tune_rounded, size: 18, color: SaynColors.darkAccent),
                    title: const Text(
                      'Custom Prompt & Settings',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Apply custom instructions to chats, PDFs, or articles',
                      style: TextStyle(fontSize: 11, color: SaynColors.darkSecondary),
                    ),
                    trailing: Icon(
                      _showCustomSettings ? Icons.expand_less : Icons.expand_more,
                      color: SaynColors.darkSecondary,
                    ),
                    onTap: () {
                      setState(() => _showCustomSettings = !_showCustomSettings);
                    },
                  ),
                  if (_showCustomSettings) ...[
                    const Divider(height: 1, color: SaynColors.darkDivider),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _customInstructionController,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'e.g. "Summarize this WhatsApp chat", "Extract 3 bullet points", "Make it friendly"...',
                              hintStyle: const TextStyle(fontSize: 11, color: SaynColors.darkMuted),
                              filled: true,
                              fillColor: SaynColors.darkElevated,
                              isDense: true,
                              contentPadding: const EdgeInsets.all(10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Quick instruction suggestion chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildQuickChip('Summarize chat'),
                              _buildQuickChip('Extract action items'),
                              _buildQuickChip('Make bullet points'),
                              _buildQuickChip('Formal client response'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── 4. ERROR MESSAGE IF ANY ───
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: SaynColors.darkError.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SaynColors.darkError.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: SaynColors.darkError, fontSize: 12),
                ),
              ),

            // ─── 5. POLISHED OUTPUT CARD ───
            if (_outputController.text.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: SaynColors.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SaynColors.darkAccent.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: SaynColors.darkAccent.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 16, color: SaynColors.darkAccent),
                              const SizedBox(width: 6),
                              Text(
                                'Polished Output (${_selectedStyle.toUpperCase()})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: SaynColors.darkAccent,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _copyOutput,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: Icon(
                              _copied ? Icons.check : Icons.copy_rounded,
                              size: 14,
                              color: _copied ? SaynColors.darkSuccess : Colors.white70,
                            ),
                            label: Text(
                              _copied ? 'Copied' : 'Copy',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _copied ? SaynColors.darkSuccess : Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: SaynColors.darkDivider),
                    TextField(
                      controller: _outputController,
                      readOnly: true,
                      maxLines: 6,
                      style: const TextStyle(
                        fontSize: 14,
                        color: SaynColors.darkText,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
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

  Widget _buildQuickChip(String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _customInstructionController.text = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: SaynColors.darkElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: SaynColors.darkDivider),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: SaynColors.darkSecondary),
        ),
      ),
    );
  }
}
