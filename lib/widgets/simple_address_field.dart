import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' hide Icon, TextStyle;
import 'package:yandex_maps_mapkit/search.dart';

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
  SearchManager? _searchManager;
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
    
    // Откладываем инициализацию на следующий кадр, чтобы убедиться, что MapKit полностью готов
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeYandexSearchServices();
    });
  }

  Future<void> _initializeYandexSearchServices() async {
    try {
      print('🔧 Инициализация Yandex Search Services...');
      
      // Проверяем, что widget все еще mounted
      if (!mounted) {
        print('⚠️ Widget был unmounted, прерываем инициализацию');
        return;
      }
      
      print('🔧 Создаем SearchManager...');
      _searchManager = SearchFactory.instance.createSearchManager(SearchManagerType.Combined);
      print('✅ SearchManager создан: $_searchManager');
      
      print('🔧 Создаем SuggestSession...');
      _suggestSession = _searchManager!.createSuggestSession();
      print('✅ SuggestSession создан: $_suggestSession');
      
      print('🔧 Создаем SuggestListener...');
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
      
      // Попытаемся еще раз через 2 секунды
      if (mounted) {
        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            print('🔄 Повторная попытка инициализации SimpleAddressField...');
            _initializeYandexSearchServices();
          }
        });
      }
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
    print('📋 SimpleAddressField подсказки:');
    for (int i = 0; i < response.items.length && i < 3; i++) {
      final item = response.items[i];
      print('   [${i+1}] ${item.displayText}');
    }
    
    setState(() {
      _suggestions.clear();
      _suggestions.addAll(response.items.take(5));
      _isSearching = false;
      _showSuggestions = true;
    });
    
    print('🎯 SimpleAddressField состояние обновлено: ${_suggestions.length} подсказок, showSuggestions=$_showSuggestions');
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
}