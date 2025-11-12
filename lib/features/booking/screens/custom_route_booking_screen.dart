import 'package:flutter/cupertino.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';
import '../../../services/yandex_maps_service.dart';
import '../../../services/price_calculator_service.dart';
import '../../../services/calculator_settings_service.dart';
import '../../../models/calculator_settings.dart';
import '../../../models/price_calculation.dart';

/// Экран "Свободный маршрут" с калькулятором стоимости
class CustomRouteBookingScreen extends StatefulWidget {
  const CustomRouteBookingScreen({super.key});

  @override
  State<CustomRouteBookingScreen> createState() =>
      _CustomRouteBookingScreenState();
}

class _CustomRouteBookingScreenState extends State<CustomRouteBookingScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  final YandexMapsService _mapsService = YandexMapsService.instance;
  final PriceCalculatorService _priceService = PriceCalculatorService.instance;
  final CalculatorSettingsService _settingsService =
      CalculatorSettingsService.instance;

  bool _isCalculating = false;
  PriceCalculation? _calculation;
  double? _distanceKm;
  String? _errorMessage;
  CalculatorSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getSettings();
      setState(() {
        _settings = settings;
      });
    } catch (e) {
      print('❌ Ошибка загрузки настроек: $e');
      // Используем дефолтные настройки
      setState(() {
        _settings = CalculatorSettings.defaultSettings;
      });
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _calculateRoute() async {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();

    if (from.isEmpty || to.isEmpty) {
      setState(() {
        _errorMessage = 'Введите адреса отправления и назначения';
        _calculation = null;
      });
      return;
    }

    setState(() {
      _isCalculating = true;
      _errorMessage = null;
      _calculation = null;
    });

    try {
      print('🗺️ Начинаем расчет маршрута...');
      print('🗺️ Откуда: $from');
      print('🗺️ Куда: $to');

      // 1. Получаем маршрут через Yandex API
      final routeInfo = await _mapsService.calculateRoute(from, to);

      if (routeInfo == null) {
        throw Exception('Не удалось построить маршрут');
      }

      print('✅ Маршрут получен: ${routeInfo.distance} км');

      // 2. Рассчитываем стоимость
      final calculation = await _priceService.calculatePrice(
        routeInfo.distance,
      );

      print('💰 Стоимость: ${calculation.finalPrice}₽');

      setState(() {
        _calculation = calculation;
        _distanceKm = routeInfo.distance;
        _isCalculating = false;
      });
    } catch (e) {
      print('❌ Ошибка: $e');
      setState(() {
        _errorMessage = 'Не удалось построить маршрут: ${e.toString()}';
        _isCalculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text('Свободный маршрут', style: TextStyle(color: theme.label)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.info_circle, color: theme.primary),
          onPressed: () => _showInfoDialog(theme),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Информационная карточка
              _buildInfoCard(theme),

              const SizedBox(height: 24),

              // Поле "Откуда"
              _buildSectionTitle('Откуда', theme),
              _buildAddressField(
                controller: _fromController,
                placeholder: 'Адрес отправления',
                icon: CupertinoIcons.location,
                theme: theme,
              ),

              const SizedBox(height: 24),

              // Поле "Куда"
              _buildSectionTitle('Куда', theme),
              _buildAddressField(
                controller: _toController,
                placeholder: 'Адрес назначения',
                icon: CupertinoIcons.location_solid,
                theme: theme,
              ),

              const SizedBox(height: 24),

              // Кнопка расчета
              CupertinoButton.filled(
                onPressed: _isCalculating ? null : _calculateRoute,
                child: _isCalculating
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : const Text(
                        'Рассчитать стоимость',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Результат расчета или ошибка
              if (_errorMessage != null) _buildErrorCard(theme),
              if (_calculation != null) _buildResultCard(theme),

              // Отступ снизу для системных кнопок навигации
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, CustomTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: theme.label,
        ),
      ),
    );
  }

  Widget _buildInfoCard(CustomTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.map_pin_ellipse, color: theme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Калькулятор маршрута',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.label,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Введите адреса для расчета стоимости поездки',
                  style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    required CustomTheme theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        padding: const EdgeInsets.all(16),
        decoration: null,
        style: TextStyle(color: theme.label),
        placeholderStyle: TextStyle(
          color: theme.secondaryLabel.withOpacity(0.5),
        ),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Icon(icon, color: theme.primary, size: 20),
        ),
      ),
    );
  }

  Widget _buildErrorCard(CustomTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: CupertinoColors.systemRed,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(fontSize: 14, color: theme.label),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(CustomTheme theme) {
    final calc = _calculation!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: CupertinoColors.systemGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Маршрут рассчитан',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.label,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Расстояние
          _buildResultRow(
            icon: CupertinoIcons.arrow_right,
            label: 'Расстояние',
            value: '${_distanceKm!.toStringAsFixed(1)} км',
            theme: theme,
          ),

          const SizedBox(height: 12),

          // Формула расчета
          _buildResultRow(
            icon: CupertinoIcons.number,
            label: 'Расчет',
            value: calc.formula,
            theme: theme,
          ),

          const SizedBox(height: 20),

          Container(height: 1, color: theme.separator.withOpacity(0.5)),

          const SizedBox(height: 20),

          // Итоговая цена
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Стоимость поездки:',
                style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
              ),
              Text(
                '${calc.finalPrice} ₽',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
            ],
          ),

          // Пояснение
          if (calc.appliedMinPrice || calc.roundedUp) ...[
            const SizedBox(height: 12),
            if (calc.appliedMinPrice)
              _buildNotice(
                'Применена минимальная стоимость',
                CupertinoColors.systemOrange,
                theme,
              ),
            if (calc.roundedUp && !calc.appliedMinPrice)
              _buildNotice(
                'Цена округлена до тысяч вверх',
                CupertinoColors.systemBlue,
                theme,
              ),
          ],

          const SizedBox(height: 20),

          // Кнопка бронирования
          CupertinoButton.filled(
            onPressed: () => _bookTrip(),
            child: const Text(
              'Забронировать',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow({
    required IconData icon,
    required String label,
    required String value,
    required CustomTheme theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.label,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotice(String text, Color color, CustomTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.info_circle_fill, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: theme.label),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(CustomTheme theme) {
    final settings = _settings ?? CalculatorSettings.defaultSettings;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Как работает калькулятор?'),
        content: Text(
          '\nФормула расчета:\n\n'
          '${settings.baseCost}₽ (базовая стоимость)\n+ '
          '${settings.costPerKm}₽ × расстояние (км)\n\n'
          'Минимальная стоимость: ${settings.minPrice}₽\n\n'
          '${settings.roundToThousands ? "Округление до тысяч вверх" : "Без округления"}',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Понятно'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _bookTrip() {
    // TODO: Реализовать бронирование
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Бронирование'),
        content: const Text(
          'Функция бронирования в разработке.\n\nДля заказа свяжитесь с диспетчером.',
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
