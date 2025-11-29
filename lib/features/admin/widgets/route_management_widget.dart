import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../services/route_management_service.dart';
import '../../../models/predefined_route.dart';
import '../../../widgets/simple_address_field.dart';

/// Виджет для управления фиксированными маршрутами в админ-панели
class RouteManagementWidget extends StatefulWidget {
  final dynamic theme;

  const RouteManagementWidget({super.key, required this.theme});

  @override
  State<RouteManagementWidget> createState() => _RouteManagementWidgetState();
}

class _RouteManagementWidgetState extends State<RouteManagementWidget> {
  final RouteManagementService _routeService = RouteManagementService.instance;
  
  List<PredefinedRoute> _routes = [];
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Данные для добавления нового маршрута
  String _selectedFromCity = '';
  String _selectedToCity = '';
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }
  
  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final routes = await _routeService.getAllRoutes(forceRefresh: true);
      if (mounted) {
        setState(() {
          _routes = routes;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Показываем менее пугающее сообщение и все равно пытаемся загрузить локальные данные
      print('⚠️ Ошибка загрузки из Firebase, используем локальные данные: $e');
      try {
        final routes = await _routeService.getAllRoutes(forceRefresh: false);
        if (mounted) {
          setState(() {
            _routes = routes;
            _isLoading = false;
          });
        }
      } catch (localError) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showError('Ошибка загрузки маршрутов: $localError');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildAddRouteSection(),
          const SizedBox(height: 32),
          _buildRoutesListSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Управление маршрутами',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: widget.theme.label,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.theme.systemBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.theme.systemBlue.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.info_circle,
                color: widget.theme.systemBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Здесь вы можете добавлять новые маршруты и устанавливать фиксированные цены. Изменения автоматически синхронизируются с клиентским приложением.',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.theme.label,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddRouteSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.theme.separator,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.add_circled,
                color: widget.theme.systemGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Добавить новый маршрут',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 🔧 РАБОЧИЙ SimpleAddressField для "Откуда"
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
          const SizedBox(height: 12),
          
          // 🔧 РАБОЧИЙ SimpleAddressField для "Куда"
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
          const SizedBox(height: 12),
          
          _buildInputField(
            'Цена (₽)',
            _priceController,
            'Например: 50000',
            CupertinoIcons.money_dollar_circle,
            isNumeric: true,
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _isSaving ? null : _addRoute,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CupertinoActivityIndicator(color: Colors.white),
                    )
                  : const Text('Добавить маршрут'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String placeholder,
    IconData icon, {
    bool isNumeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: widget.theme.label,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.theme.systemBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.theme.separator),
          ),
          prefix: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(
              icon,
              color: widget.theme.secondaryLabel,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutesListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Существующие маршруты',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: widget.theme.label,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: widget.theme.systemBlue,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.refresh, size: 16),
                  const SizedBox(width: 4),
                  const Text('Обновить'),
                ],
              ),
              onPressed: _loadRoutes,
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CupertinoActivityIndicator(),
            ),
          )
        else if (_routes.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: widget.theme.secondarySystemBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  CupertinoIcons.arrow_right_circle,
                  size: 48,
                  color: widget.theme.secondaryLabel,
                ),
                const SizedBox(height: 16),
                Text(
                  'Маршруты не найдены',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.theme.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавьте первый маршрут с помощью формы выше',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.theme.tertiaryLabel,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _routes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildRouteCard(_routes[index]),
          ),
      ],
    );
  }

  Widget _buildRouteCard(PredefinedRoute route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.theme.separator),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.theme.systemBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.arrow_right,
              color: widget.theme.systemBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${route.fromCity} → ${route.toCity}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.theme.label,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${route.price.toStringAsFixed(0)}₽',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.systemGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Создан: ${_formatDate(route.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.theme.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            child: Icon(
              CupertinoIcons.pencil_circle,
              color: widget.theme.warning,
            ),
            onPressed: () => _editRoute(route),
          ),
          
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            child: Icon(
              CupertinoIcons.delete,
              color: widget.theme.danger,
            ),
            onPressed: () => _confirmDeleteRoute(route),
          ),
        ],
      ),
    );
  }

  Future<void> _addRoute() async {
    final fromCity = _selectedFromCity.trim();
    final toCity = _selectedToCity.trim();
    final priceText = _priceController.text.trim();

    if (fromCity.isEmpty || toCity.isEmpty || priceText.isEmpty) {
      _showError('Заполните все поля');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showError('Введите корректную цену');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _routeService.addRoute(
        fromCity: fromCity,
        toCity: toCity,
        price: price,
      );

      // Очищаем форму
      setState(() {
        _selectedFromCity = '';
        _selectedToCity = '';
      });
      _priceController.clear();

      // Перезагружаем список
      await _loadRoutes();

      _showSuccess('Маршрут "$fromCity → $toCity" добавлен');
    } catch (e) {
      _showError('Маршрут добавлен локально. Firebase недоступен: $e');
      // Все равно очищаем форму и перезагружаем, так как данные могут быть сохранены локально
      setState(() {
        _selectedFromCity = '';
        _selectedToCity = '';
      });
      _priceController.clear();
      await _loadRoutes();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _editRoute(PredefinedRoute route) async {
    // Показываем диалог редактирования
    final result = await showCupertinoDialog(
      context: context,
      builder: (context) => _EditRouteDialog(
        route: route,
        theme: widget.theme,
      ),
    );

    if (result != null) {
      try {
        final updatedRoute = route.copyWith(
          fromCity: result['fromCity'],
          toCity: result['toCity'], 
          price: result['price'],
        );
        
        await _routeService.updateRoute(updatedRoute);

        await _loadRoutes();
        _showSuccess('Маршрут обновлён');
      } catch (e) {
        _showError('Ошибка обновления маршрута: $e');
      }
    }
  }

  Future<void> _confirmDeleteRoute(PredefinedRoute route) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Удалить маршрут'),
        content: Text('Вы уверены, что хотите удалить маршрут "${route.fromCity} → ${route.toCity}"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Удалить'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _routeService.deleteRoute(route.id);
        await _loadRoutes();
        _showSuccess('Маршрут удалён');
      } catch (e) {
        _showError('Ошибка удаления маршрута: $e');
      }
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
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Успешно'),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Диалог для редактирования маршрута
class _EditRouteDialog extends StatefulWidget {
  final PredefinedRoute route;
  final dynamic theme;

  const _EditRouteDialog({required this.route, required this.theme});

  @override
  State<_EditRouteDialog> createState() => _EditRouteDialogState();
}

class _EditRouteDialogState extends State<_EditRouteDialog> {
  late String _selectedFromCity;
  late String _selectedToCity;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _selectedFromCity = widget.route.fromCity;
    _selectedToCity = widget.route.toCity;
    _priceController = TextEditingController(text: widget.route.price.toInt().toString());
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Редактировать маршрут'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          
          CupertinoTextField(
            placeholder: 'Откуда',
            controller: TextEditingController(text: _selectedFromCity),
            onChanged: (value) => _selectedFromCity = value,
            padding: const EdgeInsets.all(12),
          ),
          const SizedBox(height: 8),
          
          CupertinoTextField(
            placeholder: 'Куда', 
            controller: TextEditingController(text: _selectedToCity),
            onChanged: (value) => _selectedToCity = value,
            padding: const EdgeInsets.all(12),
          ),
          const SizedBox(height: 8),
          
          CupertinoTextField(
            controller: _priceController,
            placeholder: 'Цена (₽)',
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.all(12),
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
            final fromCity = _selectedFromCity.trim();
            final toCity = _selectedToCity.trim();
            final price = double.tryParse(_priceController.text.trim());

            if (fromCity.isEmpty || toCity.isEmpty || price == null || price <= 0) {
              return;
            }

            Navigator.pop(context, {
              'fromCity': fromCity,
              'toCity': toCity,
              'price': price,
            });
          },
        ),
      ],
    );
  }
}