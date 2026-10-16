import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _freezeWordController = TextEditingController();
  final SaynApiClient _apiClient = SaynApiClient();

  String _selectedMode = 'standard';
  double _synonymIntensity = 2.0; // 0 (Exact) to 4 (Max)
  final List<String> _freezeWords = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _copied = false;

  // Grammarly & QuillBot Document Metrics
  int _wordCount = 0;
  int _charCount = 0;
  int _readabilityScore = 85;
  int _correctnessCount = 0;
  int _clarityCount = 0;
  int _engagementCount = 0;
  int _deliveryCount = 0;

  final List<Map<String, String>> _modes = const [
    {'id': 'standard', 'label': 'Standard'},
    {'id': 'fluency', 'label': 'Fluency'},
    {'id': 'formal', 'label': 'Formal'},
    {'id': 'simple', 'label': 'Simple'},
    {'id': 'creative', 'label': 'Creative'},
    {'id': 'shorten', 'label': 'Shorten'},
    {'id': 'expand', 'label': 'Expand'},
  ];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_computeMetrics);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    _freezeWordController.dispose();
    super.dispose();
  }

  void _computeMetrics() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _wordCount = 0;
        _charCount = 0;
        _readabilityScore = 100;
        _correctnessCount = 0;
        _clarityCount = 0;
        _engagementCount = 0;
        _deliveryCount = 0;
      });
      return;
    }

    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final sentences = text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).toList();
    final sCount = sentences.isEmpty ? 1 : sentences.length;
    final wCount = words.length;

    // Fast local heuristic estimation
    int passiveMatches = RegExp(r'\b(is|are|was|were|been)\s+\w+ed\b', caseSensitive: false).allMatches(text).length;
    int hedgeMatches = RegExp(r'\b(maybe|perhaps|probably|somewhat|kind of)\b', caseSensitive: false).allMatches(text).length;
    int typoMatches = RegExp(r'\b(teh|recieve|definately|seperate)\b', caseSensitive: false).allMatches(text).length;

    // Flesch Reading Ease estimate
    double avgWordsPerSentence = wCount / sCount;
    int estimatedScore = (100 - (avgWordsPerSentence * 1.5) - (typoMatches * 5)).round().clamp(10, 100);

    setState(() {
      _wordCount = wCount;
      _charCount = text.length;
      _readabilityScore = estimatedScore;
      _correctnessCount = typoMatches;
      _clarityCount = passiveMatches;
      _engagementCount = hedgeMatches;
      _deliveryCount = (wCount > 80 && avgWordsPerSentence > 22) ? 1 : 0;
    });
  }

  Future<void> _refine() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please enter or dictate text to refine.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.refineText(
        text: text,
        mode: _selectedMode,
        synonymIntensity: _synonymIntensity.round(),
        freezeWords: _freezeWords,
      );
      setState(() {
        _outputController.text = res['refinedText'] ?? '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addFreezeWord() {
    final word = _freezeWordController.text.trim();
    if (word.isNotEmpty && !_freezeWords.contains(word)) {
      setState(() {
        _freezeWords.add(word);
        _freezeWordController.clear();
      });
    }
  }

  void _removeFreezeWord(String word) {
    setState(() {
      _freezeWords.remove(word);
    });
  }

  void _copyOutput() {
    if (_outputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _outputController.text));
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  String _getSynonymLabel(double value) {
    switch (value.round()) {
      case 0:
        return 'Exact (Minimal)';
      case 1:
        return 'Conservative';
      case 2:
        return 'Standard';
      case 3:
        return 'Rich';
      case 4:
        return 'Creative (Maximum)';
      default:
        return 'Standard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaynColors.darkBg,
      appBar: AppBar(
        backgroundColor: SaynColors.darkBg,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: SaynColors.darkAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: SaynColors.darkAccent.withOpacity(0.3)),
              ),
              child: const Text(
                'STUDIO',
                style: TextStyle(
                  color: SaynColors.darkAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Paraphraser & Proofreader',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Selector Pills (QuillBot Modes)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _modes.map((m) {
                  final isSelected = _selectedMode == m['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m['label']!),
                      selected: isSelected,
                      selectedColor: SaynColors.darkAccent,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF0D0D12) : SaynColors.darkSecondary,
                      ),
                      backgroundColor: SaynColors.darkSurface,
                      side: BorderSide(
                        color: isSelected ? SaynColors.darkAccent : SaynColors.darkDivider,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedMode = m['id']!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // QuillBot Synonym Intensity Slider Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SaynColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SaynColors.darkDivider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Synonym Intensity',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: SaynColors.darkText,
                        ),
                      ),
                      Text(
                        _getSynonymLabel(_synonymIntensity),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: SaynColors.darkAccent,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: SaynColors.darkAccent,
                      inactiveTrackColor: SaynColors.darkDivider,
                      thumbColor: SaynColors.darkAccent,
                      overlayColor: SaynColors.darkAccent.withOpacity(0.2),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: _synonymIntensity,
                      min: 0,
                      max: 4,
                      divisions: 4,
                      onChanged: (val) => setState(() => _synonymIntensity = val),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Freeze Words Drawer / Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SaynColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SaynColors.darkDivider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.ac_unit, size: 14, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      const Text(
                        'Freeze Words',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: SaynColors.darkText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_freezeWords.length} pinned',
                        style: const TextStyle(fontSize: 11, color: SaynColors.darkMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_freezeWords.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _freezeWords.map((word) {
                        return Chip(
                          backgroundColor: SaynColors.darkElevated,
                          label: Text(
                            word,
                            style: const TextStyle(fontSize: 11, color: SaynColors.darkText),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 12, color: SaynColors.darkMuted),
                          onDeleted: () => _removeFreezeWord(word),
                          side: const BorderSide(color: SaynColors.darkDivider),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  if (_freezeWords.isNotEmpty) const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _freezeWordController,
                          style: const TextStyle(fontSize: 12, color: SaynColors.darkText),
                          decoration: InputDecoration(
                            hintText: 'Add word to freeze (e.g. SAYN)...',
                            hintStyle: const TextStyle(fontSize: 12, color: SaynColors.darkMuted),
                            filled: true,
                            fillColor: SaynColors.darkElevated,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _addFreezeWord(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.filledStyleFrom(
                          backgroundColor: SaynColors.darkElevated,
                          foregroundColor: SaynColors.darkAccent,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: _addFreezeWord,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Grammarly 4-Pillar Score Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: SaynColors.darkSurface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SaynColors.darkDivider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Overall Score
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: SaynColors.darkAccent, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$_readabilityScore',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: SaynColors.darkAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Doc Score',
                            style: TextStyle(fontSize: 10, color: SaynColors.darkSecondary),
                          ),
                          Text(
                            '$_wordCount words',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: SaynColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // 4 Pillars
                  Row(
                    children: [
                      _buildPillarBadge('🔴', _correctnessCount, 'Correct'),
                      const SizedBox(width: 6),
                      _buildPillarBadge('🔵', _clarityCount, 'Clear'),
                      const SizedBox(width: 6),
                      _buildPillarBadge('🟢', _engagementCount, 'Engage'),
                      const SizedBox(width: 6),
                      _buildPillarBadge('🟣', _deliveryCount, 'Deliver'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Source Input Card
            Container(
              decoration: BoxDecoration(
                color: SaynColors.darkSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SaynColors.darkDivider),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Source Text',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: SaynColors.darkSecondary,
                          ),
                        ),
                        if (_inputController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _inputController.clear();
                              setState(() {});
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(fontSize: 12, color: SaynColors.darkError),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: SaynColors.darkDivider),
                  TextField(
                    controller: _inputController,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 14, color: SaynColors.darkText),
                    decoration: const InputDecoration(
                      hintText: 'Type, paste, or dictate rough thoughts here...',
                      hintStyle: TextStyle(fontSize: 13, color: SaynColors.darkMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Refine Button (Volt Neon Green)
            ElevatedButton(
              onPressed: _isLoading ? null : _refine,
              style: ElevatedButton.styleFrom(
                backgroundColor: SaynColors.darkAccent,
                foregroundColor: const Color(0xFF0D0D12),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFF0D0D12),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Paraphrase & Polish (0ms Groq)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),

            // Error Display
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: SaynColors.darkError.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SaynColors.darkError.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: SaynColors.darkError, fontSize: 12),
                ),
              ),

            // Output Card
            if (_outputController.text.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: SaynColors.darkSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SaynColors.darkAccent.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: SaynColors.darkAccent.withOpacity(0.08),
                      blurRadius: 16,
                      spreadRadius: 2,
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
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 16, color: SaynColors.darkAccent),
                              SizedBox(width: 6),
                              Text(
                                'Polished Output',
                                style: TextStyle(
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
                              _copied ? Icons.check : Icons.copy,
                              size: 14,
                              color: _copied ? SaynColors.darkSuccess : SaynColors.darkSecondary,
                            ),
                            label: Text(
                              _copied ? 'Copied' : 'Copy',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _copied ? SaynColors.darkSuccess : SaynColors.darkSecondary,
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

  Widget _buildPillarBadge(String emoji, int count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: SaynColors.darkElevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 9)),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: SaynColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}
