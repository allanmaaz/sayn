import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class SynonymSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const SynonymSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<Map<String, String>> levels = [
    {'title': 'Strict', 'subtitle': 'Minimal edits • Fewest changes'},
    {'title': 'Low', 'subtitle': 'Subtle & conservative tweaks'},
    {'title': 'Standard', 'subtitle': 'Balanced flow & natural phrasing'},
    {'title': 'High', 'subtitle': 'Actively varied & richer vocabulary'},
    {'title': 'Max', 'subtitle': 'Creative re-imagination & maximum diversity'},
  ];

  @override
  Widget build(BuildContext context) {
    final current = levels[value.clamp(0, 4)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SaynColors.paperCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaynColors.paperBorder, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 16,
                color: SaynColors.wineMaroon,
              ),
              const SizedBox(width: 8),
              const Text(
                'Synonym Intensity',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: SaynColors.wineMaroon,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBECE6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  current['title']!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: SaynColors.wineMaroon,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: SaynColors.wineMaroon,
              inactiveTrackColor: SaynColors.paperSurface,
              thumbColor: SaynColors.wineMaroon,
              overlayColor: SaynColors.wineMaroon.withValues(alpha: 0.12),
              trackHeight: 4.0,
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3),
              activeTickMarkColor: SaynColors.warmCream,
              inactiveTickMarkColor: SaynColors.paperBorder,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 4,
              divisions: 4,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fewer edits',
                  style: TextStyle(fontSize: 11, color: SaynColors.paperTextMuted),
                ),
                Text(
                  current['subtitle']!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SaynColors.paperTextMuted,
                  ),
                ),
                const Text(
                  'More diverse',
                  style: TextStyle(fontSize: 11, color: SaynColors.paperTextMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
