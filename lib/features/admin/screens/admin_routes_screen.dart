import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/predefined_route.dart';
import '../../../services/route_management_service.dart';
import '../../../widgets/simple_address_field.dart';

/// Админ-панель для управления предустановленными маршрутами
class AdminRoutesScreen extends StatefulWidget {
  const AdminRoutesScreen({super.key});

  @override
  State<AdminRoutesScreen> createState() => _AdminRoutesScreenState();
}

class _AdminRoutesScreenState extends State<AdminRoutesScreen> {
  final RouteManagementService _routeService = RouteManagementService.instance;
  List<PredefinedRoute> _routes = [];
  bool _isLoading = true;
  String? _error;

  // Контроллеры для формы добавления
  final TextEditingController _fromCityController = TextEditingController();
  final TextEditingController _toCityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  @override
  void dispose() {
    _fromCityController.dispose();
    _toCityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final routes = await _routeService.getAllRoutes(forceRefresh: true);
      
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addRoute() async {
    final fromCity = _fromCityController.text.trim();
    final toCity = _toCityController.text.trim();
    final priceText = _priceController.text.trim();

    if (fromCity.isEmpty || toCity.isEmpty || priceText.isEmpty) {
      _showError('Все поля должны быть заполнены');
      return;
    }

    final double? price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showError('Цена должна быть положительным числом');
      return;
    }

    try {
      await _routeService.addRoute(
        fromCity: fromCity,
        toCity: toCity,
        price: price,
      );

      _fromCityController.clear();
      _toCityController.clear();
      _priceController.clear();

      _showSuccess('Маршрут добавлен успешно!');
      _loadRoutes();
    } catch (e) {
      _showError('Ошибка добавления: $e');
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Успех'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Админ: Управление маршрутами'),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Форма добавления нового маршрута
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Добавить новый маршрут',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SimpleAddressField(
                      label: 'Город отправления',
                      initialValue: _fromCityController.text,
                      onAddressSelected: (address) {
                        print('📍 [ADMIN] Выбран FROM город: "$address"');
                        _fromCityController.text = address;
                      },
                    ),
                    const SizedBox(height: 12),
                    SimpleAddressField(
                      label: 'Город назначения',
                      initialValue: _toCityController.text,
                      onAddressSelected: (address) {
                        print('📍 [ADMIN] Выбран TO город: "$address"');
                        _toCityController.text = address;
                      },
                    ),
                    const SizedBox(height: 12),
                    CupertinoTextField(
                      controller: _priceController,
                      placeholder: 'Цена (₽)',
                      keyboardType: TextInputType.number,
                      padding: const EdgeInsets.all(12),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: CupertinoColors.activeBlue,
                        onPressed: _addRoute,
                        child: const Text('Добавить маршрут'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Заголовок списка
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Маршруты (${_routes.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _loadRoutes,
                      child: const Icon(CupertinoIcons.refresh),
                    ),
                  ],
                ),
              ),
            ),

            // Список маршрутов
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CupertinoActivityIndicator(),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 48,
                        color: CupertinoColors.systemRed,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ошибка загрузки:\n$_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        onPressed: _loadRoutes,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_routes.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.map,
                        size: 48,
                        color: CupertinoColors.systemGrey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Нет предустановленных маршрутов',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final route = _routes[index];
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: CupertinoListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            CupertinoIcons.location_circle,
                            color: CupertinoColors.activeBlue,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '${route.fromCity} → ${route.toCity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${route.price.toStringAsFixed(0)}₽',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.activeGreen,
                          ),
                        ),
                        additionalInfo: Text(
                          'ID: ${route.id.length > 8 ? route.id.substring(0, 8) : route.id}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _routes.length,
                ),
              ),

            // Отступ внизу
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }
}

/// Виджет для отображения элемента списка в стиле Cupertino
class CupertinoListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? additionalInfo;
  final VoidCallback? onTap;

  const CupertinoListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.additionalInfo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CupertinoColors.systemGrey5),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) title!,
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    subtitle!,
                  ],
                  if (additionalInfo != null) ...[
                    const SizedBox(height: 4),
                    additionalInfo!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}