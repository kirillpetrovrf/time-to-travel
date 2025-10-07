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
    print('🧳 [БАГАЖ] Инициализация количеств багажа');
    print(
      '🧳 [БАГАЖ] Начальный багаж: ${widget.initialBaggage.length} предметов',
    );

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
      print(
        '🧳 [БАГАЖ] Загружен ${item.size.name.toUpperCase()}: ${item.quantity} шт, цена: ${item.pricePerExtraItem}₽/шт',
      );
      if (item.size == BaggageSize.custom) {
        _customDescriptionController.text = item.customDescription ?? '';
        _customDimensionsController.text = item.customDimensions ?? '';
      }
    }

    print(
      '🧳 [БАГАЖ] Итоговые количества: S=${_quantities[BaggageSize.s]}, M=${_quantities[BaggageSize.m]}, L=${_quantities[BaggageSize.l]}, Custom=${_quantities[BaggageSize.custom]}',
    );
  }

  Future<void> _loadPrices() async {
    print('💰 [БАГАЖ] Загрузка цен багажа...');
    try {
      final prices = await BaggagePricingService.getExtraBaggagePrices();
      print('💰 [БАГАЖ] Цены загружены успешно:');
      print('💰 [БАГАЖ]   S: ${prices[BaggageSize.s]}₽/шт');
      print('💰 [БАГАЖ]   M: ${prices[BaggageSize.m]}₽/шт');
      print('💰 [БАГАЖ]   L: ${prices[BaggageSize.l]}₽/шт');
      print('💰 [БАГАЖ]   Custom: ${prices[BaggageSize.custom]}₽/шт');
      if (mounted) {
        setState(() {
          _prices = prices;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [БАГАЖ] Ошибка загрузки цен: $e');
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
      final oldQuantity = _quantities[size] ?? 0;
      print(
        '➕➖ [БАГАЖ] Изменение количества ${size.name.toUpperCase()}: $oldQuantity → $newQuantity',
      );
      setState(() {
        _quantities[size] = newQuantity;
      });
      print(
        '📊 [БАГАЖ] Текущее состояние: S=${_quantities[BaggageSize.s]}, M=${_quantities[BaggageSize.m]}, L=${_quantities[BaggageSize.l]}, Custom=${_quantities[BaggageSize.custom]}',
      );
      print(
        '📊 [БАГАЖ] Общее количество: ${_getTotalBaggageCount()} предметов',
      );
      print(
        '💵 [БАГАЖ] Общая стоимость: ${_calculateTotalCost().toStringAsFixed(0)}₽',
      );
    }
  }

  int _getTotalBaggageCount() {
    return _quantities.values.fold(0, (sum, quantity) => sum + quantity);
  }

  // Определяет количество бесплатных багажей для данного размера
  int _getFreeBaggageCount(BaggageSize size) {
    int totalCount = _getTotalBaggageCount();

    // Если ничего не выбрано - нет бесплатных
    if (totalCount == 0) {
      return 0;
    }

    final quantity = _quantities[size] ?? 0;
    if (quantity == 0) return 0;

    final sCount = _quantities[BaggageSize.s] ?? 0;
    final mCount = _quantities[BaggageSize.m] ?? 0;
    final lCount = _quantities[BaggageSize.l] ?? 0;
    final customCount = _quantities[BaggageSize.custom] ?? 0;

    bool hasMorL = (mCount > 0 || lCount > 0 || customCount > 0);

    // НОВАЯ ЛОГИКА v6.0:
    // - Только S: первые ДВА бесплатно
    // - Смешанный багаж: ВСЕ S платно, ОДИН M/L бесплатно

    if (size == BaggageSize.s) {
      // Для S: если ТОЛЬКО S, то 2 бесплатно, иначе ВСЕ платно
      if (!hasMorL) {
        return sCount >= 2 ? 2 : sCount;
      } else {
        return 0; // При смешанном багаже все S платно
      }
    } else if (size == BaggageSize.m) {
      // Для M: первый бесплатно (если есть M)
      // M имеет приоритет над L
      if (mCount > 0) {
        return 1;
      }
      return 0;
    } else if (size == BaggageSize.l) {
      // Для L: первый бесплатно только если нет M
      if (lCount > 0 && mCount == 0) {
        return 1;
      }
      return 0;
    } else if (size == BaggageSize.custom) {
      // Custom всегда платно
      return 0;
    }

    return 0;
  }

  double _calculateTotalCost() {
    print('💵 [БАГАЖ] ========== РАСЧЕТ СТОИМОСТИ ==========');
    // ФИНАЛЬНАЯ ЛОГИКА v6.0:
    // Если ТОЛЬКО S: первые 2 бесплатно, остальные по 500₽
    // Если есть M/L: ВСЕ S платно + один M/L бесплатно

    int totalBaggageCount = _getTotalBaggageCount();
    print('💵 [БАГАЖ] Общее количество багажа: $totalBaggageCount предметов');

    if (totalBaggageCount == 0) {
      print('💵 [БАГАЖ] Багаж не выбран, стоимость: 0₽');
      return 0.0;
    }

    final sCount = _quantities[BaggageSize.s] ?? 0;
    final mCount = _quantities[BaggageSize.m] ?? 0;
    final lCount = _quantities[BaggageSize.l] ?? 0;
    final customCount = _quantities[BaggageSize.custom] ?? 0;

    final sPrice = _prices[BaggageSize.s] ?? 500.0;
    final mPrice = _prices[BaggageSize.m] ?? 1000.0;
    final lPrice = _prices[BaggageSize.l] ?? 2000.0;
    final customPrice = _prices[BaggageSize.custom] ?? 0.0;

    bool hasMorL = (mCount > 0 || lCount > 0 || customCount > 0);

    print(
      '💵 [БАГАЖ] Состав: S=$sCount, M=$mCount, L=$lCount, Custom=$customCount',
    );
    print('💵 [БАГАЖ] Есть M/L/Custom: $hasMorL');

    double total = 0.0;

    // СЛУЧАЙ 1: Только S (особое правило)
    if (!hasMorL && sCount > 0) {
      print('💵 [БАГАЖ] --- Только S багажи ---');
      if (sCount <= 2) {
        print('💵 [БАГАЖ]   ✅ Все бесплатно (до 2-х S)');
      } else {
        total = (sCount - 2) * sPrice;
        print(
          '💵 [БАГАЖ]   ✅ 2 бесплатно + ${sCount - 2} платных = ${total.toStringAsFixed(0)}₽',
        );
      }
      print(
        '💵 [БАГАЖ] ========== ИТОГО: ${total.toStringAsFixed(0)}₽ ==========',
      );
      return total;
    }

    // СЛУЧАЙ 2: Есть разные размеры
    // ФИНАЛЬНАЯ ПРАВИЛЬНАЯ ЛОГИКА v7.0:
    // - ВСЕ S платно (без скидки)
    // - ОДИН M бесплатно
    // - При наличии и M и L: L со скидкой 50% (1000₽ вместо 2000₽)
    // - Если только L (без M): первый L бесплатно
    print('💵 [БАГАЖ] --- Смешанный багаж (S + M/L/Custom) ---');

    // Считаем платные S (все S платные при смешанном багаже)
    if (sCount > 0) {
      double cost = sCount * sPrice;
      total += cost;
      print(
        '💵 [БАГАЖ] Платные S: $sCount × ${sPrice.toStringAsFixed(0)}₽ = ${cost.toStringAsFixed(0)}₽',
      );
    }

    // Считаем платные M
    if (mCount > 0) {
      // Первый M бесплатно
      int freeMCount = 1;
      int paidM = mCount - freeMCount;
      if (paidM > 0) {
        double cost = paidM * mPrice;
        total += cost;
        print(
          '💵 [БАГАЖ] Платные M: $paidM × ${mPrice.toStringAsFixed(0)}₽ = ${cost.toStringAsFixed(0)}₽',
        );
      }
      print('💵 [БАГАЖ] Бесплатный M: $freeMCount шт');
    }

    // Считаем платные L
    if (lCount > 0) {
      // СПЕЦИАЛЬНАЯ ЛОГИКА:
      // - Если есть M: L со скидкой 50% (1000₽)
      // - Если нет M: первый L бесплатно
      if (mCount > 0) {
        // Есть M - L со скидкой 50%
        double discountedLPrice = lPrice / 2;
        double cost = lCount * discountedLPrice;
        total += cost;
        print(
          '💵 [БАГАЖ] Платные L (со скидкой 50%): $lCount × ${discountedLPrice.toStringAsFixed(0)}₽ = ${cost.toStringAsFixed(0)}₽',
        );
      } else {
        // Нет M - первый L бесплатно
        int freeLCount = 1;
        int paidL = lCount - freeLCount;
        if (paidL > 0) {
          double cost = paidL * lPrice;
          total += cost;
          print(
            '💵 [БАГАЖ] Платные L: $paidL × ${lPrice.toStringAsFixed(0)}₽ = ${cost.toStringAsFixed(0)}₽',
          );
        }
        print('💵 [БАГАЖ] Бесплатный L: $freeLCount шт');
      }
    }

    // Custom всегда платно
    if (customCount > 0) {
      double cost = customCount * customPrice;
      total += cost;
      print(
        '💵 [БАГАЖ] Custom: $customCount × ${customPrice.toStringAsFixed(0)}₽ = ${cost.toStringAsFixed(0)}₽',
      );
    }

    print(
      '💵 [БАГАЖ] ========== ИТОГО: ${total.toStringAsFixed(0)}₽ ==========',
    );

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
            final baggageList = _buildBaggageList();
            print('');
            print('✅ [БАГАЖ] ========== ПОДТВЕРЖДЕНИЕ ВЫБОРА ==========');
            print('✅ [БАГАЖ] Пользователь нажал "Готово"');
            print('✅ [БАГАЖ] Выбрано предметов: ${_getTotalBaggageCount()}');
            for (var item in baggageList) {
              print(
                '✅ [БАГАЖ]   • ${item.size.name.toUpperCase()}: ${item.quantity} шт, цена за доп: ${item.pricePerExtraItem.toStringAsFixed(0)}₽',
              );
            }
            print(
              '✅ [БАГАЖ] Итоговая стоимость: ${_calculateTotalCost().toStringAsFixed(0)}₽',
            );
            print('✅ [БАГАЖ] ==========================================');
            print('');
            widget.onBaggageSelected(baggageList);
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
                      'БЕСПЛАТНЫЙ БАГАЖ',
                      style: TextStyle(
                        color: CupertinoColors.activeGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Только S: 2 бесплатно. S + M/L: по 1 бесплатно',
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

              // Информационное сообщение о дополнительной оплате
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
                              'Только S: 2 бесплатно. S + M/L: по 1 бесплатно',
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

    // Определяем количество бесплатных багажей для этого размера
    int freeCount = _getFreeBaggageCount(size);
    int paidCount = quantity - freeCount;

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
                    // Все багажи бесплатные (S багажи в пределах 2-х)
                    else if (freeCount > 0 && paidCount == 0)
                      Text(
                        freeCount == 1
                            ? 'БЕСПЛАТНО'
                            : 'БЕСПЛАТНО (${freeCount} шт)',
                        style: TextStyle(
                          color: CupertinoColors.activeGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    // Есть и бесплатные, и платные (например, 2 бесплатных S + 3 платных S)
                    else if (freeCount > 0 && paidCount > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'БЕСПЛАТНО (${freeCount}) + ${paidCount} доп.',
                            style: TextStyle(
                              color: theme.label,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (pricePerExtra > 0)
                            Text(
                              'Доп. багаж: ${(paidCount * pricePerExtra).toStringAsFixed(0)}₽',
                              style: TextStyle(
                                color: theme.secondaryLabel,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      )
                    // Все багажи платные (не S, или S больше 2-х)
                    else
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
