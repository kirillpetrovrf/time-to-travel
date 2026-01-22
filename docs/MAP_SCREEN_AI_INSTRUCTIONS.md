# 🗺️ ИНСТРУКЦИИ ДЛЯ ИИ: Создание экрана карты с элементами управления

**Дата:** 3 декабря 2025  
**Проект:** Такси Попутчик  
**Назначение:** Полные инструкции для создания аналогичного экрана карты в другом Flutter приложении

---

## 🎯 ЧТО МЫ СОЗДАЕМ

Экран карты с наложенными элементами управления:
- 🔍 Панель поиска "Откуда/Куда" (сверху)
- 🎯 Кнопки выбора точек на карте ("От"/"До")
- 🗑️ Кнопка сброса маршрута ("корзина") с анимированным текстом
- 📍 Кнопка геолокации (правый нижний угол)
- 🔍 Кнопки масштабирования +/- (правая сторона)
- 📝 Автодополнение адресов с dropdown
- 🗺️ Обработка тапов по карте для выбора точек

---

## 📁 СТРУКТУРА ФАЙЛОВ

Создайте следующие файлы в вашем Flutter проекте:

```
lib/
├── screens/
│   └── map_screen.dart                 # Основной экран карты
├── widgets/
│   ├── search_fields_panel.dart        # Панель с полями "Откуда/Куда"
│   ├── search_field_with_suggestions.dart  # Поле ввода с автодополнением
│   └── geolocation_button.dart         # Кнопка геолокации
├── utils/
│   └── map_utils.dart                  # Утилиты для карты
└── assets/
    ├── user_forward.png                # Иконка "От" (зеленая стрелка)
    └── user_backward.png               # Иконка "До" (красная стрелка)
```

---

## 🎨 1. ОСНОВНОЙ ЭКРАН КАРТЫ

**Файл:** `lib/screens/map_screen.dart`

```dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// Замените на ваш SDK карт (Yandex MapKit, Google Maps, etc.)
import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;

// Импорты виджетов (создайте эти файлы)
import '../widgets/search_fields_panel.dart';
import '../widgets/geolocation_button.dart';
import '../utils/map_utils.dart';

enum ActiveField { none, from, to }
enum RoutePointType { from, to }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 📝 Контроллеры для текстовых полей
  late TextEditingController _fromController;
  late TextEditingController _toController;
  
  // 🎯 Состояние активного поля и выбора точек
  ActiveField _activeField = ActiveField.none;
  RoutePointType _selectedPointType = RoutePointType.from;
  bool _isPointSelectionEnabled = true;
  bool _showDeleteMessage = false;
  
  // 🗺️ Переменные карты (адаптируйте под ваш SDK)
  mapkit.MapWindow? _mapWindow;
  
  // 📍 Список предложений автодополнения (замените на ваш API)
  List<SuggestionItem> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController();
    _toController = TextEditingController();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🗺️ 1. КАРТА НА ВЕСЬ ЭКРАН (базовый слой)
          _buildMapWidget(),
          
          // 🔍 2. ПАНЕЛЬ ПОИСКА "ОТКУДА/КУДА" (поверх карты)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: SearchFieldsPanel(
                fromController: _fromController,
                toController: _toController,
                fromSuggestions: _activeField == ActiveField.from ? _suggestions : [],
                toSuggestions: _activeField == ActiveField.to ? _suggestions : [],
                isFromFieldActive: _activeField == ActiveField.from,
                isToFieldActive: _activeField == ActiveField.to,
                showFromSuggestions: _activeField == ActiveField.from && _suggestions.isNotEmpty,
                showToSuggestions: _activeField == ActiveField.to && _suggestions.isNotEmpty,
                // Callback'и для активации полей
                onFromFieldTapped: () {
                  setState(() {
                    _activeField = ActiveField.from;
                  });
                  _loadSuggestions(_fromController.text);
                },
                onToFieldTapped: () {
                  setState(() {
                    _activeField = ActiveField.to;
                  });
                  _loadSuggestions(_toController.text);
                },
                // Callback'и для изменения текста
                onFromTextChanged: (text) {
                  if (_activeField == ActiveField.from) {
                    _loadSuggestions(text);
                  }
                },
                onToTextChanged: (text) {
                  if (_activeField == ActiveField.to) {
                    _loadSuggestions(text);
                  }
                },
                // Callback'и для выбора предложений
                onFromSuggestionSelected: (address) {
                  setState(() {
                    _fromController.text = address;
                    _activeField = ActiveField.none;
                  });
                  _setPointFromAddress(address, RoutePointType.from);
                },
                onToSuggestionSelected: (address) {
                  setState(() {
                    _toController.text = address;
                    _activeField = ActiveField.none;
                  });
                  _setPointFromAddress(address, RoutePointType.to);
                },
                // 🎯 Callback'и для кнопок карты
                onFromMapButtonTapped: () {
                  setState(() {
                    _selectedPointType = RoutePointType.from;
                    _isPointSelectionEnabled = true;
                    _activeField = ActiveField.none;
                  });
                  _showSnackBar("Выберите точку ОТКУДА на карте 🟢");
                },
                onToMapButtonTapped: () {
                  setState(() {
                    _selectedPointType = RoutePointType.to;
                    _isPointSelectionEnabled = true;
                    _activeField = ActiveField.none;
                  });
                  _showSnackBar("Выберите точку КУДА на карте 🔴");
                },
              ),
            ),
          ),
          
          // 🗑️ 3. КНОПКА СБРОСА МАРШРУТА (под панелью поиска)
          Positioned(
            top: 140,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Row(
                children: [
                  // Кнопка "корзины"
                  FloatingActionButton(
                    heroTag: "reset_route_button",
                    mini: true,
                    backgroundColor: CupertinoColors.white,
                    onPressed: () async {
                      // Показываем анимированный текст
                      setState(() {
                        _showDeleteMessage = true;
                      });
                      
                      // Сброс всех полей и маршрутов
                      _resetAllFields();
                      
                      // Скрываем текст через 2 секунды
                      await Future.delayed(const Duration(seconds: 2));
                      if (mounted) {
                        setState(() {
                          _showDeleteMessage = false;
                        });
                      }
                    },
                    child: const Icon(
                      Icons.delete_outline,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  
                  // 📝 Анимированный текст справа от кнопки
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _showDeleteMessage ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: _showDeleteMessage
                          ? Container(
                              margin: const EdgeInsets.only(left: 8),
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.systemGrey.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Стираем все маршруты',
                                  style: TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 📍 4. КНОПКА ГЕОЛОКАЦИИ (правый нижний угол)
          Positioned(
            bottom: 16,
            right: 16,
            child: GeolocationButton(
              onPressed: _moveToUserLocation,
            ),
          ),
          
          // 🔍 5. КНОПКИ МАСШТАБИРОВАНИЯ (правая сторона, по центру)
          Positioned(
            top: 0,
            bottom: 0,
            right: 16,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: "zoom_in",
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _zoomIn,
                    child: const Icon(
                      Icons.add,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: "zoom_out",
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _zoomOut,
                    child: const Icon(
                      Icons.remove,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🗺️ ВИДЖЕТ КАРТЫ (адаптируйте под ваш SDK)
  Widget _buildMapWidget() {
    // Замените на ваш виджет карты (YandexMap, GoogleMap, etc.)
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: const Center(
        child: Text(
          'ЗДЕСЬ ВАША КАРТА\n(YandexMap, GoogleMap, etc.)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
      // Пример для Yandex MapKit:
      // child: YandexMap(
      //   onMapCreated: (controller) => _setupMap(controller),
      //   onMapTap: (point) => _onMapTap(point),
      // ),
    );
  }

  // 📍 ОБРАБОТЧИК ТАПОВ ПО КАРТЕ
  void _onMapTap(dynamic point) {
    if (_isPointSelectionEnabled) {
      print('🎯 Map tapped for point selection: ${point.latitude}, ${point.longitude}');
      
      // Получаем адрес по координатам (замените на ваш API)
      _getAddressFromCoordinates(point.latitude, point.longitude).then((address) {
        setState(() {
          if (_selectedPointType == RoutePointType.from) {
            _fromController.text = address;
          } else {
            _toController.text = address;
          }
          _isPointSelectionEnabled = false;
        });
      });
    }
  }

  // 🔍 ЗАГРУЗКА ПРЕДЛОЖЕНИЙ (замените на ваш API)
  void _loadSuggestions(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    // Замените на ваш API автодополнения
    try {
      // Пример для Yandex SuggestSession:
      // final suggestions = await _suggestSession.suggest(query);
      
      // Заглушка - замените на реальный API:
      final suggestions = [
        SuggestionItem(title: 'Красная площадь, Москва', subtitle: 'Россия'),
        SuggestionItem(title: 'Невский проспект, Санкт-Петербург', subtitle: 'Россия'),
      ];
      
      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {
      print('Ошибка загрузки предложений: $e');
      setState(() {
        _suggestions = [];
      });
    }
  }

  // 📍 УСТАНОВКА ТОЧКИ ПО АДРЕСУ
  void _setPointFromAddress(String address, RoutePointType type) async {
    // Замените на ваш API геокодирования
    try {
      // final coordinates = await _geocodingService.getCoordinatesFromAddress(address);
      // _setPointOnMap(coordinates, type);
      print('Установка точки $type по адресу: $address');
    } catch (e) {
      print('Ошибка геокодирования: $e');
    }
  }

  // 📍 ПОЛУЧЕНИЕ АДРЕСА ПО КООРДИНАТАМ
  Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
    // Замените на ваш API обратного геокодирования
    try {
      // final address = await _reverseGeocodingService.getAddress(latitude, longitude);
      // return address;
      
      // Заглушка:
      return 'Адрес: $latitude, $longitude';
    } catch (e) {
      return 'Неизвестный адрес';
    }
  }

  // 🗑️ СБРОС ВСЕХ ПОЛЕЙ
  void _resetAllFields() {
    setState(() {
      _fromController.clear();
      _toController.clear();
      _activeField = ActiveField.none;
      _selectedPointType = RoutePointType.from;
      _isPointSelectionEnabled = true;
      _suggestions = [];
    });
    
    // Очистка маршрутов на карте (замените на ваш API)
    // _clearRouteOnMap();
    
    print('🔥 Все поля и маршруты сброшены');
  }

  // 📍 ПЕРЕМЕЩЕНИЕ К ГЕОЛОКАЦИИ ПОЛЬЗОВАТЕЛЯ
  void _moveToUserLocation() async {
    // Замените на ваш API геолокации
    try {
      // final position = await Geolocator.getCurrentPosition();
      // _moveMapCamera(position.latitude, position.longitude);
      print('📍 Перемещение к геолокации пользователя');
      _showSnackBar('Перемещено к вашему местоположению');
    } catch (e) {
      _showSnackBar('Не удалось получить местоположение');
    }
  }

  // 🔍 МАСШТАБИРОВАНИЕ КАРТЫ
  void _zoomIn() {
    // Замените на ваш API карты
    // _mapController?.zoomIn();
    print('🔍 Приближение карты');
  }

  void _zoomOut() {
    // Замените на ваш API карты
    // _mapController?.zoomOut();
    print('🔍 Отдаление карты');
  }

  // 📢 ПОКАЗ СООБЩЕНИЙ
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// 📝 МОДЕЛЬ ПРЕДЛОЖЕНИЯ АВТОДОПОЛНЕНИЯ
class SuggestionItem {
  final String title;
  final String? subtitle;
  
  const SuggestionItem({
    required this.title,
    this.subtitle,
  });
}
```

