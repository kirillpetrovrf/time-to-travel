import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/trip_type.dart';

class PricingSettingsWidget extends StatefulWidget {
  final dynamic theme;

  const PricingSettingsWidget({super.key, required this.theme});

  @override
  State<PricingSettingsWidget> createState() => _PricingSettingsWidgetState();
}

class _PricingSettingsWidgetState extends State<PricingSettingsWidget> {
  final TextEditingController _groupPriceController = TextEditingController();
  final TextEditingController _individualPriceController =
      TextEditingController();
  final TextEditingController _individualNightPriceController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentPrices();
  }

  void _loadCurrentPrices() {
    _groupPriceController.text = TripPricing.groupTripPrice.toString();
    _individualPriceController.text = TripPricing.individualTripPrice
        .toString();
    _individualNightPriceController.text = TripPricing.individualTripNightPrice
        .toString();
  }

  @override
  void dispose() {
    _groupPriceController.dispose();
    _individualPriceController.dispose();
    _individualNightPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Настройка цен'),
          const SizedBox(height: 16),

          _buildPriceCard(
            'Групповая поездка',
            'Поездка в микроавтобусе с другими пассажирами',
            _groupPriceController,
            CupertinoIcons.person_3,
          ),

          const SizedBox(height: 16),

          _buildPriceCard(
            'Индивидуальная поездка (день)',
            'Поездка в легковом автомобиле до 22:00',
            _individualPriceController,
            CupertinoIcons.car,
          ),

          const SizedBox(height: 16),

          _buildPriceCard(
            'Индивидуальная поездка (ночь)',
            'Поездка в легковом автомобиле после 22:00',
            _individualNightPriceController,
            CupertinoIcons.moon,
          ),

          const SizedBox(height: 24),

          _buildDiscountSection(),

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
                  onPressed: _savePrices,
                  child: const Text('Сохранить изменения'),
                ),
              ),
            ],
          ),
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

  Widget _buildPriceCard(
    String title,
    String description,
    TextEditingController controller,
    IconData icon,
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
              Icon(icon, color: widget.theme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.theme.label,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            description,
            style: TextStyle(fontSize: 14, color: widget.theme.secondaryLabel),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  placeholder: 'Цена в рублях',
                  style: TextStyle(color: widget.theme.label),
                  decoration: BoxDecoration(
                    color: widget.theme.systemBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.theme.separator.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: widget.theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₽',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.theme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Скидки и акции',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.theme.label,
            ),
          ),
          const SizedBox(height: 12),

          _buildDiscountItem('Скидка для постоянных клиентов', '10%', true),
          _buildDiscountItem('Скидка за раннее бронирование', '5%', false),
          _buildDiscountItem('Скидка для групп от 5 человек', '15%', true),

          const SizedBox(height: 16),

          CupertinoButton(
            color: widget.theme.primary,
            child: const Text('Настроить скидки'),
            onPressed: _showDiscountSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountItem(String title, String discount, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isActive
                ? CupertinoIcons.check_mark_circled_solid
                : CupertinoIcons.circle,
            color: isActive
                ? CupertinoColors.systemGreen
                : widget.theme.secondaryLabel,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 14, color: widget.theme.label),
            ),
          ),
          Text(
            discount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.theme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _savePrices() {
    // Здесь будет логика сохранения цен в базе данных
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Успешно!'),
        content: const Text('Цены успешно обновлены'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
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
              _loadCurrentPrices();
            },
          ),
        ],
      ),
    );
  }

  void _showDiscountSettings() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Настройка скидок'),
        content: const Text(
          'Функция настройки скидок будет доступна в следующем обновлении',
        ),
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
