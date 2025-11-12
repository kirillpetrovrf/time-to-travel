import 'package:flutter/cupertino.dart';
import 'package:taxi_route_calculator/features/search/state/suggest_state.dart';
import 'package:taxi_route_calculator/widgets/search_field_with_suggestions.dart';

/// Панель с двумя полями поиска: "Откуда" (точка А) и "Куда" (точка Б)
class SearchFieldsPanel extends StatelessWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final List<SuggestItem> fromSuggestions;
  final List<SuggestItem> toSuggestions;
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
    this.fromPlaceholder = 'Адрес подачи',
    this.toPlaceholder = 'Адрес назначения',
    this.isFromFieldActive = false,
    this.isToFieldActive = false,
    this.showFromSuggestions = false,
    this.showToSuggestions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Поле "Откуда" (точка А)
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
          // Поле "Куда" (точка Б)
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
