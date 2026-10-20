import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../services/platform_channels.dart';
import '../../services/user_stats_service.dart';
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
  final SaynApiClient _apiClient = SaynApiClient();

  // Primary styles requested by user
  String _selectedStyle = 'professional'; // 'natural' | 'fluent' | 'professional'
  bool _isPolishing = false;
  bool _isDictating = false;
  bool _copied = false;

  // Real-time document statistics
  int _wordCount = 0;
  int _readabilityScore = 83;


  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.initialStyle ?? 'professional';
    final defaultSample =
        'The product description states it includes 100 papers, but I only received 60. I kindly request a refund or a replacement for the missing items';
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _inputController.text = widget.initialText!;
      _outputController.text = widget.initialText!;
    } else {
      _inputController.text = defaultSample;
      _outputController.text = defaultSample;
    }
    _inputController.addListener(_updateMetrics);
    _updateMetrics();
  }

  @override
  void didUpdateWidget(covariant WorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != null && widget.initialText != oldWidget.initialText) {
      _inputController.value = TextEditingValue(
        text: widget.initialText!,
        selection: TextSelection.collapsed(offset: widget.initialText!.length),
      );
      _updateMetrics();
    }
    if (widget.initialStyle != null && widget.initialStyle != oldWidget.initialStyle) {
      setState(() {
        _selectedStyle = widget.initialStyle!;
      });
    }
  }

  @override
  void dispose() {
    if (_isDictating) {
      PlatformChannels.stopDictation();
    }
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  void _updateMetrics() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _wordCount = 0;
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
      _readabilityScore = score;
    });
  }

  // 1. Direct Grammar & Polish Action (Triggered by Grammar Icon)
  Future<void> _runGrammarPolish() async {
    final rawText = _inputController.text.trim();
    if (rawText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please type, paste, or speak text into the box first.'),
            backgroundColor: SaynColors.wineMaroon,
          ),
        );
      }
      return;
    }

    setState(() => _isPolishing = true);

    try {
      final res = await _apiClient.refineText(
        text: rawText,
        mode: _selectedStyle,
      );

      final refined = res['refinedText'] ?? rawText;
      setState(() {
        _inputController.value = TextEditingValue(
          text: refined,
          selection: TextSelection.collapsed(offset: refined.length),
        );
        _outputController.text = refined;
      });

      // Synchronize in real time with UserStatsService and Supabase
      UserStatsService.instance.recordPolishedText(
        sourceText: rawText,
        resultText: refined,
        mode: _selectedStyle,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: SaynColors.wineMaroon,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPolishing = false);
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
        actions: const [
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        // Generous bottom padding (120dp) to prevent overlap with the floating bottom dock
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 1. 3 MODE PILLS (Natural, Fluent, Professional) ───
            Row(
              children: [
                Expanded(
                  flex: 10,
                  child: _buildModePill('natural', 'Natural', Icons.spa_outlined),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 9,
                  child: _buildModePill('fluent', 'Fluent', Icons.bolt_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 14,
                  child: _buildModePill('professional', 'Professional', Icons.business_center_outlined),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ─── 2. MAIN INPUT CARD ───
            Container(
              decoration: BoxDecoration(
                color: SaynColors.paperCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Card Header: Paste text, Stats & Clear
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        // Paste text pill button
                        InkWell(
                          onTap: _pasteFromClipboard,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBECE6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.paste_rounded, size: 14, color: SaynColors.wineMaroon),
                                SizedBox(width: 6),
                                Text(
                                  'Paste text',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: SaynColors.wineMaroon,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$_wordCount words • $_readabilityScore% flow',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: SaynColors.paperTextMuted,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            _inputController.clear();
                            setState(() {});
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: SaynColors.wineMaroon,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: SaynColors.paperBorder),

                  // Text Input Area
                  TextField(
                    controller: _inputController,
                    maxLines: 6,
                    minLines: 4,
                    style: const TextStyle(
                      fontSize: 15,
                      color: SaynColors.paperText,
                      height: 1.45,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Start typing or paste your text here...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: SaynColors.paperTextMuted,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),

                  // Action Buttons Inside Card
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // 1. TALK BUTTON
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _startTalking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF5EBDD),
                                foregroundColor: SaynColors.wineMaroon,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(color: SaynColors.paperBorder),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isDictating ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
                                    color: SaynColors.wineMaroon,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isDictating ? 'Listening...' : 'Talk',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: SaynColors.wineMaroon,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // 2. IMPROVE TEXT BUTTON
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _isPolishing ? null : _runGrammarPolish,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SaynColors.wineMaroon,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _isPolishing
                                      ? const SizedBox(
                                          width: 15,
                                          height: 15,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 17,
                                          color: Colors.white,
                                        ),
                                  const SizedBox(width: 7),
                                  const Text(
                                    'Improve text',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ],
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

            // ─── 4. IMPROVED TEXT CARD ───
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: SaynColors.paperCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
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
                        'Improved text',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: SaynColors.paperText,
                        ),
                      ),
                      GestureDetector(
                        onTap: _copyOutput,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _copied ? Icons.check_rounded : Icons.copy_rounded,
                              size: 16,
                              color: SaynColors.wineMaroon,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _copied ? 'Copied' : 'Copy',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: SaynColors.wineMaroon,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F6F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: SaynColors.paperBorder.withOpacity(0.8),
                      ),
                    ),
                    child: SelectableText(
                      _outputController.text.isNotEmpty
                          ? _outputController.text
                          : 'Your polished text will appear here. Tap "Improve text" above.',
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: SaynColors.paperText,
                        height: 1.5,
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

  Widget _buildModePill(String id, String label, IconData icon) {
    final isSelected = _selectedStyle == id;
    return InkWell(
      onTap: () => setState(() => _selectedStyle = id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? SaynColors.wineMaroon : SaynColors.paperCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? SaynColors.wineMaroon : SaynColors.paperBorder,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SaynColors.wineMaroon.withOpacity(0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : SaynColors.wineMaroon,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : SaynColors.paperText,
              ),
              maxLines: 1,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}
