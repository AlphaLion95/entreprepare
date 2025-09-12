import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const _plansKey = 'offline_plans_v1';
  static const _quizAnswersKey = 'offline_quiz_answers_v1';
  static const _quizCompletedKey = 'offline_quiz_completed_v1';
  static const _settingsKey = 'offline_settings_v1';
  static const _favoritesKey = 'offline_favorites_v1';
  static const _aiIdeaCacheKey = 'offline_ai_idea_cache_v1';
  static const _problemSolutionCacheKey = 'offline_problem_solution_cache_v1';

  static Future<SharedPreferences> get _p async =>
      SharedPreferences.getInstance();

  // Plans
  static Future<List<Map<String, dynamic>>> loadPlans() async {
    final prefs = await _p;
    final raw = prefs.getString(_plansKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  static Future<void> savePlans(List<Map<String, dynamic>> plans) async {
    final prefs = await _p;
    await prefs.setString(_plansKey, jsonEncode(plans));
  }

  // Quiz
  static Future<Map<String, dynamic>> loadQuizAnswers() async {
    final prefs = await _p;
    final raw = prefs.getString(_quizAnswersKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> saveQuizAnswers(Map<String, dynamic> answers) async {
    final prefs = await _p;
    await prefs.setString(_quizAnswersKey, jsonEncode(answers));
  }

  static Future<bool> loadQuizCompleted() async {
    final prefs = await _p;
    return prefs.getBool(_quizCompletedKey) ?? false;
  }

  static Future<void> saveQuizCompleted(bool v) async {
    final prefs = await _p;
    await prefs.setBool(_quizCompletedKey, v);
  }

  // Settings
  static Future<Map<String, dynamic>?> loadSettings() async {
    final prefs = await _p;
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await _p;
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }

  // Favorites (saved businesses as simple list of titles)
  static Future<List<String>> loadFavorites() async {
    final prefs = await _p;
    final raw = prefs.getString(_favoritesKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }
    return [];
  }

  static Future<void> saveFavorites(List<String> favs) async {
    final prefs = await _p;
    await prefs.setString(_favoritesKey, jsonEncode(favs));
  }

  // AI idea cache (query -> list of suggestions)
  static Future<Map<String, dynamic>> loadAiIdeaCache() async {
    final prefs = await _p;
    final raw = prefs.getString(_aiIdeaCacheKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return {};
  }

  static Future<void> saveAiIdeaCache(Map<String, dynamic> cache) async {
    final prefs = await _p;
    await prefs.setString(_aiIdeaCacheKey, jsonEncode(cache));
  }

  // Problem solution cache (activity+problem+goal -> list suggestions)
  static Future<Map<String, dynamic>> loadProblemSolutionCache() async {
    final prefs = await _p;
    final raw = prefs.getString(_problemSolutionCacheKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }

  static Future<void> saveProblemSolutionCache(
    Map<String, dynamic> cache,
  ) async {
    final prefs = await _p;
    await prefs.setString(_problemSolutionCacheKey, jsonEncode(cache));
  }
}
