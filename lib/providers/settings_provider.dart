import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _apiKeyKey = 'api_key';
  static const String _baseUrlKey = 'base_url';
  static const String _providerKey = 'provider';
  static const String _themeKey = 'theme';
  
  String? _apiKey;
  String _baseUrl = 'https://openrouter.ai/api/v1';
  String _provider = 'OpenRouter';
  String _theme = 'dark';
  
  String? get apiKey => _apiKey;
  String get baseUrl => _baseUrl;
  String get provider => _provider;
  String get theme => _theme;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString(_apiKeyKey);
      _baseUrl = prefs.getString(_baseUrlKey) ?? _baseUrl;
      _provider = prefs.getString(_providerKey) ?? _provider;
      _theme = prefs.getString(_themeKey) ?? _theme;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }
  
  Future<void> setApiKey(String? apiKey) async {
    _apiKey = apiKey;
    final prefs = await SharedPreferences.getInstance();
    if (apiKey != null) {
      await prefs.setString(_apiKeyKey, apiKey);
    } else {
      await prefs.remove(_apiKeyKey);
    }
    notifyListeners();
  }

  // Метод для получения текущих настроек в виде Map
  Map<String, dynamic> getCurrentSettings() {
    return {
      'apiKey': _apiKey,
      'baseUrl': _baseUrl,
      'provider': _provider,
      'theme': _theme,
    };
  }
  
  Future<void> setBaseUrl(String baseUrl) async {
    _baseUrl = baseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, baseUrl);
    notifyListeners();
  }
  
  Future<void> setProvider(String provider) async {
    _provider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider);
    
    // Автоматически устанавливаем соответствующий URL
    switch (provider) {
      case 'OpenRouter':
        _baseUrl = 'https://openrouter.ai/api/v1';
        break;
      case 'VSEGPT':
        _baseUrl = 'https://vsetgpt.ru/api/v1';
        break;
      default:
        _baseUrl = 'https://openrouter.ai/api/v1';
    }
    
    await prefs.setString(_baseUrlKey, _baseUrl);
    notifyListeners();
  }
  
  Future<void> setTheme(String theme) async {
    _theme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
    notifyListeners();
  }
  
  List<String> get availableProviders => ['OpenRouter', 'VSEGPT'];
  List<String> get availableThemes => ['dark', 'light'];
}
