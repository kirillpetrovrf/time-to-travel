import 'package:common/buttons/simple_button.dart';
import 'package:flutter/material.dart';
import '../state/suggest_state.dart';
import 'suggest_item.dart';

final class SearchBottomSheet extends StatelessWidget {
  final List<SuggestItem> suggestItems;
  final String searchAndSuggestStatus;
  final TextEditingController textEditingController;

  final void Function(String) onTextChanged;
  final void Function(String) onSubmitted;
  final VoidCallback onSearchButtonTapped;
  final VoidCallback onClearButtonTapped;
  final VoidCallback onResetButtonTapped;
  final VoidCallback onSearchCoffeeButtonTapped;
  final VoidCallback onSearchMallButtonTapped;
  final VoidCallback onSearchHotelButtonTapped;

  final bool isSearchButtonEnabled;
  final bool isResetButtonEnabled;
  final bool isCategoryButtonsVisible;
  final bool isTextFieldEnabled;

  const SearchBottomSheet({
    super.key,
    required this.suggestItems,
    required this.searchAndSuggestStatus,
    required this.textEditingController,
    required this.isSearchButtonEnabled,
    required this.isResetButtonEnabled,
    required this.isCategoryButtonsVisible,
    required this.isTextFieldEnabled,
    required this.onTextChanged,
    required this.onSubmitted,
    required this.onSearchButtonTapped,
    required this.onClearButtonTapped,
    required this.onResetButtonTapped,
    required this.onSearchCoffeeButtonTapped,
    required this.onSearchHotelButtonTapped,
    required this.onSearchMallButtonTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10.0,
              children: [
                SizedBox(
                  width: 150,
                  child: TextField(
                    enabled: isTextFieldEnabled,
                    controller: textEditingController,
                    style: Theme.of(context).textTheme.labelMedium,
                    cursorColor: Theme.of(context).colorScheme.onPrimary,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10.0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10.0)),
                      ),
                      suffixIcon: textEditingController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: onClearButtonTapped,
                              color: Theme.of(context).colorScheme.onPrimary,
                            )
                          : null,
                      labelStyle: Theme.of(context).textTheme.labelMedium,
                      labelText: "Поиск",
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSubmitted,
                    onChanged: onTextChanged,
                  ),
                ),
                SimpleButton(
                  text: "Поиск",
                  isEnabled: isSearchButtonEnabled,
                  onPressed: onSearchButtonTapped,
                ),
                SimpleButton(
                  text: "Сбросить сессию",
                  isEnabled: isResetButtonEnabled,
                  onPressed: onResetButtonTapped,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              searchAndSuggestStatus,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            if (isCategoryButtonsVisible) ...[
              const SizedBox(height: 32.0),
              Wrap(
                spacing: 16.0,
                children: [
                  SimpleButton(
                    text: "Кофе",
                    textStyle: Theme.of(context).textTheme.labelLarge,
                    onPressed: onSearchCoffeeButtonTapped,
                  ),
                  SimpleButton(
                    text: "ТЦ",
                    textStyle: Theme.of(context).textTheme.labelLarge,
                    onPressed: onSearchMallButtonTapped,
                  ),
                  SimpleButton(
                    text: "Отель",
                    textStyle: Theme.of(context).textTheme.labelLarge,
                    onPressed: onSearchHotelButtonTapped,
                  ),
                ],
              )
            ],
            if (suggestItems.isNotEmpty) ...[
              Divider(
                height: 20.0,
                thickness: 2.0,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ],
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: suggestItems
                    .map((item) => SuggestItemWidget(
                          title: item.title,
                          subtitle: item.subtitle,
                          onTap: () {
                            // Сначала сохраняем адрес
                            item.onTap();
                            // Затем закрываем bottomSheet с задержкой, чтобы избежать tap-through
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            });
                          },
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
