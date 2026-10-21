import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/personal_dictionary_service.dart';

class PersonalDictionaryScreen extends StatefulWidget {
  const PersonalDictionaryScreen({super.key});

  @override
  State<PersonalDictionaryScreen> createState() => _PersonalDictionaryScreenState();
}

class _PersonalDictionaryScreenState extends State<PersonalDictionaryScreen> {
  final TextEditingController _addController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    PersonalDictionaryService.instance.init();
  }

  @override
  void dispose() {
    _addController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addWord() {
    final term = _addController.text.trim();
    if (term.isNotEmpty) {
      PersonalDictionaryService.instance.addWord(term);
      _addController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = PersonalDictionaryService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final words = service.wordsList.where((w) {
          if (_searchQuery.isEmpty) return true;
          return w.contains(_searchQuery.toLowerCase());
        }).toList();

        return Scaffold(
          backgroundColor: SaynColors.paperBg,
          appBar: AppBar(
            backgroundColor: SaynColors.paperBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: SaynColors.wineMaroon),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Personal Dictionary',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: SaynColors.wineMaroon,
              ),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Description Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SaynColors.paperCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SaynColors.paperBorder, width: 1.1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: SaynColors.wineMaroon, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Words added here are whitelisted and will never be flagged as typos or grammatical errors.',
                          style: TextStyle(fontSize: 12.5, color: SaynColors.paperText, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Add Word Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addController,
                        onSubmitted: (_) => _addWord(),
                        style: const TextStyle(fontSize: 14, color: SaynColors.paperText),
                        decoration: InputDecoration(
                          hintText: 'Add custom word, acronym, name...',
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

                // Search Bar if word list is larger
                if (service.wordsList.length > 5) ...[
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 13, color: SaynColors.paperText),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: SaynColors.paperTextMuted),
                      hintText: 'Search words...',
                      hintStyle: const TextStyle(fontSize: 13, color: SaynColors.paperTextMuted),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: SaynColors.paperBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: SaynColors.paperBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Word List
                Expanded(
                  child: words.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.spellcheck_rounded, size: 42, color: SaynColors.wineMaroon.withValues(alpha: 0.4)),
                              const SizedBox(height: 10),
                              Text(
                                _searchQuery.isEmpty ? 'Your personal dictionary is empty' : 'No matching words found',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: SaynColors.wineMaroon,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Type above to add company names, slang, or jargon.',
                                style: TextStyle(fontSize: 12, color: SaynColors.paperTextMuted),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: words.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: SaynColors.paperBorder),
                          itemBuilder: (context, idx) {
                            final w = words[idx];
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                title: Text(
                                  w,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: SaynColors.paperText,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFC92A2A)),
                                  onPressed: () => service.removeWord(w),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
