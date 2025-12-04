import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' hide Icon, TextStyle;
import 'package:yandex_maps_mapkit/search.dart';
import '../services/yandex_search_service.dart';

/// Упрощенный автокомплит для админ панели
class SimpleAddressField extends StatefulWidget {
  final String label;
  final String? initialValue;
  final Function(String address) onAddressSelected;

  const SimpleAddressField({
    super.key,
    required this.label,
    required this.onAddressSelected,
    this.initialValue,
  });

  @override
  State<SimpleAddressField> createState() => _SimpleAddressFieldState();
}

class _SimpleAddressFieldState extends State<SimpleAddressField> {
  late final TextEditingController _controller;
  SearchSuggestSession? _suggestSession;
  SearchSuggestSessionSuggestListener? _suggestListener;
  
  Timer? _debounceTimer;
  final List<SuggestItem> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    
    print('🔧 SimpleAddressField.initState() начинается...');
    
    // ✅ НОВЫЙ КОД: Используем глобальный YandexSearchService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeYandexSearchServices();
    });
  }

  Future<void> _initializeYandexSearchServices() async {
    try {
      print('🔧 Инициализация SimpleAddressField...');
      
      // Проверяем, что widget все еще mounted
      if (!mounted) {
        print('⚠️ Widget был unmounted, прерываем инициализацию');
        return;
      }
      
      // ✅ Получаем SuggestSession из глобального сервиса
      _suggestSession = YandexSearchService.instance.createSuggestSession();
      print('✅ SuggestSession получен из YandexSearchService: $_suggestSession');
      
      _suggestListener = SearchSuggestSessionSuggestListener(
        onResponse: _onSuggestResponse,
        onError: _onSuggestError,
      );
      print('✅ SuggestListener создан: $_suggestListener');
      
      _isInitialized = true;
      print('🎉 SimpleAddressField инициализирован успешно!');
    } catch (e, stackTrace) {
      print('❌ Ошибка инициализации SimpleAddressField: $e');
      print('   Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    // _suggestSession не имеет метода close, просто освобождаем ресурсы
    super.dispose();
  }

  void _fetchSuggestions(String query) {
    print('🔎 _fetchSuggestions вызван с query: "$query"');
    
    if (!mounted) {
      print('❌ Widget не mounted, прерываем');
      return;
    }
    
    if (query.length < 3) {
      print('❌ Query слишком короткий (${query.length} символов), прерываем');
      return;
    }

    // Проверяем, что все сервисы инициализированы
    if (!_isInitialized || _suggestSession == null || _suggestListener == null) {
      print('❌ Yandex сервисы еще не инициализированы, пропускаем запрос');
      return;
    }
    
    print('🔧 Начинаем suggest запрос...');
    setState(() {
      _isSearching = true;
    });

    try {
      final boundingBox = BoundingBox(
        const Point(latitude: 41.0, longitude: 19.0),
        const Point(latitude: 82.0, longitude: 180.0),
      );
      print('📦 BoundingBox: SW(41.0, 19.0) NE(82.0, 180.0)');

      final options = SuggestOptions(
        suggestTypes: SuggestType(
          SuggestType.Geo.value | SuggestType.Biz.value | SuggestType.Transit.value,
        ),
      );
      print('⚙️ SuggestOptions: suggestTypes = ${options.suggestTypes.value}');

      print('🚀 Вызываем _suggestSession.suggest()...');
      print('🔧 Параметры: text="$query", listener=$_suggestListener');
      _suggestSession!.suggest(
        boundingBox,
        options,
        _suggestListener!,
        text: query,
      );
      print('✅ _suggestSession.suggest() вызван успешно, ожидаем callback...');
    } catch (e, stackTrace) {
      print('❌ Ошибка в _fetchSuggestions: $e');
      print('   Stack trace: $stackTrace');
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _onSuggestResponse(SuggestResponse response) {
    if (!mounted) return;
    
    print('✅✅✅ SimpleAddressField: CALLBACK FIRED! получено ${response.items.length} подсказок');
    print('📋 SimpleAddressField исходные подсказки:');
    for (int i = 0; i < response.items.length && i < 3; i++) {
      final item = response.items[i];
      print('   [${i+1}] ${item.displayText}');
    }
    
    // 🎯 Применяем интеллектуальную сортировку для улучшения релевантности
    List<SuggestItem> sortedItems = _prioritizeSuggestions(response.items, _controller.text);
    
    setState(() {
      _suggestions.clear();
      _suggestions.addAll(sortedItems.take(5));
      _isSearching = false;
      _showSuggestions = true;
    });
    
    print('🎯 SimpleAddressField состояние обновлено: ${_suggestions.length} подсказок после приоритизации');
    print('🏆 ТОП-3 приоритизированных результата:');
    for (int i = 0; i < math.min(3, _suggestions.length); i++) {
      final item = _suggestions[i];
      print('   [${i+1}] ${item.displayText} (${_getLocationTypeFromItem(item)})');
    }
  }

  void _onSuggestError(dynamic error) {
    if (!mounted) return;
    
    print('❌❌❌ SimpleAddressField ERROR CALLBACK FIRED! ошибка: $error');
    print('❌ Тип ошибки: ${error.runtimeType}');
    print('❌ Детали ошибки: $error');
    
    setState(() {
      _suggestions.clear();
      _isSearching = false;
      _showSuggestions = false;
    });
  }

  void _selectSuggestion(SuggestItem suggestion) {
    final address = suggestion.displayText ?? '';
    _controller.text = address;
    widget.onAddressSelected(address);
    
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: _controller,
          placeholder: widget.label,
          padding: const EdgeInsets.all(12),
          onChanged: (text) {
            _debounceTimer?.cancel();
            if (text.length >= 3) {
              _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                _fetchSuggestions(text);
              });
            } else {
              setState(() {
                _showSuggestions = false;
              });
            }
          },
          suffix: _isSearching 
            ? const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CupertinoActivityIndicator(),
                ),
              )
            : null,
        ),
        
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CupertinoColors.systemGrey4,
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  onPressed: () => _selectSuggestion(suggestion),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      suggestion.displayText ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// 🎯 Интеллектуальная приоритизация предложений для улучшения релевантности
  List<SuggestItem> _prioritizeSuggestions(List<SuggestItem> items, String query) {
    if (items.isEmpty || query.isEmpty) return items;
    
    final cleanQuery = query.toLowerCase().trim();
    print('🎯 Приоритизация ${items.length} предложений для запроса: "$cleanQuery"');
    
    // Создаем список с весами релевантности
    List<_WeightedSuggestion> weightedItems = items.map((item) {
      final weight = _calculateRelevanceWeight(item, cleanQuery);
      return _WeightedSuggestion(item, weight);
    }).toList();
    
    // Сортируем по весу (больший вес = выше приоритет)
    weightedItems.sort((a, b) => b.weight.compareTo(a.weight));
    
    print('📊 Результаты приоритизации:');
    for (int i = 0; i < math.min(5, weightedItems.length); i++) {
      final weighted = weightedItems[i];
      print('   [${i+1}] ${weighted.item.displayText} (вес: ${weighted.weight}, тип: ${_getLocationTypeFromItem(weighted.item)})');
    }
    
    return weightedItems.map((w) => w.item).toList();
  }

  /// 🔢 Расчет веса релевантности для предложения
  double _calculateRelevanceWeight(SuggestItem item, String query) {
    double weight = 0.0;
    
    final displayText = item.displayText?.toLowerCase() ?? '';
    final title = _extractPlainTitle(item.title).toLowerCase();
    final locationType = _getLocationTypeFromItem(item);
    
    // 1. Точное слово (token) совпадение — если одно из слов в названии равно запросу
    //    Это важный сигнал для населённых пунктов: "посёлок Кын" -> слово "кын" === запрос
    final words = title.split(RegExp(r'[^\p{L}\d]+', unicode: true)).where((w) => w.isNotEmpty).toList();
    if (words.any((w) => w == query)) {
      weight += 900.0;
      print('   🎯 Точное слово в названии: words=$words содержит "$query" (+900)');
    }
    // 2. Полное совпадение всей title
    else if (title == query) {
      weight += 800.0;
      print('   🎯 Полное совпадение: "$title" = "$query" (+800)');
    }
    // 3. Начинается с запроса (например: Кыновский) — меньший приоритет, т.к. это может быть улица
    else if (title.startsWith(query)) {
      weight += 300.0;
      print('   🔥 Начинается с запроса: "$title" startsWith "$query" (+300)');
    }
    // 4. Содержит запрос в подстроке — самый слабый сигнал
    else if (title.contains(query)) {
      weight += 100.0;
      print('   ✨ Содержит запрос: "$title" contains "$query" (+100)');
    }
    
    // 4. Бонусы за тип локации (города/села важнее рек/улиц)
    switch (locationType) {
      case 'город':
      case 'посёлок':
      case 'село':
      case 'деревня':
        weight += 300.0;
        print('   🏘️ Населенный пункт: $locationType (+300)');
        break;
      case 'станция':
      case 'достопримечательность':
        weight += 200.0;
        print('   🚉 Важный объект: $locationType (+200)');
        break;
      case 'река':
      case 'озеро':
      case 'ручей':
        weight += 50.0;
        print('   🌊 Водный объект: $locationType (+50)');
        break;
      case 'улица':
      case 'переулок':
      case 'проспект':
        weight += 10.0;
        print('   🛣️ Улица: $locationType (+10)');
        break;
    }
    
    // 5. Бонус за краткость (короткие названия обычно более точные)
    if (title.length <= query.length + 2) {
      weight += 50.0;
      print('   📏 Краткое название (+50)');
    }
    
    print('   📊 Итоговый вес для "$displayText": $weight');
    return weight;
  }

  /// 🏷️ Определение типа локации из предложения
  String _getLocationTypeFromItem(SuggestItem item) {
    final displayText = item.displayText?.toLowerCase() ?? '';
    final title = _extractPlainTitle(item.title).toLowerCase();
    
    // Проверяем по началу названия
    if (title.startsWith('город ')) return 'город';
    if (title.startsWith('посёлок ')) return 'посёлок';
    if (title.startsWith('село ')) return 'село';
    if (title.startsWith('деревня ')) return 'деревня';
    if (title.startsWith('река ')) return 'река';
    if (title.startsWith('озеро ')) return 'озеро';
    if (title.startsWith('ручей ')) return 'ручей';
    
    // Проверяем по содержанию subtitle или displayText
    if (displayText.contains('железнодорожная станция')) return 'станция';
    if (displayText.contains('достопримечательность')) return 'достопримечательность';
    if (displayText.contains('улица')) return 'улица';
    if (displayText.contains('переулок')) return 'переулок';
    if (displayText.contains('проспект')) return 'проспект';
    if (displayText.contains('шоссе')) return 'шоссе';
    
    return 'неизвестно';
  }

  /// 🔤 Извлечение чистого текста из SpannableString
  String _extractPlainTitle(dynamic spannableTitle) {
    if (spannableTitle == null) return '';
    final titleStr = spannableTitle.toString();
    // Извлекаем текст между "text: " и первой запятой
    final match = RegExp(r'text: ([^,}]+)').firstMatch(titleStr);
    return match?.group(1) ?? titleStr;
  }
}

/// 🏋️ Вспомогательный класс для хранения предложения с весом
class _WeightedSuggestion {
  final SuggestItem item;
  final double weight;
  
  _WeightedSuggestion(this.item, this.weight);
}