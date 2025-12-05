import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../widgets/simple_address_field.dart';

/// Диалог для добавления нового маршрута в группу с автокомплитом Yandex Maps
class AddRouteToGroupDialog extends StatefulWidget {
  final double defaultPrice;

  const AddRouteToGroupDialog({
    super.key,
    required this.defaultPrice,
  });

  @override
  State<AddRouteToGroupDialog> createState() => _AddRouteToGroupDialogState();
}

class _AddRouteToGroupDialogState extends State<AddRouteToGroupDialog> {
  String _selectedFromCity = '';
  String _selectedToCity = '';
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.defaultPrice.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  bool get _canAdd =>
      _selectedFromCity.isNotEmpty &&
      _selectedToCity.isNotEmpty &&
      _priceController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Отмена'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: const Text('Добавить маршрут'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _canAdd
              ? () {
                  final price = double.tryParse(_priceController.text);
                  if (price != null && price > 0) {
                    Navigator.of(context).pop({
                      'from': _selectedFromCity,
                      'to': _selectedToCity,
                      'price': price,
                    });
                  }
                }
              : null,
          child: Text(
            'Добавить',
            style: TextStyle(
              color: _canAdd
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.inactiveGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Информационный блок
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemBlue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.info_circle,
                      color: CupertinoColors.systemBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Используйте автокомплит для выбора городов. Начните вводить название, система автоматически предложит варианты.',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Поле "Откуда" с автокомплитом
              SimpleAddressField(
                label: 'Откуда',
                initialValue: _selectedFromCity,
                onAddressSelected: (address) {
                  setState(() {
                    _selectedFromCity = address;
                  });
                  print('✅ Выбран адрес "Откуда": $address');
                },
              ),
              
              const SizedBox(height: 16),
              
              // Поле "Куда" с автокомплитом
              SimpleAddressField(
                label: 'Куда',
                initialValue: _selectedToCity,
                onAddressSelected: (address) {
                  setState(() {
                    _selectedToCity = address;
                  });
                  print('✅ Выбран адрес "Куда": $address');
                },
              ),
              
              const SizedBox(height: 16),
              
              // Поле цены
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Цена (₽)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  CupertinoTextField(
                    controller: _priceController,
                    placeholder: 'Например: 50000',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(
                        CupertinoIcons.money_dollar_circle,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        '₽',
                        style: TextStyle(
                          fontSize: 17,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.tertiarySystemFill
                          .resolveFrom(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Кнопка добавления (дублируется снизу для удобства)
              CupertinoButton.filled(
                onPressed: _canAdd
                    ? () {
                        final price = double.tryParse(_priceController.text);
                        if (price != null && price > 0) {
                          Navigator.of(context).pop({
                            'from': _selectedFromCity,
                            'to': _selectedToCity,
                            'price': price,
                          });
                        }
                      }
                    : null,
                child: const Text('Добавить маршрут'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
