import '../services/route_group_service.dart';

/// Утилита для удаления ложных групп из базы данных
class CleanFalseGroups {
  static Future<void> execute() async {
    print('🧹 Начинаем очистку ложных групп...');
    
    final service = RouteGroupService.instance;
    
    // Получаем все группы
    final allGroups = await service.getAllGroups();
    print('📊 Найдено групп: ${allGroups.length}');
    
    // ID предустановленных групп (правильные)
    const validGroupIds = [
      'rostov_region',
      'crimea',
      'azov_sea',
      'black_sea_coast',
      'sochi',
      'krasnodar',
      'volgograd_minvody',
      'yeisk',
      'distant_russia',
      'any_routes', // Новая группа "Любые маршруты"
    ];
    
    // Находим ложные группы (те, у которых ID начинается с "group_")
    final falseGroups = allGroups.where((group) {
      return !validGroupIds.contains(group.id);
    }).toList();
    
    print('❌ Найдено ложных групп: ${falseGroups.length}');
    
    // Удаляем ложные группы
    for (final group in falseGroups) {
      print('🗑️ Удаляем: ${group.name} (ID: ${group.id})');
      await service.deleteGroup(group.id);
    }
    
    // Проверяем результат
    final remainingGroups = await service.getAllGroups();
    print('✅ Очистка завершена!');
    print('📊 Осталось групп: ${remainingGroups.length}');
    
    for (final group in remainingGroups) {
      print('   ✓ ${group.name} (${group.basePrice}₽)');
    }
  }
}
