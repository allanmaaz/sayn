import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../../../services/personal_dictionary_service.dart';

class GrammarlyIssuesSheet extends StatefulWidget {
  final List<Map<String, dynamic>> initialIssues;
  final Function(String originalText, String replacement) onApplyFix;
  final Function(List<Map<String, dynamic>> acceptedIssues) onAcceptAll;

  const GrammarlyIssuesSheet({
    super.key,
    required this.initialIssues,
    required this.onApplyFix,
    required this.onAcceptAll,
  });

  @override
  State<GrammarlyIssuesSheet> createState() => _GrammarlyIssuesSheetState();
}

class _GrammarlyIssuesSheetState extends State<GrammarlyIssuesSheet> {
  late List<Map<String, dynamic>> _issues;
  String _selectedPillar = 'all'; // 'all' | 'correctness' | 'clarity' | 'engagement' | 'delivery'

  @override
  void initState() {
    super.initState();
    _issues = List.from(widget.initialIssues);
  }

  Color _getPillarColor(String pillar) {
    switch (pillar.toLowerCase()) {
      case 'correctness':
        return const Color(0xFFC92A2A); // Red
      case 'clarity':
        return const Color(0xFF1C7ED6); // Blue
      case 'engagement':
        return const Color(0xFF2B8A3E); // Green
      case 'delivery':
        return const Color(0xFF7048E8); // Purple
      default:
        return SaynColors.wineMaroon;
    }
  }

  IconData _getPillarIcon(String pillar) {
    switch (pillar.toLowerCase()) {
      case 'correctness':
        return Icons.spellcheck_rounded;
      case 'clarity':
        return Icons.auto_awesome_rounded;
      case 'engagement':
        return Icons.lightbulb_outline_rounded;
      case 'delivery':
        return Icons.record_voice_over_rounded;
      default:
        return Icons.checklist_rounded;
    }
  }

  List<Map<String, dynamic>> get _filteredIssues {
    if (_selectedPillar == 'all') return _issues;
    return _issues.where((i) => (i['pillar'] as String? ?? '').toLowerCase() == _selectedPillar).toList();
  }

  void _acceptIssue(Map<String, dynamic> issue) {
    final orig = issue['originalText'] as String? ?? '';
    final repl = issue['suggestedReplacement'] as String? ?? '';
    widget.onApplyFix(orig, repl);
    setState(() {
      _issues.remove(issue);
    });
    if (_issues.isEmpty && mounted) {
      Navigator.pop(context);
    }
  }

  void _dismissIssue(Map<String, dynamic> issue) {
    setState(() {
      _issues.remove(issue);
    });
    if (_issues.isEmpty && mounted) {
      Navigator.pop(context);
    }
  }

  void _acceptAll() {
    widget.onAcceptAll(_issues);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: const BoxDecoration(
        color: SaynColors.paperBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBECE6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_rounded,
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
                      'Grammarly Review',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: SaynColors.wineMaroon,
                      ),
                    ),
                    Text(
                      '${_issues.length} suggested enhancement${_issues.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12, color: SaynColors.paperTextMuted),
                    ),
                  ],
                ),
              ),
              if (_issues.isNotEmpty)
                TextButton.icon(
                  onPressed: _acceptAll,
                  style: TextButton.styleFrom(
                    foregroundColor: SaynColors.wineMaroon,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: const Color(0xFFFBECE6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text(
                    'Accept All',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: SaynColors.wineMaroon),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pillar Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPillarFilter('all', 'All (${_issues.length})', SaynColors.wineMaroon),
                const SizedBox(width: 6),
                _buildPillarFilter(
                  'correctness',
                  'Correctness (${_countPillar('correctness')})',
                  const Color(0xFFC92A2A),
                ),
                const SizedBox(width: 6),
                _buildPillarFilter(
                  'clarity',
                  'Clarity (${_countPillar('clarity')})',
                  const Color(0xFF1C7ED6),
                ),
                const SizedBox(width: 6),
                _buildPillarFilter(
                  'engagement',
                  'Engagement (${_countPillar('engagement')})',
                  const Color(0xFF2B8A3E),
                ),
                const SizedBox(width: 6),
                _buildPillarFilter(
                  'delivery',
                  'Delivery (${_countPillar('delivery')})',
                  const Color(0xFF7048E8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: SaynColors.paperBorder),
          const SizedBox(height: 12),

          // Issues List
          Expanded(
            child: _filteredIssues.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 42, color: Color(0xFF2B8A3E)),
                        const SizedBox(height: 10),
                        const Text(
                          'No issues found in this category!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: SaynColors.wineMaroon,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your writing is clean, clear, and well-structured.',
                          style: TextStyle(fontSize: 12, color: SaynColors.paperTextMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredIssues.length,
                    itemBuilder: (context, index) {
                      return _buildIssueCard(_filteredIssues[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  int _countPillar(String p) {
    return _issues.where((i) => (i['pillar'] as String? ?? '').toLowerCase() == p).length;
  }

  Widget _buildPillarFilter(String id, String label, Color color) {
    final isSelected = _selectedPillar == id;
    return InkWell(
      onTap: () => setState(() => _selectedPillar = id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : SaynColors.paperCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : SaynColors.paperBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : SaynColors.paperText,
          ),
        ),
      ),
    );
  }

  Widget _buildIssueCard(Map<String, dynamic> issue) {
    final pillar = (issue['pillar'] as String? ?? 'correctness').toLowerCase();
    final color = _getPillarColor(pillar);
    final icon = _getPillarIcon(pillar);
    final title = issue['title'] as String? ?? 'Suggestion';
    final explanation = issue['explanation'] as String? ?? '';
    final orig = issue['originalText'] as String? ?? '';
    final repl = issue['suggestedReplacement'] as String? ?? '';

    final isSingleWord = !orig.trim().contains(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SaynColors.paperCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaynColors.paperBorder, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pillar & Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      pillar.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: SaynColors.paperText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Replacement Diff Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SaynColors.paperBorder.withValues(alpha: 0.8)),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                if (orig.isNotEmpty)
                  Text(
                    orig,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFFC92A2A),
                      decoration: TextDecoration.lineThrough,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (orig.isNotEmpty && repl.isNotEmpty)
                  const Icon(Icons.arrow_forward_rounded, size: 13, color: SaynColors.paperTextMuted),
                if (repl.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6FCF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      repl,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2B8A3E),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              explanation,
              style: const TextStyle(fontSize: 12, color: SaynColors.paperTextMuted, height: 1.35),
            ),
          ],
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              if (isSingleWord && orig.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await PersonalDictionaryService.instance.addWord(orig);
                    _dismissIssue(issue);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added "$orig" to your personal dictionary.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: SaynColors.paperTextMuted,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 30),
                  ),
                  child: const Text('Add to dictionary', style: TextStyle(fontSize: 11)),
                ),
              const Spacer(),
              // Dismiss
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: SaynColors.paperTextMuted),
                tooltip: 'Dismiss',
                onPressed: () => _dismissIssue(issue),
              ),
              const SizedBox(width: 4),
              // Accept
              ElevatedButton.icon(
                onPressed: () => _acceptIssue(issue),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SaynColors.wineMaroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_rounded, size: 14),
                label: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
