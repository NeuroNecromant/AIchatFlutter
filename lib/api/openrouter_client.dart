// Import JSON library
import 'dart:convert';
// Import HTTP client
import 'package:http/http.dart' as http;
// Import Flutter core classes
import 'package:flutter/foundation.dart';
// Import package for working with .env files
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Класс клиента для работы с API OpenRouter
class OpenRouterClient {
  // API ключ для авторизации
  String? _apiKey;
  // Базовый URL API
  String? _baseUrl;
  // Заголовки HTTP запросов
  Map<String, String> _headers = {};

  // Геттеры
  String? get apiKey => _apiKey;
  String? get baseUrl => _baseUrl;

  // Единственный экземпляр класса (Singleton)
  static final OpenRouterClient _instance = OpenRouterClient._internal();

  // Фабричный метод для получения экземпляра
  factory OpenRouterClient() {
    return _instance;
  }

  // Приватный конструктор для реализации Singleton
  OpenRouterClient._internal() {
    // Инициализация клиента с значениями по умолчанию
    _baseUrl = 'https://openrouter.ai/api/v1';
    _updateHeaders();
    
    // Инициализация клиента
    _initializeClient();
  }

  // Метод обновления настроек
  void updateSettings(String baseUrl, String? apiKey) {
    _baseUrl = baseUrl;
    _apiKey = apiKey;
    _updateHeaders();
    
    if (kDebugMode) {
      print('OpenRouterClient settings updated:');
      print('Base URL: $_baseUrl');
      print('API Key: ${_apiKey != null ? '***' : 'null'}');
    }
  }

