import 'package:flutter/cupertino.dart';
import '../../../models/predefined_route.dart';
import '../../../theme/theme_manager.dart';

/// Виджет элемента маршрута в группе
class RouteInGroupItem extends StatelessWidget {
  final PredefinedRoute route;
  final VoidCallback onEdit;
  final VoidCallback? onReset;
  final VoidCallback? onDelete;

  const RouteInGroupItem({
    super.key,
    required this.route,
    required this.onEdit,
    this.onReset,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    final bool hasCustomPrice = route.customPrice;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasCustomPrice 
            ? CupertinoColors.systemOrange.withOpacity(0.3)
            : theme.separator,
        ),
      ),
      child: Row(
        children: [
          // Индикатор типа цены
          Container(
            width: 6,
            height: 40,
            decoration: BoxDecoration(
              color: hasCustomPrice 
                ? CupertinoColors.systemOrange 
                : theme.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Информация о маршруте
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${route.fromCity} → ${route.toCity}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.label,
                        ),
                      ),
                    ),
                    
                    // Иконка типа цены
                    Icon(
                      hasCustomPrice 
                        ? CupertinoIcons.pencil_circle_fill 
                        : CupertinoIcons.link,
                      color: hasCustomPrice 
                        ? CupertinoColors.systemOrange 
                        : theme.primary,
                      size: 18,
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Text(
                      '${route.price.toInt()} ₽',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: hasCustomPrice 
                          ? CupertinoColors.systemOrange 
                          : theme.primary,
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Text(
                      hasCustomPrice 
                        ? 'Индивидуальная цена' 
                        : 'Групповая цена',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.secondaryLabel,
                      ),
                    ),
                    
                    if (route.isReverse) ...[
                      const SizedBox(width: 8),
                      Icon(
                        CupertinoIcons.arrow_2_circlepath,
                        size: 14,
                        color: theme.tertiaryLabel,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Кнопки действий
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Кнопка редактирования
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.pencil,
                    color: theme.primary,
                    size: 18,
                  ),
                ),
              ),
              
              // Кнопка сброса (только для кастомных цен)
              if (hasCustomPrice && onReset != null) ...[
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: onReset,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.refresh,
                      color: CupertinoColors.systemOrange,
                      size: 18,
                    ),
                  ),
                ),
              ],
              
              // Кнопка удаления
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.trash,
                      color: CupertinoColors.systemRed,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
