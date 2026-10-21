import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class FreezeWordsSheet extends StatefulWidget {
  final List<String> initialFreezeWords;
  final ValueChanged<List<String>> onSave;

  const FreezeWordsSheet({
    super.key,
    required this.initialFreezeWords,
    required this.onSave,
  });

  @override
  State<FreezeWordsSheet> createState() => _FreezeWordsSheetState();
}

class _FreezeWordsSheetState extends State<FreezeWordsSheet> {
  late List<String> _words;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _words = List.from(widget.initialFreezeWords);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addWord() {
    final term = _inputController.text.trim();
    if (term.isNotEmpty && !_words.contains(term)) {
      setState(() {
        _words.add(term);
        _inputController.clear();
      });
    }
  }

  void _removeWord(String term) {
    setState(() {
      _words.remove(term);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
                  Icons.ac_unit_rounded,
                  color: SaynColors.wineMaroon,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Freeze Words',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: SaynColors.wineMaroon,
                      ),
                    ),
                    Text(
                      'Lock words so SAYN never modifies or translates them',
                      style: TextStyle(fontSize: 12, color: SaynColors.paperTextMuted),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addWord(),
                  style: const TextStyle(fontSize: 14, color: SaynColors.paperText),
                  decoration: InputDecoration(
                    hintText: 'e.g. Supabase, Docker, SAYN...',
                    hintStyle: const TextStyle(fontSize: 13, color: SaynColors.paperTextMuted),
                    filled: true,
                    fillColor: SaynColors.paperCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SaynColors.paperBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SaynColors.paperBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SaynColors.wineMaroon, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addWord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SaynColors.wineMaroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_words.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SaynColors.paperCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SaynColors.paperBorder),
              ),
              child: const Text(
                'No frozen words yet. Type a brand, acronym, or exact phrase above to lock it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: SaynColors.paperTextMuted),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _words.map((term) {
                return Chip(
                  label: Text(
                    term,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: SaynColors.wineMaroon,
                    ),
                  ),
                  backgroundColor: const Color(0xFFFBECE6),
                  side: const BorderSide(color: SaynColors.paperBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  deleteIcon: const Icon(Icons.close_rounded, size: 14, color: SaynColors.wineMaroon),
                  onDeleted: () => _removeWord(term),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              widget.onSave(_words);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SaynColors.wineMaroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'Save (${_words.length} Frozen)',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