---

## 🔍 2. ПАНЕЛЬ ПОИСКА

**Файл:** `lib/widgets/search_fields_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'search_field_with_suggestions.dart';
import '../screens/map_screen.dart'; // Для SuggestionItem

class SearchFieldsPanel extends StatelessWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final List<SuggestionItem> fromSuggestions;
  final List<SuggestionItem> toSuggestions;
  final ValueChanged<String>? onFromTextChanged;
  final ValueChanged<String>? onToTextChanged;
  final ValueChanged<String>? onFromSuggestionSelected;
  final ValueChanged<String>? onToSuggestionSelected;
  final VoidCallback? onFromFieldTapped;
  final VoidCallback? onToFieldTapped;
  final VoidCallback? onFromMapButtonTapped;
  final VoidCallback? onToMapButtonTapped;
  final String fromPlaceholder;
  final String toPlaceholder;
  final bool isFromFieldActive;
  final bool isToFieldActive;
  final bool showFromSuggestions;
  final bool showToSuggestions;

  const SearchFieldsPanel({
    super.key,
    required this.fromController,
    required this.toController,
    this.fromSuggestions = const [],
    this.toSuggestions = const [],
    this.onFromTextChanged,
    this.onToTextChanged,
    this.onFromSuggestionSelected,
    this.onToSuggestionSelected,
    this.onFromFieldTapped,
    this.onToFieldTapped,
    this.onFromMapButtonTapped,
    this.onToMapButtonTapped,
    this.fromPlaceholder = 'Откуда',
    this.toPlaceholder = 'Куда',
    this.isFromFieldActive = false,
    this.isToFieldActive = false,
    this.showFromSuggestions = false,
    this.showToSuggestions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.resolveFrom(context).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🟢 ПОЛЕ "ОТКУДА" (точка А)
          SearchFieldWithSuggestions(
            controller: fromController,
            placeholder: fromPlaceholder,
            icon: CupertinoIcons.location_fill,
            iconColor: CupertinoColors.activeGreen,
            mapButtonText: 'От',
            suggestions: fromSuggestions,
            isActive: isFromFieldActive,
            showSuggestions: showFromSuggestions,
            onTextChanged: onFromTextChanged,
            onSuggestionSelected: onFromSuggestionSelected,
            onFieldTapped: onFromFieldTapped,
            onMapButtonTapped: onFromMapButtonTapped,
          ),
          
          const SizedBox(height: 16),
          
          // 🔴 ПОЛЕ "КУДА" (точка Б)
          SearchFieldWithSuggestions(
            controller: toController,
            placeholder: toPlaceholder,
            icon: CupertinoIcons.flag_fill,
            iconColor: CupertinoColors.destructiveRed,
            mapButtonText: 'До',
            suggestions: toSuggestions,
            isActive: isToFieldActive,
            showSuggestions: showToSuggestions,
            onTextChanged: onToTextChanged,
            onSuggestionSelected: onToSuggestionSelected,
            onFieldTapped: onToFieldTapped,
            onMapButtonTapped: onToMapButtonTapped,
          ),
        ],
      ),
    );
  }
}
```

