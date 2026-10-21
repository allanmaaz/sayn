import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalDictionaryService extends ChangeNotifier {
  static final PersonalDictionaryService instance = PersonalDictionaryService._();
  PersonalDictionaryService._();

  static const String _prefKey = 'sayn_personal_dictionary';
  final Set<String> _words = {};
  bool _initialized = false;

  Set<String> get words => Set.unmodifiable(_words);
  List<String> get wordsList => _words.toList()..sort();

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefKey) ?? [];
      _words.addAll(saved.map((w) => w.trim().toLowerCase()));
      _initialized = true;
      notifyListeners();
    } catch (_) {}
  }

  bool contains(String word) {
    return _words.contains(word.trim().toLowerCase());
  }

  Future<void> addWord(String word) async {
    final cleaned = word.trim().toLowerCase();
    if (cleaned.isEmpty || _words.contains(cleaned)) return;
    _words.add(cleaned);
    notifyListeners();
    await _persist();
  }

  Future<void> removeWord(String word) async {
    final cleaned = word.trim().toLowerCase();
    if (_words.remove(cleaned)) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, _words.toList());
    } catch (_) {}
  }
}
