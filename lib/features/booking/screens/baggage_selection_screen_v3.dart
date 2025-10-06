import 'package:flutter/cupertino.dart';
import '../../../models/baggage.dart';
import '../../../services/baggage_pricing_service.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';

/// Экран выбора багажа (ПОЛНОСТЬЮ ПЕРЕДЕЛАН под ТЗ v3.0)
/// НОВЫЕ ПРАВИЛА: 1 багажное место БЕСПЛАТНО, количество 1-10, цены от диспетчера
class BaggageSelectionScreen extends StatefulWidget {
  final List<BaggageItem> initialBaggage;
  final Function(List<BaggageItem>) onBaggageSelected;

  const BaggageSelectionScreen({
    super.key,
    this.initialBaggage = const [],
    required this.onBaggageSelected,
  });

  @override
  State<BaggageSelectionScreen> createState() => _BaggageSelectionScreenState();
}

class _BaggageSelectionScreenState extends State<BaggageSelectionScreen> {
  late Map<BaggageSize, int>
  _quantities; // Количество каждого типа багажа (0-10)
  Map<BaggageSize, double> _prices = {}; // Цены от диспетчера
  bool _isLoading = true;

  // Контроллеры для custom багажа
  final TextEditingController _customDescriptionController =
      TextEditingController();
  final TextEditingController _customDimensionsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeQuantities();
    _loadPrices();
  }

  void _initializeQuantities() {
    // Инициализируем количества из существующего багажа или нулями
    _quantities = {
      BaggageSize.s: 0,
      BaggageSize.m: 0,
      BaggageSize.l: 0,
      BaggageSize.custom: 0,
    };

    // Заполняем из начальных данных
    for (final item in widget.initialBaggage) {
      _quantities[item.size] = item.quantity;
      if (item.size == BaggageSize.custom) {
        _customDescriptionController.text = item.customDescription ?? '';
        _customDimensionsController.text = item.customDimensions ?? '';
      }
    }
  }

  Future<void> _loadPrices() async {
    try {
      final prices = await BaggagePricingService.getExtraBaggagePrices();
      if (mounted) {
        setState(() {
          _prices = prices;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки цен: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _customDescriptionController.dispose();
    _customDimensionsController.dispose();
    super.dispose();
  }

  void _updateQuantity(BaggageSize size, int newQuantity) {
    if (newQuantity >= 0 && newQuantity <= 10) {
      setState(() {
        _quantities[size] = newQuantity;
      });
    }
  }

  int _getTotalBaggageCount() {
    return _quantities.values.fold(0, (sum, quantity) => sum + quantity);
  }

  // Определяет, является ли данный размер первым выбранным багажом
  bool _isFirstBaggageSize(BaggageSize size) {
    // Проходим по размерам в том же порядке, что и отображаем
    for (final currentSize in [
      BaggageSize.s,
      BaggageSize.m,
      BaggageSize.l,
      BaggageSize.custom,
    ]) {
      final quantity = _quantities[currentSize] ?? 0;
      if (quantity > 0) {
        // Первый найденный размер с quantity > 0 - это и есть первый багаж
        return currentSize == size;
      }
    }
    return false;
  }

  double _calculateTotalCost() {
    // НОВАЯ ЛОГИКА: только первое место из всего багажа бесплатно
    int totalBaggageCount = 0;
    double total = 0.0;

    // Сначала считаем общее количество багажа
    for (final size in BaggageSize.values) {
      totalBaggageCount += _quantities[size] ?? 0;
    }

    if (totalBaggageCount == 0) return 0.0;
    if (totalBaggageCount == 1) return 0.0; // Первый багаж бесплатно

    // Считаем стоимость всех багажей (без учета первого бесплатного)
    int processedCount = 0;
    for (final size in BaggageSize.values) {
      final quantity = _quantities[size] ?? 0;
      final pricePerExtra = _prices[size] ?? 0.0;

      for (int i = 0; i < quantity; i++) {
        processedCount++;

        // Первый багаж бесплатно
        if (processedCount == 1) continue;

        // Все последующие по полной цене
        total += pricePerExtra;
      }
    }

    return total;
  }

  List<BaggageItem> _buildBaggageList() {
    final List<BaggageItem> result = [];

    for (final size in BaggageSize.values) {
      final quantity = _quantities[size] ?? 0;
      if (quantity > 0) {
        final pricePerExtra = _prices[size] ?? 0.0;
        result.add(
          BaggageItem(
            size: size,
            quantity: quantity,
            customDescription: size == BaggageSize.custom
                ? _customDescriptionController.text
                : null,
            customDimensions: size == BaggageSize.custom
                ? _customDimensionsController.text
                : null,
            pricePerExtraItem: pricePerExtra,
          ),
        );
      }
    }

    return result;
  }

  void _showCustomBaggageDialog() {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Индивидуальный багаж'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Информационное сообщение о цене
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemYellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.info_circle_fill,
                    color: CupertinoColors.systemOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Цена уточняется диспетчером после оформления заказа',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.secondaryLabel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _customDescriptionController,
              placeholder: 'Что везете? (необязательно)',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _customDimensionsController,
              placeholder: 'Габариты (Д×Ш×В см)',
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Сохранить'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    if (_isLoading) {
      return CupertinoPageScaffold(
        backgroundColor: theme.systemBackground,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: theme.secondarySystemBackground,
          middle: Text('Выбор багажа', style: TextStyle(color: theme.label)),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text('Выбор багажа', style: TextStyle(color: theme.label)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Отмена', style: TextStyle(color: theme.quaternaryLabel)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
            'Готово',
            style: TextStyle(color: CupertinoColors.activeBlue),
          ),
          onPressed: () {
            widget.onBaggageSelected(_buildBaggageList());
            Navigator.of(context).pop();
          },
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с пояснением новых правил
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.secondarySystemBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '1 БАГАЖНОЕ МЕСТО БЕСПЛАТНО',
                      style: TextStyle(
                        color: CupertinoColors.activeGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Дополнительный багаж оплачивается отдельно',
                      style: TextStyle(
                        color: theme.secondaryLabel,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Информационное сообщение о дополнительной оплате (показывается когда выбрано больше 1 багажа)
              if (_getTotalBaggageCount() > 1) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoColors.systemYellow.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle_fill,
                        color: CupertinoColors.systemYellow,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Дополнительная оплата',
                              style: TextStyle(
                                color: theme.label,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Один багаж бесплатно, любой последующий платно',
                              style: TextStyle(
                                color: theme.secondaryLabel,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Карточки размеров багажа
              ..._buildBaggageCards(theme),

              const SizedBox(height: 24),

              // Итоговая стоимость
              _buildTotalCostCard(theme),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBaggageCards(CustomTheme theme) {
    final List<Widget> cards = [];

    for (final size in [
      BaggageSize.s,
      BaggageSize.m,
      BaggageSize.l,
      BaggageSize.custom,
    ]) {
      cards.add(_buildBaggageCard(size, theme));
      cards.add(const SizedBox(height: 16));
    }

    return cards;
  }

  Widget _buildBaggageCard(BaggageSize size, CustomTheme theme) {
    final quantity = _quantities[size] ?? 0;
    final pricePerExtra = _prices[size] ?? 0.0;

    // Определяем, является ли этот размер первым в общем списке выбранного багажа
    bool isFirstBaggage = _isFirstBaggageSize(size);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: quantity > 0
            ? Border.all(color: CupertinoColors.activeBlue, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Иконка размера
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getSizeColor(size),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSizeIcon(size),
                  color: CupertinoColors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // Информация о размере
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getSizeTitle(size),
                      style: TextStyle(
                        color: theme.label,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getSizeDimensions(size),
                      style: TextStyle(
                        color: theme.secondaryLabel,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _getSizeExamples(size),
                      style: TextStyle(
                        color: theme.secondaryLabel,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Цена и статус
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quantity == 0)
                      Text(
                        'Не выбрано',
                        style: TextStyle(
                          color: theme.placeholderText,
                          fontSize: 14,
                        ),
                      )
                    // Для индивидуального (custom) багажа - особая логика
                    else if (size == BaggageSize.custom)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Цена уточняется диспетчером',
                            style: TextStyle(
                              color: CupertinoColors.systemOrange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'После оформления заказа с Вами свяжется диспетчер',
                            style: TextStyle(
                              color: theme.secondaryLabel,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    else if (isFirstBaggage && quantity == 1)
                      // Если это первый размер и выбран ровно 1 багаж - показываем бесплатно
                      Text(
                        'БЕСПЛАТНО',
                        style: TextStyle(
                          color: CupertinoColors.activeGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (isFirstBaggage && quantity > 1)
                      // Если это первый размер, но багажей больше 1
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'БЕСПЛАТНО + ${quantity - 1} доп.',
                            style: TextStyle(
                              color: theme.label,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (pricePerExtra > 0)
                            Text(
                              'Доп. багаж: ${((quantity - 1) * pricePerExtra).toStringAsFixed(0)}₽',
                              style: TextStyle(
                                color: theme.secondaryLabel,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      )
                    else
                      // Это не первый размер - все багажи платные
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pricePerExtra.toStringAsFixed(0)}₽',
                            style: TextStyle(
                              color: theme.label,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (quantity > 1)
                            Text(
                              'Всего: ${(quantity * pricePerExtra).toStringAsFixed(0)}₽',
                              style: TextStyle(
                                color: theme.secondaryLabel,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),

              // Кнопки управления количеством
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: quantity > 0
                        ? () => _updateQuantity(size, quantity - 1)
                        : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: quantity > 0
                            ? CupertinoColors.systemRed
                            : theme.quaternaryLabel,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        CupertinoIcons.minus,
                        color: CupertinoColors.white,
                        size: 18,
                      ),
                    ),
                  ),

                  Container(
                    width: 40,
                    child: Text(
                      quantity.toString(),
                      style: TextStyle(
                        color: theme.label,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: quantity < 10
                        ? () {
                            if (size == BaggageSize.custom && quantity == 0) {
                              _showCustomBaggageDialog();
                            }
                            _updateQuantity(size, quantity + 1);
                          }
                        : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: quantity < 10
                            ? CupertinoColors.activeBlue
                            : theme.quaternaryLabel,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        CupertinoIcons.plus,
                        color: CupertinoColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Кнопка настройки для custom багажа
          if (size == BaggageSize.custom && quantity > 0) ...[
            const SizedBox(height: 12),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showCustomBaggageDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Указать габариты и описание',
                  style: TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalCostCard(CustomTheme theme) {
    final totalCost = _calculateTotalCost();
    final hasFreeBaggage = _quantities.values.any((q) => q > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Бесплатный багаж:',
                style: TextStyle(color: theme.label, fontSize: 16),
              ),
              Text(
                hasFreeBaggage ? 'Включен' : 'Не выбран',
                style: TextStyle(
                  color: hasFreeBaggage
                      ? CupertinoColors.activeGreen
                      : theme.placeholderText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          if (totalCost > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Дополнительный багаж:',
                  style: TextStyle(color: theme.label, fontSize: 16),
                ),
                Text(
                  '${totalCost.toStringAsFixed(0)}₽',
                  style: TextStyle(
                    color: theme.label,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Вспомогательные методы для отображения информации о размерах
  String _getSizeTitle(BaggageSize size) {
    switch (size) {
      case BaggageSize.s:
        return 'Размер S (Малый)';
      case BaggageSize.m:
        return 'Размер M (Средний)';
      case BaggageSize.l:
        return 'Размер L (Большой)';
      case BaggageSize.custom:
        return 'Индивидуальный';
    }
  }

  String _getSizeDimensions(BaggageSize size) {
    switch (size) {
      case BaggageSize.s:
        return '30×40×20 см (до 10 кг)';
      case BaggageSize.m:
        return '50×60×25 см (до 20 кг)';
      case BaggageSize.l:
        return '70×80×30 см (до 32 кг)';
      case BaggageSize.custom:
        return 'Любые габариты';
    }
  }

  String _getSizeExamples(BaggageSize size) {
    switch (size) {
      case BaggageSize.s:
        return 'Рюкзак, небольшая сумка';
      case BaggageSize.m:
        return 'Спортивная сумка, средний чемодан';
      case BaggageSize.l:
        return 'Большой чемодан, коробка';
      case BaggageSize.custom:
        return 'Гитара, микроволновка, нестандартные предметы';
    }
  }

  IconData _getSizeIcon(BaggageSize size) {
    switch (size) {
      case BaggageSize.s:
        return CupertinoIcons.bag;
      case BaggageSize.m:
        return CupertinoIcons.bag_fill;
      case BaggageSize.l:
        return CupertinoIcons.cube_box;
      case BaggageSize.custom:
        return CupertinoIcons.cube;
    }
  }

  Color _getSizeColor(BaggageSize size) {
    switch (size) {
      case BaggageSize.s:
        return CupertinoColors.activeGreen;
      case BaggageSize.m:
        return CupertinoColors.activeBlue;
      case BaggageSize.l:
        return CupertinoColors.systemOrange;
      case BaggageSize.custom:
        return CupertinoColors.systemPurple;
    }
  }
}
