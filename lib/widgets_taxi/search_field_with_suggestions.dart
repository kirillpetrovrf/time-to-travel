import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../features/search/state/suggest_state.dart';
import '../features/search/widgets/utils.dart';

/// Поле ввода с автодополнением, которое показывает dropdown с предложениями
class SearchFieldWithSuggestions extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final Color iconColor;
  final String mapButtonText;
  final List<SuggestItem> suggestions;
  final ValueChanged<String>? onTextChanged;
  final ValueChanged<SuggestItem>? onSuggestionSelected;
  final ValueChanged<String>? onSubmitted;  // 🆕 Когда нажали "Найти" на клавиатуре
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
    this.onSubmitted,  // 🆕
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
  bool _isSettingTextProgrammatically = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _fieldKey = GlobalKey();
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.onFieldTapped?.call();
        // Используем addPostFrameCallback для показа overlay
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
    
    // Обновляем overlay когда меняются предложения
    if (widget.showSuggestions != oldWidget.showSuggestions ||
        widget.suggestions != oldWidget.suggestions) {
      // Используем addPostFrameCallback чтобы избежать setState во время build
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
                        // Дополнительная проверка безопасности
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

  Widget _buildSuggestionItem(SuggestItem suggestion) {
    return InkWell(
      onTap: () {
        // Устанавливаем флаг перед программной установкой текста
        _isSettingTextProgrammatically = true;
        
        // Сначала устанавливаем displayText в контроллер (короткий, красивый)
        widget.controller.text = suggestion.displayText;
        
        // Сбрасываем флаг после установки
        _isSettingTextProgrammatically = false;
        
        // Затем скрываем overlay и убираем фокус
        _focusNode.unfocus();
        _hideOverlay();
        
        // И вызываем callback с полным suggestion объектом
        widget.onSuggestionSelected?.call(suggestion);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Главный текст
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.label,
                ),
                children: suggestion.title.toTextSpans(
                  defaultColor: CupertinoColors.label.resolveFrom(context),
                  spanColor: CupertinoColors.activeBlue.resolveFrom(context),
                ),
              ),
            ),
            // Подтекст (если есть)
            if (suggestion.subtitle != null) ...[
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  children: suggestion.subtitle!.toTextSpans(
                    defaultColor: CupertinoColors.secondaryLabel.resolveFrom(context),
                    spanColor: CupertinoColors.activeBlue.resolveFrom(context),
                  ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
            // Кнопка выбора точки на карте с текстом
            GestureDetector(
              onTap: widget.onMapButtonTapped,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.iconColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.mapButtonText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.iconColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: TextStyle(
                    color: isDark ? CupertinoColors.systemGrey2 : CupertinoColors.systemGrey,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  // Игнорируем изменения когда текст устанавливается программно
                  if (!_isSettingTextProgrammatically) {
                    widget.onTextChanged?.call(value);
                  }
                },
                onSubmitted: (value) {
                  // 🆕 Когда пользователь нажимает "Найти" на клавиатуре
                  if (value.isNotEmpty) {
                    // Убираем фокус, чтобы скрыть клавиатуру и остановить автопоиск
                    _focusNode.unfocus();
                    widget.onSubmitted?.call(value);
                  }
                },
              ),
            ),
            if (widget.controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  widget.controller.clear();
                  widget.onTextChanged?.call('');
                  _focusNode.requestFocus();
                },
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}