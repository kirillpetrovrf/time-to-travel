import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' hide Icon, TextStyle;
import 'package:yandex_maps_mapkit/search.dart';
import 'package:yandex_maps_mapkit/runtime.dart' as yandex;

/// Виджет для автозаполнения адресов через Yandex MapKit
/// 
/// Использование:
/// ```dart
/// AddressAutocompleteField(
///   label: 'Откуда',
///   cityContext: 'Москва',
///   onAddressSelected: (address, coordinates) {
///     print('Выбран адрес: $address');
///     print('Координаты: $coordinates');
///   },
/// )
/// ```
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
  late final SearchManager _searchManager;
  late final SearchSuggestSession _suggestSession;
  late final SearchSuggestSessionSuggestListener _suggestListener;
  
  Timer? _debounceTimer;
  final List<SuggestItem> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  bool _isProgrammaticChange = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextChanged);
    
    _searchManager = SearchFactory.instance.createSearchManager(SearchManagerType.Combined);
    _suggestSession = _searchManager.createSuggestSession();
    
    _suggestListener = SearchSuggestSessionSuggestListener(
      onResponse: _onSuggestResponse,
      onError: _onSuggestError,
    );
  }

  void _onSuggestResponse(SuggestResponse response) {
    debugPrint('✅ [AUTOCOMPLETE] Найдено ${response.items.length} подсказок');
    
    if (!mounted) {
      debugPrint('⚠️ [AUTOCOMPLETE] Виджет удален, пропускаем setState');
      return;
    }
    
    setState(() {
      _suggestions.clear();
      _suggestions.addAll(response.items.take(7));
      _showSuggestions = _suggestions.isNotEmpty;
      _isSearching = false;
    });
  }

  void _onSuggestError(yandex.Error error) {
    debugPrint('❌ [AUTOCOMPLETE] Ошибка: $error');
    
    if (!mounted) {
      debugPrint('⚠️ [AUTOCOMPLETE] Виджет удален, пропускаем setState');
      return;
    }
    
    setState(() {
      _suggestions.clear();
      _showSuggestions = false;
      _isSearching = false;
    });
  }

  void _onTextChanged() {
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
      final searchText = '${widget.cityContext}, $text';
      debugPrint('🔍 [AUTOCOMPLETE] Поиск: "$searchText"');

      // Настройте bounding box под ваш город/регион
      final boundingBox = BoundingBox(
        const Point(latitude: 55.0, longitude: 36.5),
        const Point(latitude: 56.5, longitude: 38.5),
      );

      final options = SuggestOptions(
        suggestTypes: SuggestType(
          SuggestType.Geo.value | SuggestType.Biz.value,
        ),
      );

      _suggestSession.suggest(
        boundingBox,
        options,
        _suggestListener,
        text: searchText,
      );
    } catch (e) {
      debugPrint('❌ [AUTOCOMPLETE] Ошибка: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _onSuggestionSelected(SuggestItem item) {
    final address = _formatAddress(item);
    
    // Скрываем клавиатуру после выбора
    widget.focusNode?.unfocus();
    
    _isProgrammaticChange = true;
    
    setState(() {
      _controller.text = address;
      _showSuggestions = false;
      _suggestions.clear();
    });
    
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
    final parts = <String>[];
    
    final titleText = item.title.text;
    if (titleText.isNotEmpty) {
      parts.add(titleText);
    }
    
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
