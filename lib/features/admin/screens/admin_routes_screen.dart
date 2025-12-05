import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/predefined_route.dart';
import '../../../models/route_group.dart';
import '../../../services/route_management_service.dart';
import '../../../widgets/simple_address_field.dart';
import '../../../data/route_groups_initializer.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';
import 'route_group_details_screen.dart';

/// Админ-панель для управления предустановленными маршрутами
class AdminRoutesScreen extends StatefulWidget {
  const AdminRoutesScreen({super.key});

  @override
  State<AdminRoutesScreen> createState() => _AdminRoutesScreenState();
}

class _AdminRoutesScreenState extends State<AdminRoutesScreen> {
  final RouteManagementService _routeService = RouteManagementService.instance;
  List<PredefinedRoute> _routes = [];
  List<RouteGroup> _groups = [];
  RouteGroup? _selectedGroup; // Выбранная группа для фильтрации
  bool _isLoading = true;
  String? _error;

  // Контроллеры для формы добавления
  final TextEditingController _fromCityController = TextEditingController();
  final TextEditingController _toCityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _loadRoutes();
  }

  @override
  void dispose() {
    _fromCityController.dispose();
    _toCityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = RouteGroupsInitializer.initialGroups;
      setState(() {
        _groups = groups;
      });
    } catch (e) {
      print('❌ Ошибка загрузки групп: $e');
    }
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
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;
    
    // Фильтрация маршрутов по выбранной группе
    final displayedRoutes = _selectedGroup == null
        ? _routes
        : _routes.where((route) {
            // Проверяем, входит ли маршрут в города группы
            final fromMatch = _selectedGroup!.originCities.any((city) =>
                city.toLowerCase() == route.fromCity.toLowerCase() ||
                route.fromCity.toLowerCase().contains(city.toLowerCase()));
            final toMatch = _selectedGroup!.destinationCities.any((city) =>
                city.toLowerCase() == route.toCity.toLowerCase() ||
                route.toCity.toLowerCase().contains(city.toLowerCase()));
            
            // Учитываем обратные маршруты
            if (_selectedGroup!.autoGenerateReverse) {
              final reverseFrom = _selectedGroup!.destinationCities.any((city) =>
                  city.toLowerCase() == route.fromCity.toLowerCase() ||
                  route.fromCity.toLowerCase().contains(city.toLowerCase()));
              final reverseTo = _selectedGroup!.originCities.any((city) =>
                  city.toLowerCase() == route.toCity.toLowerCase() ||
                  route.toCity.toLowerCase().contains(city.toLowerCase()));
              return (fromMatch && toMatch) || (reverseFrom && reverseTo);
            }
            
            return fromMatch && toMatch;
          }).toList();

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.systemBackground,
        middle: Text(
          'Управление маршрутами',
          style: TextStyle(color: theme.label),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Блок с группами маршрутов
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.secondarySystemBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.square_stack_3d_up,
                          color: theme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Группы маршрутов',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: theme.label,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: CupertinoIcons.square_stack_3d_up,
                          label: 'Групп',
                          value: _groups.length.toString(),
                          theme: theme,
                        ),
                        _StatItem(
                          icon: CupertinoIcons.location,
                          label: 'Маршрутов',
                          value: displayedRoutes.length.toString(),
                          theme: theme,
                        ),
                      ],
                    ),
                    if (_groups.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      // Фильтр "Все маршруты"
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedGroup = null;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedGroup == null
                                ? theme.primary.withOpacity(0.1)
                                : theme.systemBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedGroup == null
                                  ? theme.primary
                                  : theme.separator,
                              width: _selectedGroup == null ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.globe,
                                color: _selectedGroup == null
                                    ? theme.primary
                                    : theme.secondaryLabel,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Все маршруты',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: _selectedGroup == null
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: _selectedGroup == null
                                        ? theme.primary
                                        : theme.label,
                                  ),
                                ),
                              ),
                              Text(
                                '${_routes.length}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedGroup == null
                                      ? theme.primary
                                      : theme.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Список групп
                      ..._groups.map((group) => GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedGroup = _selectedGroup?.id == group.id
                                ? null
                                : group;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedGroup?.id == group.id
                                ? theme.primary.withOpacity(0.1)
                                : theme.systemBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedGroup?.id == group.id
                                  ? theme.primary
                                  : theme.separator,
                              width: _selectedGroup?.id == group.id ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.location_circle_fill,
                                color: _selectedGroup?.id == group.id
                                    ? theme.primary
                                    : theme.secondaryLabel,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: _selectedGroup?.id == group.id
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: _selectedGroup?.id == group.id
                                            ? theme.primary
                                            : theme.label,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${group.uniqueRoutesCount} маршрутов',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.secondaryLabel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: Icon(
                                  CupertinoIcons.chevron_right,
                                  color: theme.secondaryLabel,
                                  size: 20,
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          RouteGroupDetailsScreen(group: group),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),

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
                      _selectedGroup == null
                          ? 'Все маршруты (${displayedRoutes.length})'
                          : '${_selectedGroup!.name} (${displayedRoutes.length})',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: theme.label,
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _loadRoutes,
                      child: Icon(CupertinoIcons.refresh, color: theme.primary),
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
                      Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 48,
                        color: theme.systemRed,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ошибка загрузки:\n$_error',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.systemRed,
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
            else if (displayedRoutes.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.map,
                        size: 48,
                        color: theme.secondaryLabel,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedGroup == null
                            ? 'Нет маршрутов'
                            : 'Нет маршрутов в группе "${_selectedGroup!.name}"',
                        style: TextStyle(
                          fontSize: 16,
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
                    final route = displayedRoutes[index];
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: CupertinoListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            CupertinoIcons.location_circle,
                            color: theme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '${route.fromCity} → ${route.toCity}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.label,
                          ),
                        ),
                        subtitle: Text(
                          '${route.price.toStringAsFixed(0)}₽',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.systemGreen,
                          ),
                        ),
                        additionalInfo: Text(
                          'ID: ${route.id.length > 8 ? route.id.substring(0, 8) : route.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.secondaryLabel,
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: displayedRoutes.length,
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

/// Виджет статистики
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final CustomTheme theme;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: theme.primary, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.label,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.secondaryLabel,
          ),
        ),
      ],
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