  // Метод обновления заголовков
  void _updateHeaders() {
    _headers = {
      'Content-Type': 'application/json',
      'X-Title': 'AI Chat Flutter',
    };
    
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _headers['Authorization'] = 'Bearer $_apiKey';
    }
  }

  // Метод инициализации клиента
  void _initializeClient() {
    try {
      if (kDebugMode) {
        print('Initializing OpenRouterClient...');
        print('Base URL: $_baseUrl');
        print('API Key: ${_apiKey != null ? '***' : 'null'}');
      }

      // Проверка наличия базового URL
      if (_baseUrl == null || _baseUrl!.isEmpty) {
        throw Exception('Base URL not found');
      }

      if (kDebugMode) {
        print('OpenRouterClient initialized successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error initializing OpenRouterClient: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // Метод получения списка доступных моделей
  Future<List<Map<String, dynamic>>> getModels() async {
    try {
      // Проверка настроек
      if (_baseUrl == null || _baseUrl!.isEmpty) {
        throw Exception('Base URL not configured');
      }

      // Выполнение GET запроса для получения моделей
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: _headers,
      );

      if (kDebugMode) {
        print('Models response status: ${response.statusCode}');
        print('Models response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Парсинг данных о моделях
        final modelsData = json.decode(response.body);
        if (modelsData['data'] != null) {
          return (modelsData['data'] as List)
              .map((model) => {
                    'id': model['id'] as String,
                    'name': (() {
                      try {
                        return utf8.decode((model['name'] as String).codeUnits);
                      } catch (e) {
                        // Remove invalid UTF-8 characters and try again
                        final cleaned = (model['name'] as String)
                            .replaceAll(RegExp(r'[^\x00-\x7F]'), '');
                        return utf8.decode(cleaned.codeUnits);
                      }
                    })(),
                    'pricing': {
                      'prompt': model['pricing']['prompt'] as String,
                      'completion': model['pricing']['completion'] as String,
                    },
                    'context_length': (model['context_length'] ??
                            model['top_provider']?['context_length'] ??
                            0)
                        .toString(),
                  })
              .toList();
        }
        throw Exception('Invalid API response format');
      } else {
        // Возвращение моделей по умолчанию, если API недоступен
        return _getDefaultModels();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting models: $e');
      }
      // Возвращение моделей по умолчанию в случае ошибки
      return _getDefaultModels();
    }
  }

  // Метод получения моделей по умолчанию
  List<Map<String, dynamic>> _getDefaultModels() {
    if (_baseUrl?.contains('vsegpt.ru') == true) {
      return [
        {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo', 'pricing': {'prompt': '0.000001', 'completion': '0.000002'}, 'context_length': '4096'},
        {'id': 'gpt-4', 'name': 'GPT-4', 'pricing': {'prompt': '0.00003', 'completion': '0.00006'}, 'context_length': '8192'},
        {'id': 'claude-3-sonnet', 'name': 'Claude 3.5 Sonnet', 'pricing': {'prompt': '0.000003', 'completion': '0.000015'}, 'context_length': '200000'},
      ];
    } else {
      return [
        {'id': 'deepseek-coder', 'name': 'DeepSeek', 'pricing': {'prompt': '0.00014', 'completion': '0.00028'}, 'context_length': '16384'},
        {'id': 'claude-3-sonnet', 'name': 'Claude 3.5 Sonnet', 'pricing': {'prompt': '0.000003', 'completion': '0.000015'}, 'context_length': '200000'},
        {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo', 'pricing': {'prompt': '0.0000015', 'completion': '0.000002'}, 'context_length': '16385'},
      ];
    }
  }

  // Метод отправки сообщения через API
  Future<Map<String, dynamic>> sendMessage(String message, String model) async {
    try {
      // Проверка настроек
      if (_baseUrl == null || _baseUrl!.isEmpty) {
        throw Exception('Base URL not configured');
      }
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('API key not configured');
      }

      // Подготовка данных для отправки
      // Безопасное чтение настроек из .env (если пакет не инициализирован, берем значения по умолчанию)
      final int maxTokens = (() {
        try {
          final value = dotenv.env['MAX_TOKENS'];
          return int.tryParse(value ?? '') ?? 1000;
        } catch (_) {
          return 1000;
        }
      })();

      final double temperature = (() {
        try {
          final value = dotenv.env['TEMPERATURE'];
          return double.tryParse(value ?? '') ?? 0.7;
        } catch (_) {
          return 0.7;
        }
      })();

      final data = {
        'model': model, // Модель для генерации ответа
        'messages': [
          {'role': 'user', 'content': message} // Сообщение пользователя
        ],
        'max_tokens': maxTokens, // Максимальное количество токенов
        'temperature': temperature, // Температура генерации
        'stream': false, // Отключение потоковой передачи
      };

      if (kDebugMode) {
        print('Sending message to API: ${json.encode(data)}');
      }

      // Выполнение POST запроса
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _headers,
        body: json.encode(data),
      );

      if (kDebugMode) {
        print('Message response status: ${response.statusCode}');
        print('Message response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Успешный ответ
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData;
      } else {
        // Обработка ошибки
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        return {
          'error': errorData['error']?['message'] ?? 'Unknown error occurred'
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      return {'error': e.toString()};
    }
  }

  // Метод получения текущего баланса
  Future<String> getBalance() async {
    try {
      // Проверка настроек
      if (_baseUrl == null || _baseUrl!.isEmpty) {
        throw Exception('Base URL not configured');
      }
      if (_apiKey == null || _apiKey!.isEmpty) {
        return _baseUrl!.contains('vsegpt.ru') ? '0.00₽' : '\$0.00';
      }

      // Выполнение GET запроса для получения баланса
      final response = await http.get(
        Uri.parse(_baseUrl!.contains('vsegpt.ru') == true
            ? '$_baseUrl/balance'
            : '$_baseUrl/credits'),
        headers: _headers,
      );

      if (kDebugMode) {
        print('Balance response status: ${response.statusCode}');
        print('Balance response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Парсинг данных о балансе
        final data = json.decode(response.body);
        if (data != null && data['data'] != null) {
          if (_baseUrl!.contains('vsegpt.ru') == true) {
            final credits =
                double.tryParse(data['data']['credits'].toString()) ??
                    0.0; // Доступно средств
            return '${credits.toStringAsFixed(2)}₽'; // Расчет доступного баланса
          } else {
            final credits = data['data']['total_credits'] ?? 0; // Общие кредиты
            final usage =
                data['data']['total_usage'] ?? 0; // Использованные кредиты
            return '\$${(credits - usage).toStringAsFixed(2)}'; // Расчет доступного баланса
          }
        }
      }
      return _baseUrl!.contains('vsegpt.ru') == true
          ? '0.00₽'
          : '\$0.00'; // Возвращение нулевого баланса по умолчанию
    } catch (e) {
      if (kDebugMode) {
        print('Error getting balance: $e');
      }
      return 'Error'; // Возвращение ошибки в случае исключения
    }
  }

  // Метод форматирования цен
  String formatPricing(double pricing) {
    try {
      if (_baseUrl?.contains('vsegpt.ru') == true) {
        return '${pricing.toStringAsFixed(3)}₽/K';
      } else {
        return '\$${(pricing * 1000000).toStringAsFixed(3)}/M';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error formatting pricing: $e');
      }
      return '0.00';
    }
  }
}