---

## 🎯 3. ПОЛЕ ВВОДА С КНОПКОЙ КАРТЫ

**Файл:** `lib/widgets/search_field_with_suggestions.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../screens/map_screen.dart'; // Для SuggestionItem

class SearchFieldWithSuggestions extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final Color iconColor;
  final String mapButtonText;
  final List<SuggestionItem> suggestions;
  final ValueChanged<String>? onTextChanged;
  final ValueChanged<String>? onSuggestionSelected;
  final VoidCallback? onFieldTapped;
  final VoidCallback? onMapButtonTapped;
  final bool isActive;
  final bool showSuggestions;

  const SearchFieldWithSuggestions({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.icon,
    required this.iconColor,
    required this.mapButtonText,
    this.suggestions = const [],
    this.onTextChanged,
    this.onSuggestionSelected,
    this.onFieldTapped,
    this.onMapButtonTapped,
    this.isActive = false,
    this.showSuggestions = false,
  });

  @override
  State<SearchFieldWithSuggestions> createState() => _SearchFieldWithSuggestionsState();
}

class _SearchFieldWithSuggestionsState extends State<SearchFieldWithSuggestions> {
  late FocusNode _focusNode;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  late GlobalKey _fieldKey;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _fieldKey = GlobalKey();
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.onFieldTapped?.call();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showOverlay();
        });
      } else {
        _hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SearchFieldWithSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.showSuggestions != oldWidget.showSuggestions ||
        widget.suggestions != oldWidget.suggestions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.showSuggestions && _focusNode.hasFocus) {
          _updateOverlay();
        } else {
          _hideOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _updateOverlay() {
    _hideOverlay();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNode.hasFocus) {
        _showOverlay();
      }
    });
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = _fieldKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CupertinoColors.systemGrey4.resolveFrom(context),
                  width: 0.5,
                ),
              ),
              child: widget.suggestions.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: widget.suggestions.length,
                      itemBuilder: (context, index) {
                        if (index >= widget.suggestions.length) {
                          return const SizedBox.shrink();
                        }
                        final suggestion = widget.suggestions[index];
                        return _buildSuggestionItem(suggestion);
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(SuggestionItem suggestion) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        widget.onSuggestionSelected?.call(suggestion.title);
        _focusNode.unfocus();
        _hideOverlay();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suggestion.title,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.label,
              ),
            ),
            if (suggestion.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                suggestion.subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        key: _fieldKey,
        padding: const EdgeInsets.only(left: 2, right: 12, top: 2, bottom: 2),
        decoration: BoxDecoration(
          color: widget.isActive 
              ? (isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white)
              : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(10),
          border: widget.isActive
              ? Border.all(
                  color: CupertinoColors.activeBlue.resolveFrom(context),
                  width: 2,
                )
              : null,
        ),
        child: Row(
          children: [
            // 🎯 КНОПКА ВЫБОРА ТОЧКИ НА КАРТЕ
            GestureDetector(
              onTap: widget.onMapButtonTapped,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: _buildMapButtonIcon(),
                ),
              ),
            ),
            
            const SizedBox(width: 10),
            
            // 📝 ТЕКСТОВОЕ ПОЛЕ
            Expanded(
              child: CupertinoTextField(
                controller: widget.controller,
                focusNode: _focusNode,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                placeholder: widget.placeholder,
                placeholderStyle: TextStyle(
                  color: isDark ? CupertinoColors.systemGrey2 : CupertinoColors.systemGrey,
                ),
                decoration: const BoxDecoration(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                onChanged: widget.onTextChanged,
              ),
            ),
            
            // ❌ КНОПКА ОЧИСТКИ
            if (widget.controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  widget.controller.clear();
                  widget.onTextChanged?.call('');
                  _focusNode.requestFocus();
                },
                child: Icon(
                  CupertinoIcons.clear_thick_circled,
                  size: 20,
                  color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🎨 ИКОНКА НА КНОПКЕ КАРТЫ
  Widget _buildMapButtonIcon() {
    // Если у вас есть кастомные иконки:
    if (widget.mapButtonText == 'От') {
      // Попробуйте загрузить assets/user_forward.png
      return Image.asset(
        'assets/user_forward.png',
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            CupertinoIcons.location_fill,
            color: CupertinoColors.activeGreen,
            size: 20,
          );
        },
      );
    } else {
      // Попробуйте загрузить assets/user_backward.png
      return Image.asset(
        'assets/user_backward.png',
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            CupertinoIcons.flag_fill,
            color: CupertinoColors.destructiveRed,
            size: 20,
          );
        },
      );
    }
  }
}
```

