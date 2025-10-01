import 'package:flutter/cupertino.dart';
import '../../../models/route_stop.dart';
import '../../../services/route_service.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_navigation_bar.dart';

class RouteSelectionScreen extends StatefulWidget {
  final String routeDirection;
  final Function(RouteStop fromStop, RouteStop toStop) onRouteSelected;

  const RouteSelectionScreen({
    super.key,
    required this.routeDirection,
    required this.onRouteSelected,
  });

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  final RouteService _routeService = RouteService.instance;
  RouteStop? _fromStop;
  RouteStop? _toStop;

  List<RouteStop> get _allStops =>
      _routeService.getRouteStops(widget.routeDirection);
  List<RouteStop> get _popularStops =>
      _routeService.getPopularStops(widget.routeDirection);

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      child: Column(
        children: [
          // Кастомный navigationBar с серым фоном
          CustomNavigationBar(
            title: 'Выбор маршрута',
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              child: Icon(CupertinoIcons.back, color: theme.systemRed),
            ),
          ),
          // Контент
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Заголовок маршрута
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _routeService.getRouteName(widget.routeDirection),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.label,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Выберите точки отправления и назначения',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.secondaryLabel,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Быстрый выбор популярных маршрутов
                if (_popularStops.length >= 2) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Популярные маршруты',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.label,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _getPopularRoutes().length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final route = _getPopularRoutes()[index];
                        return _PopularRouteCard(
                          fromStop: route['from']!,
                          toStop: route['to']!,
                          theme: theme,
                          onTap: () {
                            setState(() {
                              _fromStop = route['from']!;
                              _toStop = route['to']!;
                            });
                          },
                          isSelected:
                              _fromStop?.id == route['from']!.id &&
                              _toStop?.id == route['to']!.id,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Выбор отправления и назначения
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Или выберите точки вручную',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.label,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Откуда
                      _buildStopSelector(
                        title: 'Откуда',
                        selectedStop: _fromStop,
                        onTap: () => _showStopPicker(true),
                        theme: theme,
                      ),

                      const SizedBox(height: 12),

                      // Кнопка смены направления
                      Center(
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          onPressed: _swapStops,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.secondarySystemBackground,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              CupertinoIcons.arrow_up_arrow_down,
                              color: theme.systemRed,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Куда
                      _buildStopSelector(
                        title: 'Куда',
                        selectedStop: _toStop,
                        onTap: () => _showStopPicker(false),
                        theme: theme,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Информация о маршруте и кнопка продолжения
                if (_fromStop != null && _toStop != null) ...[
                  Container(
                    margin: const EdgeInsets.all(16),
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
                              'Расстояние:',
                              style: TextStyle(color: theme.secondaryLabel),
                            ),
                            Text(
                              '${_routeService.getEstimatedDistance(_fromStop!, _toStop!).toInt()} км',
                              style: TextStyle(
                                color: theme.label,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Время в пути:',
                              style: TextStyle(color: theme.secondaryLabel),
                            ),
                            Text(
                              _formatDuration(
                                _routeService.getEstimatedTravelTime(
                                  _fromStop!,
                                  _toStop!,
                                ),
                              ),
                              style: TextStyle(
                                color: theme.label,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Стоимость:',
                              style: TextStyle(color: theme.secondaryLabel),
                            ),
                            Text(
                              '${_routeService.getPriceBetweenStops(_fromStop!, _toStop!)} ₽',
                              style: TextStyle(
                                color: theme.systemRed,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Кнопка продолжения
                  Container(
                    margin: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: CupertinoButton(
                      color: theme.systemRed,
                      onPressed: () {
                        widget.onRouteSelected(_fromStop!, _toStop!);
                      },
                      child: const Text(
                        'Продолжить',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopSelector({
    required String title,
    required RouteStop? selectedStop,
    required VoidCallback onTap,
    required CustomTheme theme,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedStop != null ? theme.systemRed : theme.separator,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedStop?.name ?? 'Выберите город',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: selectedStop != null
                          ? theme.label
                          : theme.tertiaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: theme.tertiaryLabel,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showStopPicker(bool isFromStop) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _StopPickerModal(
        stops: _allStops,
        selectedStop: isFromStop ? _fromStop : _toStop,
        excludeStop: isFromStop ? _toStop : _fromStop,
        onStopSelected: (stop) {
          setState(() {
            if (isFromStop) {
              _fromStop = stop;
            } else {
              _toStop = stop;
            }
          });
        },
      ),
    );
  }

  void _swapStops() {
    setState(() {
      final temp = _fromStop;
      _fromStop = _toStop;
      _toStop = temp;
    });
  }

  List<Map<String, RouteStop>> _getPopularRoutes() {
    final routes = <Map<String, RouteStop>>[];

    for (int i = 0; i < _popularStops.length; i++) {
      for (int j = i + 1; j < _popularStops.length; j++) {
        routes.add({'from': _popularStops[i], 'to': _popularStops[j]});
      }
    }

    return routes.take(3).toList(); // Максимум 3 популярных маршрута
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}ч ${minutes}мин';
    } else {
      return '${minutes}мин';
    }
  }
}

class _PopularRouteCard extends StatelessWidget {
  final RouteStop fromStop;
  final RouteStop toStop;
  final CustomTheme theme;
  final VoidCallback onTap;
  final bool isSelected;

  const _PopularRouteCard({
    required this.fromStop,
    required this.toStop,
    required this.theme,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.systemRed.withOpacity(0.1)
              : theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.systemRed : theme.separator,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              fromStop.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.label,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  CupertinoIcons.arrow_right,
                  size: 16,
                  color: theme.systemRed,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    toStop.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.label,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '2000 ₽',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.systemRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopPickerModal extends StatelessWidget {
  final List<RouteStop> stops;
  final RouteStop? selectedStop;
  final RouteStop? excludeStop;
  final Function(RouteStop) onStopSelected;

  const _StopPickerModal({
    required this.stops,
    required this.selectedStop,
    required this.excludeStop,
    required this.onStopSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    final availableStops = stops
        .where((stop) => excludeStop == null || stop.id != excludeStop!.id)
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: theme.systemBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.separator)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Выберите город',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.label,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Готово',
                    style: TextStyle(
                      color: theme.systemRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Список остановок
          Expanded(
            child: CupertinoPicker(
              itemExtent: 44,
              onSelectedItemChanged: (index) {
                onStopSelected(availableStops[index]);
              },
              children: availableStops.map((stop) {
                return Center(
                  child: Text(
                    stop.name,
                    style: TextStyle(fontSize: 18, color: theme.label),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
