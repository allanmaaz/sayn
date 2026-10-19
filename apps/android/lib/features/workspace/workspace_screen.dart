import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../services/platform_channels.dart';
import '../../services/auth_service.dart';
import '../navigation/sayn_drawer.dart';

class WorkspaceScreen extends StatefulWidget {
  final String? initialStyle;
  final String? initialText;

  const WorkspaceScreen({
    super.key,
    this.initialStyle,
    this.initialText,
  });

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
    if (widget.initialStyle != null) {
      _selectedStyle = widget.initialStyle!;
    }
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _inputController.text = widget.initialText!;
    }
    _inputController.addListener(_updateMetrics);
  }

  @override
  void dispose() {
    if (_isDictating) {
      PlatformChannels.stopDictation();
    }
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

      // Synchronize in real time with Supabase Cloud
      AuthService.instance.uploadWritingHistory(
        text: refined,
        mode: _selectedStyle,
      );
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
    if (_isDictating) {
      await PlatformChannels.stopDictation();
      if (mounted) setState(() => _isDictating = false);
      return;
    }

    final hasPerm = await PlatformChannels.checkAudioPermission();
    if (!hasPerm) {
      await PlatformChannels.requestAudioPermission();
      final hasPermAfter = await PlatformChannels.checkAudioPermission();
      if (!hasPermAfter) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required for voice dictation.'),
              backgroundColor: SaynColors.darkSurface,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isDictating = true);
    HapticFeedback.mediumImpact();

    PlatformChannels.setSpeechListener(
      onPartialResult: (text) {
        if (mounted && text.isNotEmpty) {
          setState(() {
            _inputController.value = TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: text.length),
            );
          });
          _updateMetrics();
        }
      },
      onFinalResult: (text) {
        if (mounted) {
          setState(() {
            _isDictating = false;
            if (text.isNotEmpty) {
              _inputController.value = TextEditingValue(
                text: text,
                selection: TextSelection.collapsed(offset: text.length),
              );
              _updateMetrics();
            }
          });
          // Automatically polish spoken text into final polished output without manual tap
          if (text.trim().isNotEmpty) {
            _runGrammarPolish();
          }
        }
      },
      onEndOfSpeech: () {
        if (mounted) {
          setState(() => _isDictating = false);
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() => _isDictating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              duration: const Duration(seconds: 2),
              backgroundColor: SaynColors.darkSurface,
            ),
          );
        }
      },
    );

    final started = await PlatformChannels.startDictation();
    if (!started && mounted) {
      setState(() => _isDictating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start speech recognizer. Please check microphone settings.'),
          duration: Duration(seconds: 2),
          backgroundColor: SaynColors.darkSurface,
        ),
      );
    }
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
          backgroundColor: SaynColors.darkSurface,
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
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SAYN Studio',
              style: TextStyle(
                fontFamily: 'serif',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: SaynColors.wineMaroon,
              ),
            ),
          ],
        ),
        actions: [
          _buildUserProfileBadge(context),
          const SizedBox(width: 12),
        ],
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
                        size: 15,
                        color: isSelected ? Colors.white : SaynColors.wineMaroon,
                      ),
                      label: Text(s['label'] as String),
                      selected: isSelected,
                      selectedColor: SaynColors.wineMaroon,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : SaynColors.wineMaroon,
                      ),
                      backgroundColor: SaynColors.paperCard,
                      side: BorderSide(
                        color: isSelected ? SaynColors.wineMaroon : SaynColors.paperBorder,
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: SaynColors.paperSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: SaynColors.paperBorder),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.paste_rounded, size: 14, color: SaynColors.wineMaroon),
                                SizedBox(width: 6),
                                Text(
                                  'Paste Chat / Text',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: SaynColors.wineMaroon,
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
                              style: TextStyle(fontSize: 11.5, color: SaynColors.paperTextMuted, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: SaynColors.paperBorder),

                  // Text Input Field
                  TextField(
                    controller: _inputController,
                    maxLines: 6,
                    style: const TextStyle(fontSize: 14.5, color: SaynColors.paperText, height: 1.5),
                    decoration: const InputDecoration(
                      hintText: 'Type, talk, or paste chats & document excerpts here...',
                      hintStyle: TextStyle(fontSize: 13.5, color: SaynColors.paperTextMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),

                  const Divider(height: 1, color: SaynColors.paperBorder),

                  // ─── TWO ACTION ICONS (Talk Icon & Grammar Icon) ───
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // 1. TALK FEATURE ICON (Microphone)
                        InkWell(
                          onTap: _isDictating ? null : _startTalking,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            decoration: BoxDecoration(
                              color: SaynColors.paperSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isDictating
                                    ? SaynColors.wineMaroon
                                    : SaynColors.paperBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isDictating ? Icons.graphic_eq : Icons.mic_rounded,
                                  size: 19,
                                  color: SaynColors.wineMaroon,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isDictating ? 'Listening...' : 'Talk',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: SaynColors.wineMaroon,
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
                              backgroundColor: SaynColors.wineMaroon,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.auto_fix_high_rounded, size: 18),
                            label: Text(
                              _isPolishing ? 'Polishing...' : 'Correct Grammar',
                              style: const TextStyle(
                                fontSize: 13.5,
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
                color: SaynColors.paperCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SaynColors.paperBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.tune_rounded, size: 19, color: SaynColors.wineMaroon),
                    title: const Text(
                      'Custom Prompt & Settings',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: SaynColors.paperText),
                    ),
                    subtitle: const Text(
                      'Apply custom instructions to chats, PDFs, or articles',
                      style: TextStyle(fontSize: 11.5, color: SaynColors.paperTextMuted),
                    ),
                    trailing: Icon(
                      _showCustomSettings ? Icons.expand_less : Icons.chevron_right_rounded,
                      color: SaynColors.paperTextMuted,
                    ),
                    onTap: () {
                      setState(() => _showCustomSettings = !_showCustomSettings);
                    },
                  ),
                  if (_showCustomSettings) ...[
                    const Divider(height: 1, color: SaynColors.paperBorder),
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
                  color: SaynColors.paperCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: SaynColors.wineMaroon.withOpacity(0.4), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: SaynColors.wineMaroon.withOpacity(0.06),
                      blurRadius: 18,
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
                              const Icon(Icons.check_circle_rounded, size: 16, color: SaynColors.wineMaroon),
                              const SizedBox(width: 6),
                              Text(
                                'Polished Output (${_selectedStyle.toUpperCase()})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: SaynColors.wineMaroon,
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
                              color: _copied ? SaynColors.roseMaroon : SaynColors.warmCream,
                            ),
                            label: Text(
                              _copied ? 'Copied' : 'Copy',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _copied ? SaynColors.roseMaroon : SaynColors.warmCream,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: SaynColors.paperBorder),
                    TextField(
                      controller: _outputController,
                      readOnly: true,
                      maxLines: 6,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: SaynColors.paperText,
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

  Widget _buildUserProfileBadge(BuildContext context) {
    final username = AuthService.instance.username;
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'A';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: SaynColors.paperCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SaynColors.paperBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: SaynColors.wineMaroon,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              username,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: SaynColors.paperText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SaynColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final auth = AuthService.instance;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: SaynColors.deepMaroon,
                    child: Text(
                      auth.username.isNotEmpty ? auth.username[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              auth.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: SaynColors.roseMaroon.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: SaynColors.roseMaroon.withOpacity(0.45),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: SaynColors.warmCream,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '@${auth.username} · ${auth.email}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: SaynColors.darkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: SaynColors.darkDivider),
              const SizedBox(height: 12),

              // Supabase Cloud Sync Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SaynColors.darkElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SaynColors.darkDivider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: SaynColors.darkSuccess,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Supabase Cloud Storage',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.supabaseSyncStatus,
                            style: const TextStyle(
                              fontSize: 11,
                              color: SaynColors.darkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sync_rounded, size: 18, color: SaynColors.roseMaroon),
                      onPressed: () async {
                        await auth.syncWithSupabase();
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sign Out Button
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await auth.logout();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: SaynColors.darkError.withOpacity(0.5)),
                  foregroundColor: SaynColors.darkError,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