---

## 📍 4. КНОПКА ГЕОЛОКАЦИИ

**Файл:** `lib/widgets/geolocation_button.dart`

```dart
import 'package:flutter/cupertino.dart';

class GeolocationButton extends StatelessWidget {
  final VoidCallback? onPressed;
  
  const GeolocationButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.resolveFrom(context).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        child: Icon(
          CupertinoIcons.location_fill,
          color: CupertinoColors.systemYellow.resolveFrom(context),
          size: 24,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
```

---

## 🛠️ 5. УТИЛИТЫ (ОПЦИОНАЛЬНО)

**Файл:** `lib/utils/map_utils.dart`

```dart
import 'package:flutter/cupertino.dart';

// Утилитарные функции для работы с картой

class MapUtils {
  // Проверка валидности координат
  static bool isValidCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  // Форматирование координат для отображения
  static String formatCoordinates(double lat, double lng) {
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  // Вычисление расстояния между двумя точками (упрощенная версия)
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // км
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLng = _degreesToRadians(lng2 - lng1);
    
    double a = (dLat / 2).abs() * (dLat / 2).abs() +
        _degreesToRadians(lat1).abs() * _degreesToRadians(lat2).abs() *
        (dLng / 2).abs() * (dLng / 2).abs();
    
    double c = 2 * ((a.abs() + (1 - a).abs()) / 2);
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  // Цвета для разных типов точек
  static Color getPointColor(String pointType) {
    switch (pointType) {
      case 'from':
        return CupertinoColors.activeGreen;
      case 'to':
        return CupertinoColors.destructiveRed;
      default:
        return CupertinoColors.systemBlue;
    }
  }
}
```

---

## 🎨 6. РЕСУРСЫ (ASSETS)

Создайте папку `assets/` в корне проекта и добавьте иконки:

**pubspec.yaml:**
```yaml
flutter:
  assets:
    - assets/user_forward.png   # Зеленая стрелка "От"
    - assets/user_backward.png  # Красная стрелка "До"
```

