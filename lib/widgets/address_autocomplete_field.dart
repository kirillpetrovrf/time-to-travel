import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' hide Icon, TextStyle;
import 'package:yandex_maps_mapkit/search.dart';
import 'package:yandex_maps_mapkit/runtime.dart' as yandex;
import '../services/yandex_search_service.dart';

class AddressAutocompleteField extends StatefulWidget {
  final String label;
  final String? initialValue;
  final String cityContext;
  final Function(String address, Point? coordinates) onAddressSelected;
  final FocusNode? focusNode;

  const AddressAutocompleteField({
    super.key,
    required this.label,
    required this.cityContext,
    required this.onAddressSelected,
    this.initialValue,
    this.focusNode,
  });

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  late final TextEditingController _controller;
  late final SearchSuggestSession _suggestSession;
  late final SearchSuggestSessionSuggestListener _suggestListener;
  
  Timer? _debounceTimer;
  final List<SuggestItem> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  bool _isProgrammaticChange = false; // ← Флаг для предотвращения поиска при выборе адреса

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextChanged);
    
    // ✅ НОВЫЙ КОД: Используем глобальный YandexSearchService
    // Это решает проблему когда автокомплит не работает если пользователь
    // не посетил сначала вкладку с картой
    try {
      _suggestSession = YandexSearchService.instance.createSuggestSession();
      
      _suggestListener = SearchSuggestSessionSuggestListener(
        onResponse: _onSuggestResponse,
        onError: _onSuggestError,
      );
      
      debugPrint('✅ [AUTOCOMPLETE] SuggestSession получен из YandexSearchService');
      debugPrint('✅ [AUTOCOMPLETE] SuggestSession: $_suggestSession');
      debugPrint('✅ [AUTOCOMPLETE] Listener: $_suggestListener');
    } catch (e, stackTrace) {
      debugPrint('❌ [AUTOCOMPLETE] Ошибка получения SuggestSession: $e');
      debugPrint('❌ [AUTOCOMPLETE] Stack trace: $stackTrace');
    }
  }

  void _onSuggestResponse(SuggestResponse response) {
    debugPrint('🎉🎉🎉 [AUTOCOMPLETE] RESPONSE CALLBACK FIRED!');
    debugPrint('📊 [AUTOCOMPLETE] Получено подсказок: ${response.items.length}');
    debugPrint('🧭 [AUTOCOMPLETE] Mounted: $mounted');
    
    // ✅ КРИТИЧНО: Проверяем, что виджет не удален
    if (!mounted) {
      debugPrint('⚠️ [AUTOCOMPLETE] Виджет удален, пропускаем setState');
      return;
    }
    
    // Диагностика: выводим все подсказки
    if (response.items.isNotEmpty) {
      debugPrint('📋 [AUTOCOMPLETE] ТОП-5 подсказок:');
      for (int i = 0; i < response.items.length && i < 5; i++) {
        final item = response.items[i];
        debugPrint('   [$i] displayText: "${item.displayText}"');
        debugPrint('       title: "${item.title.text}"');
        debugPrint('       subtitle: "${item.subtitle?.text ?? 'null'}"');
      }
    } else {
      debugPrint('🚫 [AUTOCOMPLETE] Подсказки отсутствуют');
    }
    
    // Сортировка и фильтрация результатов
    final items = response.items.toList();
    final query = _controller.text.trim().toLowerCase();

    // Приоритет точным совпадениям
    items.sort((a, b) {
      final aTitle = a.title.text.toLowerCase();
      final bTitle = b.title.text.toLowerCase();

      final aExact = aTitle.contains(query) ? 0 : 1;
      final bExact = bTitle.contains(query) ? 0 : 1;

      return aExact.compareTo(bExact);
    });

    try {
      setState(() {
        _suggestions.clear();
        _suggestions.addAll(items.take(7));
        _showSuggestions = _suggestions.isNotEmpty;
        _isSearching = false;
      });
      
      debugPrint('✅ [AUTOCOMPLETE] setState успешно выполнен');
      debugPrint('📈 [AUTOCOMPLETE] Показываем ${_suggestions.length} подсказок');
      debugPrint('👁️ [AUTOCOMPLETE] showSuggestions: $_showSuggestions');
    } catch (e, stackTrace) {
      debugPrint('❌ [AUTOCOMPLETE] Ошибка в setState: $e');
      debugPrint('❌ [AUTOCOMPLETE] Stack trace: $stackTrace');
    }
  }

  void _onSuggestError(yandex.Error error) {
    debugPrint('💥💥💥 [AUTOCOMPLETE] ERROR CALLBACK FIRED!');
    debugPrint('🚨 [AUTOCOMPLETE] Ошибка: $error');
    debugPrint('🧭 [AUTOCOMPLETE] Mounted: $mounted');
    
    // ✅ КРИТИЧНО: Проверяем, что виджет не удален
    if (!mounted) {
      debugPrint('⚠️ [AUTOCOMPLETE] Виджет удален, пропускаем setState');
      return;
    }
    
    try {
      setState(() {
        _suggestions.clear();
        _showSuggestions = false;
        _isSearching = false;
      });
      debugPrint('✅ [AUTOCOMPLETE] Error setState выполнен успешно');
    } catch (e, stackTrace) {
      debugPrint('❌ [AUTOCOMPLETE] Ошибка в error setState: $e');
      debugPrint('❌ [AUTOCOMPLETE] Stack trace: $stackTrace');
    }
  }

  void _onTextChanged() {
    // Игнорируем изменения при программном выборе адреса
    if (_isProgrammaticChange) {
      return;
    }
    
    final text = _controller.text.trim();
    _debounceTimer?.cancel();
    
    if (text.length >= 3) {
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _fetchSuggestions(text);
      });
    } else {
      setState(() {
        _suggestions.clear();
        _showSuggestions = false;
      });
    }
  }

  void _fetchSuggestions(String text) {
    setState(() => _isSearching = true);

    try {
      // Формируем текст запроса с контекстом города
      final searchText = widget.cityContext.trim().isNotEmpty 
          ? '${widget.cityContext}, $text'
          : text;
      
      debugPrint('🔍 [AUTOCOMPLETE] Поиск: "$searchText"');
      debugPrint('🔍 [AUTOCOMPLETE] SuggestSession: $_suggestSession');
      debugPrint('🔍 [AUTOCOMPLETE] Listener: $_suggestListener');

      // Используем глобальный BoundingBox как в рабочем коде
      final boundingBox = BoundingBox(
        const Point(latitude: 41.0, longitude: 19.0),
        const Point(latitude: 82.0, longitude: 180.0),
      );

      final options = SuggestOptions(
        suggestTypes: SuggestType(
          SuggestType.Geo.value | SuggestType.Biz.value | SuggestType.Transit.value,
        ),
      );

      debugPrint('� [AUTOCOMPLETE] Вызываем suggest...');
      _suggestSession.suggest(
        boundingBox,
        options,
        _suggestListener,
        text: searchText, // ✅ Исправлено: передаём query в text параметр
      );
      debugPrint('✅ [AUTOCOMPLETE] Suggest вызван успешно, ожидаем callback...');
    } catch (e, stackTrace) {
      debugPrint('❌ [AUTOCOMPLETE] Ошибка в _fetchSuggestions: $e');
      debugPrint('❌ [AUTOCOMPLETE] Stack trace: $stackTrace');
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _onSuggestionSelected(SuggestItem item) {
    final address = _formatAddress(item);
    
    // ✅ Снимаем фокус и скрываем клавиатуру сразу после выбора
    widget.focusNode?.unfocus();
    
    // Устанавливаем флаг перед изменением текста
    _isProgrammaticChange = true;
    
    setState(() {
      _controller.text = address;
      _showSuggestions = false;
      _suggestions.clear();
    });
    
    // Сбрасываем флаг после короткой задержки
    Future.delayed(const Duration(milliseconds: 100), () {
      _isProgrammaticChange = false;
    });

    Point? coordinates;
    if (item.center != null) {
      coordinates = item.center!;
      debugPrint('📍 Координаты: ${coordinates.latitude}, ${coordinates.longitude}');
    }

    debugPrint('📍 Выбран: $address');
    widget.onAddressSelected(address, coordinates);
  }

  String _formatAddress(SuggestItem item) {
    // Используем title.text (русское название) вместо displayText (английское)
    final parts = <String>[];
    
    // Сначала добавляем основной адрес (улица/район)
    final titleText = item.title.text;
    if (titleText.isNotEmpty) {
      parts.add(titleText);
    }
    
    // Затем добавляем область/город
    final subtitle = item.subtitle;
    if (subtitle != null) {
      final subtitleText = subtitle.text;
      if (subtitleText.isNotEmpty) {
        parts.add(subtitleText);
      }
    }

    return parts.isNotEmpty ? parts.join(', ') : item.searchText;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    
    // ✅ КРИТИЧНО: Останавливаем поисковую сессию
    try {
      _suggestSession.reset();
      debugPrint('✅ [AUTOCOMPLETE] Поисковая сессия остановлена');
    } catch (e) {
      debugPrint('⚠️ [AUTOCOMPLETE] Ошибка при остановке сессии: $e');
    }
    
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;
    
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final placeholderColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF3C3C43);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ).copyWith(color: placeholderColor),
          ),
        ),

        CupertinoTextField(
          controller: _controller,
          focusNode: widget.focusNode,
          placeholder: 'Адрес в ${widget.cityContext}',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          style: TextStyle(color: textColor),
          placeholderStyle: TextStyle(color: placeholderColor),
          suffix: _isSearching
              ? const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: CupertinoActivityIndicator(),
                )
              : null,
        ),

        if (_showSuggestions) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                final title = item.title.text;
                final subtitle = item.subtitle?.text;

                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  onPressed: () => _onSuggestionSelected(item),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.location,
                        size: 20,
                        color: placeholderColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ).copyWith(color: textColor),
                            ),
                            if (subtitle != null && subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                ).copyWith(color: placeholderColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
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
}
