import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../models/route_group.dart';
import '../../../models/predefined_route.dart';
import '../../../services/route_group_service.dart';
import '../../../services/route_management_service.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';
import '../widgets/route_in_group_item.dart';
import '../widgets/add_route_to_group_dialog.dart';

/// Экран деталей группы маршрутов с управлением ценами
class RouteGroupDetailsScreen extends StatefulWidget {
  final RouteGroup group;

  const RouteGroupDetailsScreen({
    super.key,
    required this.group,
  });

  @override
  State<RouteGroupDetailsScreen> createState() => _RouteGroupDetailsScreenState();
}

class _RouteGroupDetailsScreenState extends State<RouteGroupDetailsScreen> {
  final RouteGroupService _groupService = RouteGroupService.instance;
  final RouteManagementService _routeService = RouteManagementService.instance;
  
  final TextEditingController _priceController = TextEditingController();
  List<PredefinedRoute> _routes = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _priceController.text = widget.group.basePrice.toInt().toString();
    _loadRoutes();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    try {
      // Загружаем ВСЕ маршруты
      final allRoutes = await _routeService.getAllRoutes();
      
      // Фильтруем маршруты для этой группы
      final filteredRoutes = allRoutes.where((route) {
        // ВАЖНО: Сначала проверяем, назначен ли маршрут явно к этой группе по groupId
        if (route.groupId != null && route.groupId == widget.group.id) {
          return true;
        }
        
        // Если у группы нет городов — маршруты попадают только по groupId
        if (widget.group.originCities.isEmpty || widget.group.destinationCities.isEmpty) {
          return false;
        }
        
        final from = route.fromCity.toLowerCase().trim();
        final to = route.toCity.toLowerCase().trim();
        
        // Проверяем прямое направление: откуда -> куда
        final matchesOrigin = widget.group.originCities.any((city) => 
          from.contains(city.toLowerCase()) || city.toLowerCase().contains(from)
        );
        final matchesDestination = widget.group.destinationCities.any((city) => 
          to.contains(city.toLowerCase()) || city.toLowerCase().contains(to)
        );
        
        // Если включено автореверсирование, проверяем обратное направление
        if (widget.group.autoGenerateReverse) {
          final reverseMatchesOrigin = widget.group.destinationCities.any((city) => 
            from.contains(city.toLowerCase()) || city.toLowerCase().contains(from)
          );
          final reverseMatchesDestination = widget.group.originCities.any((city) => 
            to.contains(city.toLowerCase()) || city.toLowerCase().contains(to)
          );
          
          return (matchesOrigin && matchesDestination) || 
                 (reverseMatchesOrigin && reverseMatchesDestination);
        }
        
        return matchesOrigin && matchesDestination;
      }).toList();
      
      setState(() {
        _routes = filteredRoutes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError('Не удалось загрузить маршруты: $e');
      }
    }
  }

  Future<void> _applyGroupPrice() async {
    final newPrice = double.tryParse(_priceController.text);
    if (newPrice == null || newPrice <= 0) {
      _showError('Введите корректную цену');
      return;
    }

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Применить цену?'),
        content: Text(
          'Установить цену $newPrice ₽ для всех маршрутов с групповой ценой?\n\n'
          'Маршруты с индивидуальными ценами не изменятся.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Применить'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        // Обновляем цену группы
        await _groupService.updateGroupPrice(widget.group.id, newPrice);
        
        // Обновляем цены маршрутов
        await _routeService.updateGroupRoutes(widget.group.id, newPrice);
        
        setState(() => _isSaving = false);
        _loadRoutes();
        
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Успешно'),
              content: const Text('Цена группы обновлена'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        setState(() => _isSaving = false);
        _showError('Не удалось обновить цену: $e');
      }
    }
  }