**Альтернатива:** Используйте встроенные иконки Flutter:
- `CupertinoIcons.location_fill` (зеленая) для "От"
- `CupertinoIcons.flag_fill` (красная) для "До"

---

## 🔧 7. ИНТЕГРАЦИЯ С SDK КАРТ

### Для Yandex MapKit:

```dart
// В pubspec.yaml добавьте:
dependencies:
  yandex_maps_mapkit: ^4.24.0-beta

// В _buildMapWidget() замените Container на:
import 'package:yandex_maps_mapkit/yandex_maps_mapkit.dart';

Widget _buildMapWidget() {
  return YandexMap(
    onMapCreated: (YandexMapController controller) {
      _mapController = controller;
    },
    onMapTap: (Point point) {
      _onMapTap(point);
    },
    mapObjects: _buildMapObjects(), // Ваши маркеры и маршруты
  );
}
```

### Для Google Maps:

```dart
// В pubspec.yaml добавьте:
dependencies:
  google_maps_flutter: ^2.5.0

// В _buildMapWidget() замените Container на:
import 'package:google_maps_flutter/google_maps_flutter.dart';

Widget _buildMapWidget() {
  return GoogleMap(
    onMapCreated: (GoogleMapController controller) {
      _mapController = controller;
    },
    onTap: (LatLng latLng) {
      _onMapTap(latLng);
    },
    markers: _buildMarkers(), // Ваши маркеры
    polylines: _buildPolylines(), // Ваши маршруты
    initialCameraPosition: const CameraPosition(
      target: LatLng(55.751244, 37.618423), // Москва
      zoom: 10.0,
    ),
  );
}
```

---

## 📦 8. ЗАВИСИМОСТИ

Добавьте в `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  
  # Выберите один SDK карт:
  yandex_maps_mapkit: ^4.24.0-beta    # Для Yandex Maps
  # ИЛИ
  google_maps_flutter: ^2.5.0         # Для Google Maps
  
  # Для геолокации:
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
  
  # Для HTTP запросов (автодополнение):
  http: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/user_forward.png
    - assets/user_backward.png
```

---

## 🚀 9. ЗАПУСК И ИСПОЛЬЗОВАНИЕ

1. **Создайте файлы** по указанной структуре
2. **Замените заглушки** на реальные API вашей карты
3. **Добавьте зависимости** в pubspec.yaml
4. **Добавьте иконки** в папку assets/
5. **Настройте API ключи** для выбранного SDK карт
6. **Запустите приложение**:

```bash
flutter pub get
flutter run
```

---

## 🎯 10. КЛЮЧЕВЫЕ ОСОБЕННОСТИ

### ✅ Что уже работает:
- 📱 Responsive UI с Stack позиционированием
- 🔍 Панель поиска с двумя полями
- 🎯 Кнопки выбора точек на карте
- 🗑️ Анимированная кнопка сброса
- 📍 Кнопка геолокации
- 🔍 Кнопки масштабирования
- 📝 Dropdown автодополнения
- 🎨 Cupertino Design System

### 🔧 Что нужно адаптировать:
- 🗺️ Замените виджет карты на ваш SDK
- 🔍 Подключите API автодополнения адресов
- 📍 Подключите API геокодирования/reverse геокодирования
- 🗺️ Добавьте отображение маркеров и маршрутов
- 📱 Настройте permissions для геолокации

---

## 💡 11. СОВЕТЫ ПО АДАПТАЦИИ

### Для другого SDK карт:
1. Замените `_buildMapWidget()` на ваш виджет карты
2. Адаптируйте `_onMapTap()` под формат координат вашего SDK
3. Реализуйте `_zoomIn()` и `_zoomOut()` через API вашего SDK

### Для другого API автодополнения:
1. Замените `_loadSuggestions()` на ваш API
2. Адаптируйте модель `SuggestionItem` под ваш формат данных
3. Обновите обработчик `onSuggestionSelected`

### Для кастомного дизайна:
1. Измените цвета в `BoxDecoration` и `IconColor`
2. Замените иконки на ваши в `_buildMapButtonIcon()`
3. Адаптируйте отступы и размеры в `EdgeInsets`

---

**Готово!** 🎉 Теперь у вас есть полный код для создания аналогичного экрана карты с всеми элементами управления. Просто адаптируйте API под ваш SDK карт и автодополнения!
