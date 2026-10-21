import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../services/platform_channels.dart';
import '../../services/user_stats_service.dart';
import '../navigation/sayn_drawer.dart';
import 'widgets/synonym_slider.dart';
import 'widgets/freeze_words_sheet.dart';
import 'widgets/thesaurus_sheet.dart';
import 'widgets/grammarly_issues_sheet.dart';
import '../tools/ai_detector_screen.dart';
import '../tools/citation_screen.dart';
import '../../services/personal_dictionary_service.dart';
import '../../services/document_reader_service.dart';
import '../voice/widgets/live_audio_waveform.dart';

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

  // QuillBot Precision Parity Controls
  int _synonymIntensity = 2; // 0=Strict, 1=Low, 2=Standard, 3=High, 4=Max
  List<String> _freezeWords = [];
  List<dynamic> _alternatives = [];
  bool _showSynonymSlider = false;

  // Grammarly Precision Parity Controls
  List<Map<String, dynamic>> _grammarIssues = [];
  String _detectedTone = 'Confident';

  // Real-time document statistics
  int _wordCount = 0;
  int _readabilityScore = 83;

  // Document Upload & Live Audio State
  bool _isExtractingDoc = false;
  ExtractedDocumentResult? _currentDocument;
  double _audioLevel = 0.0;


  @override
  void initState() {
    super.initState();
    _synonymIntensity = 2;
    _freezeWords = [];
    _alternatives = [];
    _showSynonymSlider = false;
    _grammarIssues = [];
    _detectedTone = 'Confident';
    PersonalDictionaryService.instance.init();
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
        synonymIntensity: _synonymIntensity,
        freezeWords: _freezeWords,
        includeAlternatives: true,
        includeGrammarIssues: true,
      );

      final refined = res['refinedText'] ?? rawText;
      final alternatives = res['alternatives'] as List<dynamic>? ?? [];
      final rawIssues = res['issues'] as List<dynamic>? ?? [];
      final issues = rawIssues.map((e) => Map<String, dynamic>.from(e)).toList();

      // Filter out issues where the original text matches personal dictionary
      final dictService = PersonalDictionaryService.instance;
      final filteredIssues = issues.where((iss) {
        final orig = (iss['originalText'] as String? ?? '').trim();
        return !dictService.contains(orig);
      }).toList();

      // Extract detected tone
      String tone = res['tone'] as String? ?? '';
      if (tone.isEmpty) {
        if (_selectedStyle == 'professional') {
          tone = 'Professional';
        } else if (_selectedStyle == 'natural') {
          tone = 'Friendly';
        } else {
          tone = 'Confident';
        }
      } else {
        tone = tone[0].toUpperCase() + tone.substring(1);
      }

      setState(() {
        _inputController.value = TextEditingValue(
          text: refined,
          selection: TextSelection.collapsed(offset: refined.length),
        );
        _outputController.text = refined;
        _alternatives = alternatives;
        _grammarIssues = filteredIssues;
        _detectedTone = tone;
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

  void _openGrammarlyIssuesSheet() {
    if (_grammarIssues.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GrammarlyIssuesSheet(
        initialIssues: _grammarIssues,
        onApplyFix: (orig, repl) {
          final currentText = _outputController.text;
          if (orig.isNotEmpty) {
            final newText = currentText.replaceFirst(orig, repl);
            setState(() {
              _outputController.text = newText;
              _inputController.text = newText;
              _grammarIssues.removeWhere((i) => i['originalText'] == orig);
            });
          }
        },
        onAcceptAll: (acceptedIssues) {
          var currentText = _outputController.text;
          for (final iss in acceptedIssues) {
            final orig = iss['originalText'] as String? ?? '';
            final repl = iss['suggestedReplacement'] as String? ?? '';
            if (orig.isNotEmpty) {
              currentText = currentText.replaceFirst(orig, repl);
            }
          }
          setState(() {
            _outputController.text = currentText;
            _inputController.text = currentText;
            _grammarIssues.clear();
          });
        },
      ),
    );
  }

  void _openFreezeWordsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FreezeWordsSheet(
        initialFreezeWords: _freezeWords,
        onSave: (words) => setState(() => _freezeWords = words),
      ),
    );
  }

  void _openThesaurusForWord(Map<String, dynamic> alt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ThesaurusSheet(
        originalWord: alt['originalWord'] ?? '',
        currentWord: alt['paraphrasedWord'] ?? '',
        partOfSpeech: alt['partOfSpeech'],
        definition: alt['definition'],
        synonyms: (alt['synonyms'] as List?)?.map((e) => e.toString()).toList() ?? [],
        onSelectSynonym: (chosen) {
          final currentText = _outputController.text;
          final oldWord = alt['paraphrasedWord'] ?? '';
          if (oldWord.isNotEmpty) {
            final newText = currentText.replaceFirst(oldWord, chosen);
            setState(() {
              _outputController.text = newText;
              _inputController.text = newText;
              alt['paraphrasedWord'] = chosen;
            });
          }
        },
      ),
    );
  }

  // 1c. Document Upload (PDF, TXT, Markdown)
  Future<void> _uploadDocument() async {
    setState(() => _isExtractingDoc = true);
    try {
      final result = await DocumentReaderService.instance.pickAndExtractDocument();
      if (result != null && mounted) {
        setState(() {
          _currentDocument = result;
          _inputController.text = result.text;
        });
        _updateMetrics();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${result.fileName} (${result.wordCount} words, ${result.pageCount} page${result.pageCount > 1 ? 's' : ''})'),
            duration: const Duration(seconds: 2),
            backgroundColor: SaynColors.wineMaroon,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFC92A2A),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExtractingDoc = false);
      }
    }
  }

  // 2. Direct Voice Dictation (Triggered by Talk Icon)
  Future<void> _startTalking() async {
    if (_isDictating) {
      await PlatformChannels.stopDictation();
      if (mounted) {
        setState(() {
          _isDictating = false;
          _audioLevel = 0.0;
        });
      }
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

    setState(() {
      _isDictating = true;
      _audioLevel = 0.0;
    });
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
            _audioLevel = 0.0;
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
      onAudioLevel: (level) {
        if (mounted && _isDictating) {
          setState(() => _audioLevel = level);
        }
      },
      onEndOfSpeech: () {
        if (mounted) {
          setState(() {
            _isDictating = false;
            _audioLevel = 0.0;
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isDictating = false;
            _audioLevel = 0.0;
          });
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
      setState(() {
        _isDictating = false;
        _audioLevel = 0.0;
      });
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
            const SizedBox(height: 12),

            // ─── 1b. VOCABULARY TOOLBAR (Synonyms, Freeze Words & Tool Shortcuts) ───
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _showSynonymSlider = !_showSynonymSlider),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: _showSynonymSlider ? SaynColors.wineMaroon : SaynColors.paperCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _showSynonymSlider ? SaynColors.wineMaroon : SaynColors.paperBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 13,
                            color: _showSynonymSlider ? Colors.white : SaynColors.wineMaroon,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Synonyms (L$_synonymIntensity)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _showSynonymSlider ? Colors.white : SaynColors.wineMaroon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _openFreezeWordsSheet,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: _freezeWords.isNotEmpty ? const Color(0xFFFBECE6) : SaynColors.paperCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _freezeWords.isNotEmpty ? SaynColors.wineMaroon : SaynColors.paperBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.ac_unit_rounded,
                            size: 13,
                            color: SaynColors.wineMaroon,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _freezeWords.isEmpty ? 'Freeze Words' : 'Frozen (${_freezeWords.length})',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: SaynColors.wineMaroon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'AI Content Detector',
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.radar_rounded, size: 19, color: SaynColors.wineMaroon),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AiDetectorScreen(
                            initialText: _outputController.text.isNotEmpty
                                ? _outputController.text
                                : _inputController.text,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Citation Generator',
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.format_quote_rounded, size: 19, color: SaynColors.wineMaroon),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CitationScreen(
                            initialSource: _inputController.text,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (_showSynonymSlider) ...[
              const SizedBox(height: 8),
              SynonymSlider(
                value: _synonymIntensity,
                onChanged: (lvl) => setState(() => _synonymIntensity = lvl),
              ),
            ],
            const SizedBox(height: 12),

            // ─── 2. MAIN INPUT CARD ───
            Container(
              decoration: BoxDecoration(
                color: SaynColors.paperCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBECE6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.paste_rounded, size: 13, color: SaynColors.wineMaroon),
                                SizedBox(width: 4),
                                Text(
                                  'Paste',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: SaynColors.wineMaroon,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Upload Doc pill button
                        InkWell(
                          onTap: _isExtractingDoc ? null : _uploadDocument,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBECE6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isExtractingDoc)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: SaynColors.wineMaroon,
                                    ),
                                  )
                                else
                                  const Icon(Icons.upload_file_rounded, size: 13, color: SaynColors.wineMaroon),
                                const SizedBox(width: 4),
                                const Text(
                                  'Upload Doc',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: SaynColors.wineMaroon,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$_detectedTone • $_wordCount w • $_readabilityScore%',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: SaynColors.paperTextMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            _inputController.clear();
                            setState(() {
                              _currentDocument = null;
                            });
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: SaynColors.wineMaroon,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: SaynColors.paperBorder),

                  // Optional Document pill banner if loaded
                  if (_currentDocument != null)
                    Container(
                      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: SaynColors.warmCream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: SaynColors.paperBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description_rounded, size: 14, color: SaynColors.wineMaroon),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_currentDocument!.fileName} (${_currentDocument!.fileExtension.toUpperCase()} • ${_currentDocument!.pageCount} pg • ${_currentDocument!.wordCount} w)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: SaynColors.wineMaroon,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentDocument = null;
                              });
                            },
                            child: const Icon(Icons.close_rounded, size: 14, color: SaynColors.paperTextMuted),
                          ),
                        ],
                      ),
                    ),

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
                                backgroundColor: _isDictating ? const Color(0xFFFBECE6) : const Color(0xFFF5EBDD),
                                foregroundColor: SaynColors.wineMaroon,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: _isDictating ? SaynColors.roseMaroon : SaynColors.paperBorder,
                                    width: _isDictating ? 1.5 : 1.0,
                                  ),
                                ),
                              ),
                              child: _isDictating
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        LiveAudioWaveform(
                                          isRecording: true,
                                          audioLevel: _audioLevel,
                                          activeColor: SaynColors.wineMaroon,
                                          height: 20,
                                          barCount: 7,
                                        ),
                                        const SizedBox(width: 5),
                                        const Flexible(
                                          child: Text(
                                            'Listening',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: SaynColors.wineMaroon,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.mic_none_rounded,
                                          color: SaynColors.wineMaroon,
                                          size: 19,
                                        ),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Talk',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: SaynColors.wineMaroon,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                  const Flexible(
                                    child: Text(
                                      'Improve text',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
            const SizedBox(height: 16),

            // ─── 3. GRAMMARLY HYBRID REVIEW BANNER ───
            if (_grammarIssues.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBECE6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: SaynColors.wineMaroon.withValues(alpha: 0.35),
                    width: 1.1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 18, color: SaynColors.wineMaroon),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_grammarIssues.length} Grammarly suggestion${_grammarIssues.length == 1 ? '' : 's'} ready',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: SaynColors.wineMaroon,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openGrammarlyIssuesSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SaynColors.wineMaroon,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        minimumSize: const Size(60, 32),
                      ),
                      icon: const Icon(Icons.checklist_rounded, size: 14),
                      label: const Text(
                        'Review',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ─── 4. IMPROVED TEXT CARD ───
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: SaynColors.paperCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SaynColors.paperBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
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
                        color: SaynColors.paperBorder.withValues(alpha: 0.8),
                      ),
                    ),
                    child: _buildImprovedTextContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovedTextContent() {
    final text = _outputController.text;
    if (text.isEmpty) {
      return const Text(
        'Your polished text will appear here. Tap "Improve text" above.',
        style: TextStyle(
          fontSize: 14.5,
          color: SaynColors.paperTextMuted,
          height: 1.5,
        ),
      );
    }

    if (_alternatives.isEmpty) {
      return SelectableText(
        text,
        style: const TextStyle(
          fontSize: 14.5,
          color: SaynColors.paperText,
          height: 1.5,
        ),
      );
    }

    // Interactive tokenized view:
    // Split into tokens by whitespace
    final tokens = text.split(RegExp(r'\s+'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFBECE6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 14, color: SaynColors.wineMaroon),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Interactive Thesaurus • Tap highlighted words to swap synonyms',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: SaynColors.wineMaroon,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 4,
          runSpacing: 6,
          children: tokens.map((token) {
            if (token.trim().isEmpty) {
              return const SizedBox.shrink();
            }

            final cleanToken = token.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
            final alt = _alternatives.firstWhere(
              (a) => (a['paraphrasedWord'] as String? ?? '').toLowerCase() == cleanToken,
              orElse: () => null,
            );

            if (alt != null && (alt['synonyms'] as List?)?.isNotEmpty == true) {
              return InkWell(
                onTap: () => _openThesaurusForWord(Map<String, dynamic>.from(alt)),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBECE6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: SaynColors.wineMaroon.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Text(
                    token,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: SaynColors.wineMaroon,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dotted,
                      decorationColor: SaynColors.wineMaroon,
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '$token ',
                style: const TextStyle(
                  fontSize: 14.5,
                  color: SaynColors.paperText,
                  height: 1.5,
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
                    color: SaynColors.wineMaroon.withValues(alpha: 0.22),
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
              size: 15,
              color: isSelected ? Colors.white : SaynColors.wineMaroon,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : SaynColors.paperText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