  Future<void> _editRoutePrice(PredefinedRoute route) async {
    final controller = TextEditingController(text: route.price.toInt().toString());
    
    final newPrice = await showCupertinoDialog<double>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Изменить цену\n${route.fromCity} → ${route.toCity}'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            placeholder: 'Новая цена',
            suffix: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text('₽'),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Сохранить'),
            onPressed: () {
              final price = double.tryParse(controller.text);
              if (price != null && price > 0) {
                Navigator.of(context).pop(price);
              }
            },
          ),
        ],
      ),
    );

    controller.dispose();

    if (newPrice != null) {
      try {
        await _routeService.updateRoutePrice(route.id, newPrice);
        _loadRoutes();
      } catch (e) {
        _showError('Не удалось обновить цену маршрута: $e');
      }
    }
  }

  Future<void> _resetRouteToGroupPrice(PredefinedRoute route) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Вернуть групповую цену?'),
        content: Text(
          'Вернуть для маршрута ${route.fromCity} → ${route.toCity} групповую цену ${widget.group.basePrice.toInt()} ₽?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Вернуть'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _routeService.resetRouteToGroupPrice(route.id, widget.group.basePrice);
        _loadRoutes();
      } catch (e) {
        _showError('Не удалось вернуть групповую цену: $e');
      }
    }
  }

  Future<void> _addRoute() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      CupertinoPageRoute(
        builder: (context) => AddRouteToGroupDialog(
          defaultPrice: widget.group.basePrice,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      try {
        final fromCity = result['from'] as String;
        final toCity = result['to'] as String;
        final price = result['price'] as double;
        
        // ВАЖНО: Передаём groupId текущей группы, чтобы маршрут привязался к ней
        await _routeService.addRoute(
          fromCity: fromCity,
          toCity: toCity,
          price: price,
          groupId: widget.group.id,
        );
        _loadRoutes();
        
        // Показываем уведомление об успехе
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Успешно'),
            content: Text('Маршрут $fromCity → $toCity добавлен'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } catch (e) {
        _showError('Не удалось добавить маршрут: $e');
      }
    }
  }

  Future<void> _deleteRoute(PredefinedRoute route) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Удалить маршрут?'),
        content: Text(
          'Удалить маршрут ${route.fromCity} → ${route.toCity}?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Удалить'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _routeService.deleteRoute(route.id);
        _loadRoutes();
      } catch (e) {
        _showError('Не удалось удалить маршрут: $e');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    final groupPriceRoutes = _routes.where((r) => !r.customPrice).length;
    final customPriceRoutes = _routes.where((r) => r.customPrice).length;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.systemBackground,
        border: Border(bottom: BorderSide(color: theme.separator)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: theme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: Text(
          widget.group.name,
          style: TextStyle(color: theme.label),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.add_circled, color: theme.primary, size: 28),
          onPressed: _addRoute,
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Карточка управления ценой
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.secondarySystemBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.separator),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.money_dollar_circle,
                          color: theme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Базовая цена группы',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.label,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    CupertinoTextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      placeholder: 'Введите цену',
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          '₽',
                          style: TextStyle(
                            fontSize: 17,
                            color: theme.secondaryLabel,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 17,
                        color: theme.label,
                      ),
                      decoration: BoxDecoration(
                        color: theme.systemBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.separator),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: theme.primary,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _isSaving ? null : _applyGroupPrice,
                        child: _isSaving
                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : const Text(
                              'Применить ко всем маршрутам',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Статистика маршрутов
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.secondarySystemBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                      icon: CupertinoIcons.link,
                      label: 'Групповая цена',
                      value: groupPriceRoutes.toString(),
                      color: theme.primary,
                      theme: theme,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: theme.separator,
                    ),
                    _StatColumn(
                      icon: CupertinoIcons.pencil_circle,
                      label: 'Своя цена',
                      value: customPriceRoutes.toString(),
                      color: CupertinoColors.systemOrange,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),
            
            // Список маршрутов
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              )
            else if (_routes.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.location,
                        size: 64,
                        color: theme.tertiaryLabel,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет маршрутов в группе',
                        style: TextStyle(
                          fontSize: 17,
                          color: theme.secondaryLabel,
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
                    return RouteInGroupItem(
                      route: route,
                      onEdit: () => _editRoutePrice(route),
                      onReset: route.customPrice
                        ? () => _resetRouteToGroupPrice(route)
                        : null,
                      onDelete: () => _deleteRoute(route),
                    );
                  },
                  childCount: _routes.length,
                ),
              ),
            
            // Нижний отступ
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }
}

/// Колонка статистики
class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final CustomTheme theme;

  const _StatColumn({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.label,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.secondaryLabel,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
