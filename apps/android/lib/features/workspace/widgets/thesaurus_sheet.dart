import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class ThesaurusSheet extends StatelessWidget {
  final String originalWord;
  final String currentWord;
  final String? partOfSpeech;
  final String? definition;
  final List<String> synonyms;
  final ValueChanged<String> onSelectSynonym;

  const ThesaurusSheet({
    super.key,
    required this.originalWord,
    required this.currentWord,
    this.partOfSpeech,
    this.definition,
    required this.synonyms,
    required this.onSelectSynonym,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: SaynColors.paperBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      'Synonym Thesaurus',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: SaynColors.wineMaroon,
                      ),
                    ),
                    Text(
                      'Original: "$originalWord" • Tap an alternative below',
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
          // Currently Selected Word & Dictionary Definition Card
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
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: SaynColors.wineMaroon),
                    const SizedBox(width: 8),
                    Text(
                      currentWord,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: SaynColors.wineMaroon,
                      ),
                    ),
                    if (partOfSpeech != null && partOfSpeech!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBECE6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          partOfSpeech!.toLowerCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: SaynColors.wineMaroon,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SaynColors.paperTextMuted,
                      ),
                    ),
                  ],
                ),
                if (definition != null && definition!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: SaynColors.paperBorder),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 14, color: SaynColors.wineMaroon),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          definition!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: SaynColors.paperText,
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
          const SizedBox(height: 14),
          const Text(
            'Alternative Synonyms',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: SaynColors.wineMaroon,
            ),
          ),
          const SizedBox(height: 8),
          if (synonyms.isEmpty)
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
              children: synonyms.map((syn) {
                final isSelected = syn.toLowerCase() == currentWord.toLowerCase();
                return InkWell(
                  onTap: () {
                    onSelectSynonym(syn);
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
        ],
      ),
    );
  }
}
