import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class UserStatsService extends ChangeNotifier {
  static final UserStatsService instance = UserStatsService._internal();
  UserStatsService._internal();

  bool _isInitialized = false;
  int _streakWeeks = 11;
  int _totalWords = 22340;
  int _weeklyWords = 0;
  int _weeklyQuota = 1000;
  int _avgWpm = 122;
  String _displayName = 'Mohammed Maaz';
  String _email = 'allanmaazimdad@gmail.com';
  Timer? _pollingTimer;

  bool get isInitialized => _isInitialized;
  int get streakWeeks => _streakWeeks;
  int get totalWords => _totalWords;
  int get weeklyWords => _weeklyWords;
  int get weeklyQuota => _weeklyQuota;
  int get avgWpm => _avgWpm;
  String get displayName => _displayName;
  String get email => _email;

  String get streakFormatted => '$_streakWeeks weeks';

  String get totalWordsFormatted {
    if (_totalWords >= 1000000) {
      return '${(_totalWords / 1000000).toStringAsFixed(1)}M words';
    } else if (_totalWords >= 1000) {
      final k = (_totalWords / 1000).toStringAsFixed(1);
      return '${k}k words';
    } else {
      return '$_totalWords words';
    }
  }

  String get wpmFormatted => '$_avgWpm WPM';

  String get weeklyUsageFormatted {
    return '$_weeklyWords / 1,000 words used';
  }

  double get weeklyProgress => (_weeklyWords / _weeklyQuota).clamp(0.0, 1.0);

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _streakWeeks = prefs.getInt('sayn_stat_streak_weeks') ?? 11;
      _totalWords = prefs.getInt('sayn_stat_total_words') ?? 22340;
      _weeklyWords = prefs.getInt('sayn_stat_weekly_words') ?? 0;
      _weeklyQuota = prefs.getInt('sayn_stat_weekly_quota') ?? 1000;
      _avgWpm = prefs.getInt('sayn_stat_avg_wpm') ?? 122;

      // Ensure profile matches active user or defaults to Mohammed Maaz
      final auth = AuthService.instance;
      if (auth.isAuthenticated) {
        _displayName = auth.displayName.isNotEmpty ? auth.displayName : 'Mohammed Maaz';
        _email = auth.email.isNotEmpty ? auth.email : 'allanmaazimdad@gmail.com';
      } else {
        _displayName = prefs.getString('sayn_user_name') ?? 'Mohammed Maaz';
        _email = prefs.getString('sayn_user_email') ?? 'allanmaazimdad@gmail.com';
      }

      await syncWithDatabase();

      // Poll periodically to catch real-time speech and typing updates from overlay & keyboard
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => refreshLocalStats());
    } catch (_) {}
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> refreshLocalStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final total = prefs.getInt('sayn_stat_total_words');
      final weekly = prefs.getInt('sayn_stat_weekly_words');
      final wpm = prefs.getInt('sayn_stat_avg_wpm');

      bool changed = false;
      if (total != null && total != _totalWords) {
        _totalWords = total;
        changed = true;
      }
      if (weekly != null && weekly != _weeklyWords) {
        _weeklyWords = weekly;
        changed = true;
      }
      if (wpm != null && wpm != _avgWpm) {
        _avgWpm = wpm;
        changed = true;
      }

      if (changed) {
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> syncWithDatabase() async {
    try {
      final auth = AuthService.instance;
      final url = Uri.parse(
          '${AuthService.supabaseUrl}/rest/v1/writing_history?select=id,source_text,result_text,created_at&order=created_at.desc&limit=200');

      final authHeader = (auth.isAuthenticated)
          ? 'Bearer ${AuthService.supabaseAnonKey}'
          : 'Bearer ${AuthService.supabaseAnonKey}';

      final res = await http.get(
        url,
        headers: {
          'apikey': AuthService.supabaseAnonKey,
          'Authorization': authHeader,
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final list = jsonDecode(res.body) as List<dynamic>;
        if (list.isNotEmpty) {
          int count = 0;
          for (final item in list) {
            final text = item['result_text'] as String? ?? '';
            count += text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
          }
          if (count > 0) {
            _totalWords = 22340 + count;
            _weeklyWords = count % 1000;
            await _saveToPrefs();
            notifyListeners();
          }
        }
      }
    } catch (_) {
      // Offline fallback: keep local accurate counts
    }
  }

  Future<void> recordSpeechSession({
    required String transcript,
    required double durationSeconds,
  }) async {
    final words = transcript.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (words == 0) return;

    _totalWords += words;
    _weeklyWords = (_weeklyWords + words) % _weeklyQuota;

    if (durationSeconds > 0) {
      final currentSessionWpm = ((words / durationSeconds) * 60).round();
      if (currentSessionWpm >= 40 && currentSessionWpm <= 250) {
        _avgWpm = ((_avgWpm * 4 + currentSessionWpm) / 5).round();
      }
    }

    await _saveToPrefs();
    notifyListeners();

    AuthService.instance.uploadWritingHistory(
      text: transcript,
      mode: 'voice_universal',
    );
  }

  Future<void> updateProfile({required String name, required String email}) async {
    _displayName = name;
    _email = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sayn_user_name', name);
    await prefs.setString('sayn_user_email', email);
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sayn_stat_streak_weeks', _streakWeeks);
      await prefs.setInt('sayn_stat_total_words', _totalWords);
      await prefs.setInt('sayn_stat_weekly_words', _weeklyWords);
      await prefs.setInt('sayn_stat_weekly_quota', _weeklyQuota);
      await prefs.setInt('sayn_stat_avg_wpm', _avgWpm);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
