import 'package:flutter/cupertino.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';
import '../../../services/yandex_suggest_service_v2.dart';

/// Экран тестирования автозаполнения адресов
/// Используется для разработки и отладки функционала геосаджеста Яндекс.Карт
class AddressAutocompleteTestScreen extends StatefulWidget {
  const AddressAutocompleteTestScreen({super.key});

  @override
  State<AddressAutocompleteTestScreen> createState() =>
      _AddressAutocompleteTestScreenState();
}

class _AddressAutocompleteTestScreenState
    extends State<AddressAutocompleteTestScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final FocusNode _fromFocusNode = FocusNode();
  final FocusNode _toFocusNode = FocusNode();

  // Сервис Яндекс.Геосаджест
  final YandexSuggestService _suggestService = YandexSuggestService();

  // Подсказки для адресов
  List<SuggestItem> _fromSuggestions = [];
  List<SuggestItem> _toSuggestions = [];

  // Показывать ли список подсказок
  bool _showFromSuggestions = false;
  bool _showToSuggestions = false;

  // Индикатор загрузки
  bool _isLoadingFromSuggestions = false;
  bool _isLoadingToSuggestions = false;

  @override
  void initState() {
    super.initState();

    // НЕ инициализируем сервис здесь - он инициализируется при первом запросе
    // _suggestService.initialize(); // Закомментировано!

    // Слушаем изменения в полях ввода
    _fromController.addListener(_onFromChanged);
    _toController.addListener(_onToChanged);

    // Слушаем фокус
    _fromFocusNode.addListener(() {
      setState(() {
        _showFromSuggestions = _fromFocusNode.hasFocus;
      });
    });

    _toFocusNode.addListener(() {
      setState(() {
        _showToSuggestions = _toFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    // _suggestService больше не требует dispose - управляется автоматически
    super.dispose();
  }

  void _onFromChanged() async {
    final query = _fromController.text;
    print('🔍 [FROM] Изменение: "$query"');

    if (query.isEmpty) {
      setState(() {
        _fromSuggestions = [];
        _showFromSuggestions = false;
        _isLoadingFromSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingFromSuggestions = true;
      _showFromSuggestions = true;
    });

    try {
      // Вызов реального API Яндекс.Геосаджест
      final suggestions = await _suggestService.getSuggestions(query: query);

      setState(() {
        _fromSuggestions = suggestions;
        _isLoadingFromSuggestions = false;
      });

      print('✅ [FROM] Получено подсказок: ${suggestions.length}');
    } catch (e) {
      print('❌ [FROM] Ошибка получения подсказок: $e');
      setState(() {
        _fromSuggestions = [];
        _isLoadingFromSuggestions = false;
      });
    }
  }

  void _onToChanged() async {
    final query = _toController.text;
    print('🔍 [TO] Изменение: "$query"');

    if (query.isEmpty) {
      setState(() {
        _toSuggestions = [];
        _showToSuggestions = false;
        _isLoadingToSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingToSuggestions = true;
      _showToSuggestions = true;
    });

    try {
      // Вызов реального API Яндекс.Геосаджест
      final suggestions = await _suggestService.getSuggestions(query: query);

      setState(() {
        _toSuggestions = suggestions;
        _isLoadingToSuggestions = false;
      });

      print('✅ [TO] Получено подсказок: ${suggestions.length}');
    } catch (e) {
      print('❌ [TO] Ошибка получения подсказок: $e');
      setState(() {
        _toSuggestions = [];
        _isLoadingToSuggestions = false;
      });
    }
  }

  void _selectFromSuggestion(SuggestItem suggestion) {
    print('✅ [FROM] Выбрана подсказка: "${suggestion.displayText}"');
    setState(() {
      _fromController.text = suggestion.displayText;
      _showFromSuggestions = false;
    });
    _fromFocusNode.unfocus();
  }

  void _selectToSuggestion(SuggestItem suggestion) {
    print('✅ [TO] Выбрана подсказка: "${suggestion.displayText}"');
    setState(() {
      _toController.text = suggestion.displayText;
      _showToSuggestions = false;
    });
    _toFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text(
          'Автозаполнение адресов',
          style: TextStyle(color: theme.label),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.info_circle, color: theme.primary),
          onPressed: () => _showInfoDialog(theme),
        ),
      ),
      child: SafeArea(
        child: GestureDetector(
          // Закрываем подсказки при клике вне полей
          onTap: () {
            _fromFocusNode.unfocus();
            _toFocusNode.unfocus();
            setState(() {
              _showFromSuggestions = false;
              _showToSuggestions = false;
            });
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Информационная карточка
                _buildInfoCard(theme),

                const SizedBox(height: 24),

                // Поле "Откуда"
                _buildSectionTitle('Откуда', theme),
                _buildAddressFieldWithSuggestions(
                  controller: _fromController,
                  focusNode: _fromFocusNode,
                  placeholder: 'Адрес отправления',
                  icon: CupertinoIcons.location,
                  theme: theme,
                  suggestions: _fromSuggestions,
                  showSuggestions: _showFromSuggestions,
                  onSuggestionTap: _selectFromSuggestion,
                  isLoading: _isLoadingFromSuggestions,
                ),

                const SizedBox(height: 24),

                // Поле "Куда"
                _buildSectionTitle('Куда', theme),
                _buildAddressFieldWithSuggestions(
                  controller: _toController,
                  focusNode: _toFocusNode,
                  placeholder: 'Адрес назначения',
                  icon: CupertinoIcons.location_solid,
                  theme: theme,
                  suggestions: _toSuggestions,
                  showSuggestions: _showToSuggestions,
                  onSuggestionTap: _selectToSuggestion,
                  isLoading: _isLoadingToSuggestions,
                ),

                const SizedBox(height: 24),

                // Кнопка очистки
                CupertinoButton.filled(
                  child: const Text('Очистить всё'),
                  onPressed: () {
                    setState(() {
                      _fromController.clear();
                      _toController.clear();
                      _fromSuggestions = [];
                      _toSuggestions = [];
                      _showFromSuggestions = false;
                      _showToSuggestions = false;
                    });
                  },
                ),

                const SizedBox(height: 60), // Отступ снизу
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(CustomTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.lab_flask,
                color: CupertinoColors.systemBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Тестовый режим',
                  style: TextStyle(
                    color: theme.label,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Экран для разработки и тестирования автозаполнения адресов.\n\n'
            '🔹 Введите название города или адрес\n'
            '🔹 Подсказки загружаются из Yandex Geocoder API\n'
            '🔹 Выберите подсказку из списка\n\n'
            '✅ Используются РЕАЛЬНЫЕ данные из Яндекс.Карт\n'
            '🌐 Онлайн режим - доступны ВСЕ города России',
            style: TextStyle(
              color: theme.secondaryLabel,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, CustomTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: theme.label,
        ),
      ),
    );
  }

  Widget _buildAddressFieldWithSuggestions({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required IconData icon,
    required CustomTheme theme,
    required List<SuggestItem> suggestions,
    required bool showSuggestions,
    required Function(SuggestItem) onSuggestionTap,
    required bool isLoading,
  }) {
    return Column(
      children: [
        // Поле ввода
        Container(
          decoration: BoxDecoration(
            color: theme.secondarySystemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focusNode.hasFocus
                  ? theme.primary
                  : theme.separator.withOpacity(0.2),
              width: focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: CupertinoTextField(
            controller: controller,
            focusNode: focusNode,
            placeholder: placeholder,
            padding: const EdgeInsets.all(16),
            decoration: null,
            style: TextStyle(color: theme.label, fontSize: 16),
            placeholderStyle: TextStyle(
              color: theme.secondaryLabel.withOpacity(0.5),
            ),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(icon, color: theme.primary, size: 20),
            ),
            suffix: controller.text.isNotEmpty
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(
                        CupertinoIcons.clear_circled_solid,
                        color: theme.secondaryLabel,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      controller.clear();
                    },
                  )
                : null,
          ),
        ),

        // Список подсказок
        if (showSuggestions) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: theme.secondarySystemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.separator.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                : suggestions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Ничего не найдено',
                        style: TextStyle(
                          color: theme.secondaryLabel,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: suggestions.length,
                    separatorBuilder: (context, index) => Container(
                      height: 1,
                      color: theme.separator.withOpacity(0.2),
                    ),
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        onPressed: () => onSuggestionTap(suggestion),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.location_fill,
                              color: theme.secondaryLabel,
                              size: 16,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    suggestion.title,
                                    style: TextStyle(
                                      color: theme.label,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (suggestion.subtitle != null &&
                                      suggestion.subtitle!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      suggestion.subtitle!,
                                      style: TextStyle(
                                        color: theme.secondaryLabel,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              CupertinoIcons.arrow_up_left,
                              color: theme.secondaryLabel,
                              size: 16,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }

  void _showInfoDialog(CustomTheme theme) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Яндекс.Геосаджест'),
        content: const Text(
          'Геосаджест - это встроенный функционал API Яндекс.Карт для быстрого ввода и проверки названий организаций и адресов.\n\n'
          'Подсказки появляются автоматически при вводе текста и помогают быстро найти нужный адрес.\n\n'
          'Источник: MapKit SDK от Яндекс',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Понятно'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
