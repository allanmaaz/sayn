import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../../services/platform_channels.dart';

class ThesaurusSheet extends StatefulWidget {
  final String originalWord;
  final String currentWord;
  final String? partOfSpeech;
  final String? definition;
  final String? phonetic;
  final String? audioUrl;
  final String? example;
  final String? contextualNuance;
  final List<String> synonyms;
  final List<String> antonyms;
  final ValueChanged<String> onSelectSynonym;
  final bool isFrozen;
  final VoidCallback? onToggleFreeze;

  const ThesaurusSheet({
    super.key,
    required this.originalWord,
    required this.currentWord,
    this.partOfSpeech,
    this.definition,
    this.phonetic,
    this.audioUrl,
    this.example,
    this.contextualNuance,
    required this.synonyms,
    this.antonyms = const [],
    required this.onSelectSynonym,
    this.isFrozen = false,
    this.onToggleFreeze,
  });

  @override
  State<ThesaurusSheet> createState() => _ThesaurusSheetState();
}

class _ThesaurusSheetState extends State<ThesaurusSheet> {
  bool _isPlayingAudio = false;
  late bool _isFrozen;

  @override
  void initState() {
    super.initState();
    _isFrozen = widget.isFrozen;
  }

  Future<void> _playPronunciation() async {
    if (_isPlayingAudio) return;
    setState(() => _isPlayingAudio = true);

    try {
      if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        await PlatformChannels.playAudioUrl(widget.audioUrl!);
      } else {
        await PlatformChannels.speakWord(widget.currentWord);
      }
    } finally {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) setState(() => _isPlayingAudio = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: SaynColors.paperBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sheet Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBECE6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: SaynColors.wineMaroon,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dictionary & Thesaurus',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: SaynColors.wineMaroon,
                        ),
                      ),
                      Text(
                        widget.originalWord.toLowerCase() == widget.currentWord.toLowerCase()
                            ? 'Word definition & contextual alternatives'
                            : 'Original: "${widget.originalWord}" • Tap alternative below',
                        style: const TextStyle(fontSize: 12, color: SaynColors.paperTextMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: SaynColors.wineMaroon),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Headword & Definition Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SaynColors.paperCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SaynColors.wineMaroon.withValues(alpha: 0.3), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row with Word, Phonetic, Speaker, and Freeze
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              widget.currentWord,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: SaynColors.wineMaroon,
                              ),
                            ),
                            if (widget.phonetic != null && widget.phonetic!.isNotEmpty)
                              Text(
                                widget.phonetic!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                  color: SaynColors.paperTextMuted,
                                ),
                              ),
                            if (widget.partOfSpeech != null && widget.partOfSpeech!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBECE6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.partOfSpeech!.toLowerCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                    color: SaynColors.wineMaroon,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Speaker Pronunciation Button
                      InkWell(
                        onTap: _playPronunciation,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _isPlayingAudio ? SaynColors.wineMaroon : const Color(0xFFFBECE6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlayingAudio ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                            size: 18,
                            color: _isPlayingAudio ? Colors.white : SaynColors.wineMaroon,
                          ),
                        ),
                      ),

                      if (widget.onToggleFreeze != null) ...[
                        const SizedBox(width: 8),
                        // Freeze Word Button
                        InkWell(
                          onTap: () {
                            setState(() => _isFrozen = !_isFrozen);
                            widget.onToggleFreeze!();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: _isFrozen ? const Color(0xFFE3F2FD) : SaynColors.paperCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isFrozen ? const Color(0xFF1976D2) : SaynColors.paperBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isFrozen ? '❄️ Frozen' : '❄️ Freeze',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _isFrozen ? const Color(0xFF1976D2) : SaynColors.paperTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Definition Text
                  if (widget.definition != null && widget.definition!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: SaynColors.paperBorder),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 15, color: SaynColors.wineMaroon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.definition!,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: SaynColors.paperText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Contextual Nuance
                  if (widget.contextualNuance != null && widget.contextualNuance!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFE082), width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡 ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(
                              widget.contextualNuance!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF6D4C41),
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Example Sentence
                  if (widget.example != null && widget.example!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('“ ', style: TextStyle(fontSize: 16, color: SaynColors.paperTextMuted, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            widget.example!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              color: SaynColors.paperTextMuted,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Alternative Synonyms Section
            const SizedBox(height: 16),
            const Text(
              'Alternative Synonyms',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: SaynColors.wineMaroon,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.synonyms.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SaynColors.paperCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SaynColors.paperBorder),
                ),
                child: const Text(
                  'No additional synonyms found for this word.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: SaynColors.paperTextMuted),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.synonyms.map((syn) {
                  final isSelected = syn.toLowerCase() == widget.currentWord.toLowerCase();
                  return InkWell(
                    onTap: () {
                      widget.onSelectSynonym(syn);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? SaynColors.wineMaroon : SaynColors.paperCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? SaynColors.wineMaroon : SaynColors.paperBorder,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        syn,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : SaynColors.paperText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            // Antonyms Section (if available)
            if (widget.antonyms.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Opposite Antonyms',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: SaynColors.paperTextMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.antonyms.map((ant) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SaynColors.paperCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SaynColors.paperBorder),
                    ),
                    child: Text(
                      ant,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: SaynColors.paperTextMuted,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
