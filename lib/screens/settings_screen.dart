import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  bool _isApiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSettings();
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  void _loadCurrentSettings() {
    final settingsProvider = context.read<SettingsProvider>();
    _apiKeyController.text = settingsProvider.apiKey ?? '';
    _baseUrlController.text = settingsProvider.baseUrl;
  }

  void _saveSettings() async {
    final settingsProvider = context.read<SettingsProvider>();
    final chatProvider = context.read<ChatProvider>();
    
    // Сохраняем настройки
    await settingsProvider.setApiKey(_apiKeyController.text.isEmpty ? null : _apiKeyController.text);
    await settingsProvider.setBaseUrl(_baseUrlController.text);
    
    // Синхронизируем настройки с API клиентом
    chatProvider.updateApiSettings(
      _baseUrlController.text,
      _apiKeyController.text.isEmpty ? null : _apiKeyController.text,
    );
    
    // Показываем уведомление об успешном сохранении
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки сохранены'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text(
          'Настройки',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF262626),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Провайдер
              _buildSectionCard(
                title: 'Провайдер AI',
                subtitle: 'Выберите сервис для работы с AI моделями',
                child: Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: settingsProvider.provider,
                          decoration: InputDecoration(
                            labelText: 'Провайдер',
                            labelStyle: const TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF333333),
                          ),
                          dropdownColor: const Color(0xFF333333),
                          style: const TextStyle(color: Colors.white),
                          items: settingsProvider.availableProviders
                              .map((provider) => DropdownMenuItem(
                                    value: provider,
                                    child: Text(provider),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              settingsProvider.setProvider(value);
                              _baseUrlController.text = settingsProvider.baseUrl;
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Описание: ${_getProviderDescription(settingsProvider.provider)}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // API ключ
              _buildSectionCard(
                title: 'API ключ',
                subtitle: 'Введите ваш API ключ для доступа к сервису',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _apiKeyController,
                      obscureText: !_isApiKeyVisible,
                      decoration: InputDecoration(
                        labelText: 'API ключ',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'sk-...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF333333),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isApiKeyVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _isApiKeyVisible = !_isApiKeyVisible;
                            });
                          },
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        // Обновляем настройки при изменении
                        context.read<SettingsProvider>().setApiKey(value.isEmpty ? null : value);
                      },
                      onEditingComplete: () {
                        // Сохраняем настройки при завершении редактирования
                        _saveSettings();
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                          onPressed: () {
                            if (_apiKeyController.text.isNotEmpty) {
                              Clipboard.setData(ClipboardData(text: _apiKeyController.text));
                              _showSnackBar('API ключ скопирован');
                            }
                          },
                          tooltip: 'Копировать',
                        ),
                        IconButton(
                          icon: const Icon(Icons.paste, color: Colors.white70, size: 20),
                          onPressed: () async {
                            final data = await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              _apiKeyController.text = data!.text!;
                              context.read<SettingsProvider>().setApiKey(data.text);
                            }
                          },
                          tooltip: 'Вставить',
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Очистить'),
                          onPressed: () {
                            _apiKeyController.clear();
                            context.read<SettingsProvider>().setApiKey(null);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Базовый URL
              _buildSectionCard(
                title: 'Базовый URL',
                subtitle: 'URL API сервера (обычно устанавливается автоматически)',
                child: TextFormField(
                  controller: _baseUrlController,
                  decoration: InputDecoration(
                    labelText: 'Базовый URL',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'https://api.example.com/v1',
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF333333),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    // Обновляем настройки при изменении
                    context.read<SettingsProvider>().setBaseUrl(value);
                  },
                  onEditingComplete: () {
                    // Сохраняем настройки при завершении редактирования
                    _saveSettings();
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Тема
              _buildSectionCard(
                title: 'Внешний вид',
                subtitle: 'Выберите тему приложения',
                child: Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: settingsProvider.theme,
                          decoration: InputDecoration(
                            labelText: 'Тема',
                            labelStyle: const TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF333333),
                          ),
                          dropdownColor: const Color(0xFF333333),
                          style: const TextStyle(color: Colors.white),
                          items: settingsProvider.availableThemes
                              .map((theme) => DropdownMenuItem(
                                    value: theme,
                                    child: Text(_getThemeDisplayName(theme)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              settingsProvider.setTheme(value);
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Кнопки действий
              ElevatedButton.icon(
                onPressed: () {
                  _saveSettings();
                },
                icon: const Icon(Icons.save),
                label: const Text(
                  'Сохранить настройки',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {
                  _showResetDialog();
                },
                icon: const Icon(Icons.restore),
                label: const Text(
                  'Сбросить настройки',
                  style: TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      color: const Color(0xFF333333),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  String _getProviderDescription(String provider) {
    switch (provider) {
      case 'OpenRouter':
        return 'Популярный агрегатор AI моделей с широким выбором';
      case 'VSEGPT':
        return 'Российский сервис для работы с AI моделями';
      default:
        return 'Неизвестный провайдер';
    }
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'dark':
        return 'Темная';
      case 'light':
        return 'Светлая';
      default:
        return 'Темная';
    }
  }



  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF333333),
          title: const Text(
            'Сброс настроек',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Вы уверены, что хотите сбросить все настройки к значениям по умолчанию?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetSettings();
              },
              child: const Text(
                'Сбросить',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _resetSettings() {
    final settingsProvider = context.read<SettingsProvider>();
    final chatProvider = context.read<ChatProvider>();
    
    settingsProvider.setProvider('OpenRouter');
    settingsProvider.setBaseUrl('https://openrouter.ai/api/v1');
    settingsProvider.setTheme('dark');
    _apiKeyController.clear();
    _baseUrlController.text = 'https://openrouter.ai/api/v1';
    
    // Обновляем настройки в ChatProvider
    chatProvider.updateApiSettings(
      settingsProvider.baseUrl,
      settingsProvider.apiKey,
    );
    
    _showSnackBar('Настройки сброшены');
  }
}
