import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class StatsProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  Map<String, Map<String, dynamic>> _modelStats = {};
  List<Map<String, dynamic>> _dailyExpenses = [];
  List<Map<String, dynamic>> _monthlyExpenses = [];
  
  Map<String, Map<String, dynamic>> get modelStats => _modelStats;
  List<Map<String, dynamic>> get dailyExpenses => _dailyExpenses;
  List<Map<String, dynamic>> get monthlyExpenses => _monthlyExpenses;
  
  StatsProvider() {
    _loadStats();
  }
  
  Future<void> _loadStats() async {
    try {
      await _loadModelStats();
      await _loadDailyExpenses();
      await _loadMonthlyExpenses();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }
  
  Future<void> _loadModelStats() async {
    try {
      final messages = await _db.getMessages();
      final stats = <String, Map<String, dynamic>>{};
      
      for (final message in messages) {
        if (message.modelId != null && message.tokens != null && message.cost != null) {
          if (!stats.containsKey(message.modelId)) {
            stats[message.modelId!] = {
              'name': message.modelId,
              'totalMessages': 0,
              'totalTokens': 0,
              'totalCost': 0.0,
              'avgTokensPerMessage': 0.0,
              'avgCostPerMessage': 0.0,
            };
          }
          
          stats[message.modelId!]!['totalMessages'] = 
              (stats[message.modelId!]!['totalMessages'] as int) + 1;
          stats[message.modelId!]!['totalTokens'] = 
              (stats[message.modelId!]!['totalTokens'] as int) + message.tokens!;
          stats[message.modelId!]!['totalCost'] = 
              (stats[message.modelId!]!['totalCost'] as double) + message.cost!;
        }
      }
      
      // Вычисляем средние значения
      for (final entry in stats.entries) {
        final data = entry.value;
        final totalMessages = data['totalMessages'] as int;
        final totalTokens = data['totalTokens'] as int;
        final totalCost = data['totalCost'] as double;
        
        data['avgTokensPerMessage'] = totalMessages > 0 ? totalTokens / totalMessages : 0.0;
        data['avgCostPerMessage'] = totalMessages > 0 ? totalCost / totalMessages : 0.0;
      }
      
      _modelStats = stats;
    } catch (e) {
      debugPrint('Error loading model stats: $e');
    }
  }
  
  Future<void> _loadDailyExpenses() async {
    try {
      final messages = await _db.getMessages();
      final dailyMap = <String, double>{};
      
      for (final message in messages) {
        if (message.cost != null) {
          final date = DateFormat('yyyy-MM-dd').format(message.timestamp);
          dailyMap[date] = (dailyMap[date] ?? 0.0) + message.cost!;
        }
      }
      
      _dailyExpenses = dailyMap.entries.map((entry) => {
        'date': entry.key,
        'cost': entry.value,
        'formattedDate': DateFormat('dd.MM').format(DateFormat('yyyy-MM-dd').parse(entry.key)),
      }).toList();
      
      // Сортируем по дате
      _dailyExpenses.sort((a, b) => a['date'].compareTo(b['date']));
    } catch (e) {
      debugPrint('Error loading daily expenses: $e');
    }
  }
  
  Future<void> _loadMonthlyExpenses() async {
    try {
      final messages = await _db.getMessages();
      final monthlyMap = <String, double>{};
      
      for (final message in messages) {
        if (message.cost != null) {
          final date = DateFormat('yyyy-MM').format(message.timestamp);
          monthlyMap[date] = (monthlyMap[date] ?? 0.0) + message.cost!;
        }
      }
      
      _monthlyExpenses = monthlyMap.entries.map((entry) => {
        'month': entry.key,
        'cost': entry.value,
        'formattedMonth': DateFormat('MMM yyyy').format(DateFormat('yyyy-MM').parse(entry.key)),
      }).toList();
      
      // Сортируем по месяцу
      _monthlyExpenses.sort((a, b) => a['month'].compareTo(b['month']));
    } catch (e) {
      debugPrint('Error loading monthly expenses: $e');
    }
  }
  
  Future<void> refreshStats() async {
    await _loadStats();
  }
  
  double get totalCost {
    return _modelStats.values.fold(0.0, (sum, stats) => sum + (stats['totalCost'] as double));
  }
  
  int get totalTokens {
    return _modelStats.values.fold(0, (sum, stats) => sum + (stats['totalTokens'] as int));
  }
  
  int get totalMessages {
    return _modelStats.values.fold(0, (sum, stats) => sum + (stats['totalMessages'] as int));
  }
  
  String get totalCostFormatted {
    return totalCost < 0.001 ? '<\$0.001' : '\$${totalCost.toStringAsFixed(3)}';
  }

  // Метод для форматирования стоимости с учетом провайдера
  String formatCost(double cost, String provider) {
    if (provider == 'VSEGPT') {
      return cost < 0.001 ? '<0.001₽' : '${cost.toStringAsFixed(3)}₽';
    } else {
      return cost < 0.001 ? '<\$0.001' : '\$${cost.toStringAsFixed(3)}';
    }
  }

  // Метод для получения символа валюты
  String getCurrencySymbol(String provider) {
    return provider == 'VSEGPT' ? '₽' : '\$';
  }
}
