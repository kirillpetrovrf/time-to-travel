import 'package:flutter/cupertino.dart';
import '../../../models/route_group.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';
import '../../../data/route_groups_initializer.dart';
import '../widgets/route_group_card.dart';
import 'route_group_details_screen.dart';

/// Экран управления группами маршрутов
class RouteGroupsAdminScreen extends StatefulWidget {
  const RouteGroupsAdminScreen({super.key});

  @override
  State<RouteGroupsAdminScreen> createState() => _RouteGroupsAdminScreenState();
}

class _RouteGroupsAdminScreenState extends State<RouteGroupsAdminScreen> {
  List<RouteGroup> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      // Загружаем группы напрямую из инициализатора (без Firebase/SQLite)
      final groups = RouteGroupsInitializer.initialGroups;
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Ошибка'),
            content: Text('Не удалось загрузить группы: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  void _navigateToGroupDetails(RouteGroup group) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => RouteGroupDetailsScreen(group: group),
      ),
    ).then((_) => _loadGroups());
  }

  Future<void> _deleteGroup(RouteGroup group) async {
    // Предустановленные группы нельзя удалять
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Нельзя удалить'),
          content: const Text(
            'Это предустановленная группа. Она загружается из кода при каждом запуске приложения.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

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
          'Группы маршрутов',
          style: TextStyle(color: theme.label),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.refresh, color: theme.primary),
          onPressed: _loadGroups,
        ),
      ),
      child: SafeArea(
        child: _isLoading
          ? Center(
              child: CupertinoActivityIndicator(color: theme.primary),
            )
          : _groups.isEmpty
            ? Center(
                child: Text(
                  'Нет групп маршрутов',
                  style: TextStyle(
                    fontSize: 17,
                    color: theme.secondaryLabel,
                  ),
                ),
              )
            : CustomScrollView(
                slivers: [
                  // Статистика
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.secondarySystemBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
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
                            value: _groups.fold<int>(
                              0,
                              (sum, g) => sum + g.uniqueRoutesCount,
                            ).toString(),
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 🆕 Кнопки-чипы для быстрого доступа к группам
                  SliverToBoxAdapter(
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: theme.secondarySystemBackground,
                              borderRadius: BorderRadius.circular(20),
                              minSize: 0,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    group.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.label,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${group.uniqueRoutesCount}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onPressed: () => _navigateToGroupDetails(group),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Список групп
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final group = _groups[index];
                        return RouteGroupCard(
                          group: group,
                          onTap: () => _navigateToGroupDetails(group),
                          onDelete: () => _deleteGroup(group),
                        );
                      },
                      childCount: _groups.length,
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

/// Виджет элемента статистики
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
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.label,
          ),
        ),
        const SizedBox(height: 4),
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
