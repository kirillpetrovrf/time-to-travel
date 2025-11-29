import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../services/baggage_pricing_service.dart';
import '../../../models/baggage.dart';

/// Виджет настройки цен на багаж (для админ-панели диспетчера)
class BaggagePricingSettingsWidget extends StatefulWidget {
  final dynamic theme;

  const BaggagePricingSettingsWidget({super.key, required this.theme});

  @override
  State<BaggagePricingSettingsWidget> createState() =>
      _BaggagePricingSettingsWidgetState();
}

class _BaggagePricingSettingsWidgetState
    extends State<BaggagePricingSettingsWidget> {
  final TextEditingController _sPriceController = TextEditingController();
  final TextEditingController _mPriceController = TextEditingController();
  final TextEditingController _lPriceController = TextEditingController();
  final TextEditingController _customPriceController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPrices();
  }

  Future<void> _loadCurrentPrices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prices = await BaggagePricingService.getExtraBaggagePrices();

      if (mounted) {
        setState(() {
          _sPriceController.text = prices[BaggageSize.s]!.toInt().toString();
          _mPriceController.text = prices[BaggageSize.m]!.toInt().toString();
          _lPriceController.text = prices[BaggageSize.l]!.toInt().toString();
          _customPriceController.text = prices[BaggageSize.custom]!
              .toInt()
              .toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Ошибка загрузки цен: $e');
      }
    }
  }

  @override
  void dispose() {
    _sPriceController.dispose();
    _mPriceController.dispose();
    _lPriceController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Настройка цен на дополнительный багаж'),
          const SizedBox(height: 8),
          _buildInfoBox(),
          const SizedBox(height: 24),

          _buildPriceCard(
            'Малый (S)',
            'До 10 кг, 55×40×20 см',
            _sPriceController,
            CupertinoIcons.bag,
            CupertinoColors.systemGreen,
          ),

          const SizedBox(height: 16),

          _buildPriceCard(
            'Средний (M)',
            'До 20 кг, 70×50×30 см',
            _mPriceController,
            CupertinoIcons.bag_fill,
            CupertinoColors.activeBlue,
          ),

          const SizedBox(height: 16),

          _buildPriceCard(
            'Большой (L)',
            'До 30 кг, 90×60×40 см',
            _lPriceController,
            CupertinoIcons.archivebox,
            CupertinoColors.systemOrange,
          ),

          const SizedBox(height: 16),

          _buildPriceCard(
            'Индивидуальный (Custom)',
            'Крупногабаритный груз (цена уточняется)',
            _customPriceController,
            CupertinoIcons.cube_box,
            CupertinoColors.systemPurple,
          ),

          const SizedBox(height: 24),

          _buildPricingRulesInfo(),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: widget.theme.secondarySystemBackground,
                  onPressed: _resetPrices,
                  child: Text(
                    'Сбросить',
                    style: TextStyle(color: widget.theme.label),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: _isSaving ? null : _savePrices,
                  child: _isSaving
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : const Text('Сохранить изменения'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 60), // Отступ снизу для навигации
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: widget.theme.label,
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.activeBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.info_circle_fill,
            color: CupertinoColors.activeBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Первый багаж любого размера включен бесплатно. Указанные цены применяются к дополнительному багажу.',
              style: TextStyle(fontSize: 14, color: widget.theme.label),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(
    String title,
    String description,
    TextEditingController controller,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.theme.label,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.theme.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  placeholder: 'Цена в рублях',
                  suffix: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '₽',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.theme.primary,
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: widget.theme.tertiarySystemBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.theme.separator.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRulesInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.book_fill,
                color: widget.theme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Правила ценообразования',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRuleItem('1 багажное место любого размера - БЕСПЛАТНО'),
          _buildRuleItem(
            'Все последующие места оплачиваются по указанным ценам',
          ),
          _buildRuleItem('Для Custom багажа цена уточняется индивидуально'),
          _buildRuleItem('Цены применяются автоматически при бронировании'),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.theme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: widget.theme.secondaryLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePrices() async {
    // Валидация
    final sPrice = double.tryParse(_sPriceController.text);
    final mPrice = double.tryParse(_mPriceController.text);
    final lPrice = double.tryParse(_lPriceController.text);
    final customPrice = double.tryParse(_customPriceController.text);

    if (sPrice == null ||
        mPrice == null ||
        lPrice == null ||
        customPrice == null) {
      _showError('Введите корректные числовые значения для всех полей');
      return;
    }

    if (sPrice < 0 || mPrice < 0 || lPrice < 0 || customPrice < 0) {
      _showError('Цены не могут быть отрицательными');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await BaggagePricingService.updateExtraBaggagePrices(
        sPricePerExtra: sPrice,
        mPricePerExtra: mPrice,
        lPricePerExtra: lPrice,
        customPricePerExtra: customPrice,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _showSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _showError('Ошибка сохранения: $e');
      }
    }
  }

  void _resetPrices() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Сброс цен'),
        content: const Text(
          'Вы уверены, что хотите вернуть цены к значениям по умолчанию?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Сбросить'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _sPriceController.text = BaggagePricingService
                    .defaultSPricePerExtra
                    .toInt()
                    .toString();
                _mPriceController.text = BaggagePricingService
                    .defaultMPricePerExtra
                    .toInt()
                    .toString();
                _lPriceController.text = BaggagePricingService
                    .defaultLPricePerExtra
                    .toInt()
                    .toString();
                _customPriceController.text = BaggagePricingService
                    .defaultCustomPricePerExtra
                    .toInt()
                    .toString();
              });
            },
          ),
        ],
      ),
    );
  }

  void _showSuccess() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Успешно!'),
        content: const Text('Цены на багаж успешно обновлены'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
