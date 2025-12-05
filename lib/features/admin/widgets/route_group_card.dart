import 'package:flutter/cupertino.dart';
import '../../../models/route_group.dart';
import '../../../theme/theme_manager.dart';

/// Виджет карточки группы маршрутов
class RouteGroupCard extends StatelessWidget {
  final RouteGroup group;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RouteGroupCard({
    super.key,
    required this.group,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.separator),
        ),
        child: Row(
          children: [
            // Иконка группы
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.square_stack_3d_up,
                color: theme.primary,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Информация о группе
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: theme.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.secondaryLabel,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Базовая цена
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${group.basePrice.toInt()} ₽',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.primary,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Количество маршрутов
                      Text(
                        '${group.uniqueRoutesCount} маршрутов',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.tertiaryLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Иконка перехода
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
}
