import 'package:shared_preferences/shared_preferences.dart';

class KeywordService {
  static const String _keywordsKey = 'selected_keywords';
  final SharedPreferences _prefs;

  KeywordService(this._prefs);

  Future<List<String>> getSelectedKeywords() async {
    return _prefs.getStringList(_keywordsKey) ?? [];
  }

  Future<void> saveSelectedKeywords(List<String> keywords) async {
    await _prefs.setStringList(_keywordsKey, keywords);
  }

  Future<void> addKeyword(String keyword) async {
    final keywords = await getSelectedKeywords();
    if (!keywords.contains(keyword)) {
      keywords.add(keyword);
      await saveSelectedKeywords(keywords);
    }
  }

  Future<void> removeKeyword(String keyword) async {
    final keywords = await getSelectedKeywords();
    keywords.remove(keyword);
    await saveSelectedKeywords(keywords);
  }

  Future<void> clearKeywords() async {
    await _prefs.remove(_keywordsKey);
  }
} 