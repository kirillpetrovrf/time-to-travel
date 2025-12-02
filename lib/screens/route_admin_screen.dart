import 'package:flutter/cupertino.dart';
import '../utils/route_reload_utility.dart';

/// 🔧 АДМИН-ЭКРАН ДЛЯ УПРАВЛЕНИЯ МАРШРУТАМИ
/// 
/// Использование:
/// Navigator.push(context, CupertinoPageRoute(
///   builder: (context) => const RouteAdminScreen(),
/// ));
/// 
class RouteAdminScreen extends StatefulWidget {
  const RouteAdminScreen({super.key});

  @override
  State<RouteAdminScreen> createState() => _RouteAdminScreenState();
}

class _RouteAdminScreenState extends State<RouteAdminScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, dynamic>? _lastStatus;
  List<String> _krasnodarRoutes = [];

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Проверка статуса...';
    });

    try {
      final status = await RouteReloadUtility.checkRoutesStatus();
      final krasnodarRoutes = await RouteReloadUtility.checkKrasnodarRoutes();

      setState(() {
        _lastStatus = status;
        _krasnodarRoutes = krasnodarRoutes;
        _statusMessage = status['success'] 
            ? 'Статус обновлен'
            : 'Ошибка: ${status['error']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Ошибка проверки: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadRoutes() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Перезагрузка маршрутов...';
    });

    try {
      final result = await RouteReloadUtility.reloadAllRoutes(showDetails: true);

      setState(() {
        _statusMessage = result['success'] 
            ? 'Перезагрузка завершена за ${result['duration_ms']}мс'
            : 'Ошибка: ${result['error']}';
        _isLoading = false;
      });

      // Обновляем статус после перезагрузки
      if (result['success']) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _checkStatus();
      }

    } catch (e) {
      setState(() {
        _statusMessage = 'Ошибка перезагрузки: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('🔧 Админка маршрутов'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 📊 БЛОК СТАТУСА
              _buildStatusCard(),
              
              const SizedBox(height: 20),
              
              // 🎯 БЛОК КРАСНОДАРСКИХ МАРШРУТОВ
              _buildKrasnodarRoutesCard(),
              
              const SizedBox(height: 20),
              
              // 🔧 БЛОК УПРАВЛЕНИЯ
              _buildControlsCard(),
              
              const Spacer(),
              
              // 📝 СООБЩЕНИЕ О СТАТУСЕ
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (_isLoading)
                        const CupertinoActivityIndicator()
                      else
                        Icon(
                          _statusMessage.contains('Ошибка') 
                              ? CupertinoIcons.exclamationmark_triangle_fill
                              : CupertinoIcons.checkmark_circle_fill,
                          color: _statusMessage.contains('Ошибка')
                              ? CupertinoColors.destructiveRed
                              : CupertinoColors.activeGreen,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey4,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.chart_bar_fill, 
                   color: CupertinoColors.systemBlue),
              SizedBox(width: 8),
              Text('📊 Статус маршрутов', 
                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_lastStatus != null) ...[
            _buildStatusRow('Всего маршрутов в БД:', 
                           '${_lastStatus!['total_routes']}'),
            _buildStatusRow('RouteInitializer маршрутов:', 
                           '${_lastStatus!['initializer_routes']}'),
            _buildStatusRow('Процент инициализации:', 
                           '${_lastStatus!['initialization_percentage']}%'),
            _buildStatusRow('Средняя цена:', 
                           '${_lastStatus!['avg_price']}₽'),
            _buildStatusRow('Статус:', 
                           _lastStatus!['is_fully_initialized'] ? 'Полная инициализация' : 'Требуется обновление'),
          ] else ...[
            const Text('Статус не загружен', 
                      style: TextStyle(color: CupertinoColors.systemGrey)),
          ],
        ],
      ),
    );
  }

  Widget _buildKrasnodarRoutesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey4,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.location_fill, 
                   color: CupertinoColors.systemOrange),
              SizedBox(width: 8),
              Text('🎯 Маршруты Краснодар', 
                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_krasnodarRoutes.isNotEmpty) ...[
            Text('Найдено маршрутов: ${_krasnodarRoutes.length}/12',
                 style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            
            SizedBox(
              height: 120,
              child: ListView.builder(
                itemCount: _krasnodarRoutes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.checkmark_circle_fill,
                                   color: CupertinoColors.activeGreen, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _krasnodarRoutes[index],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            const Text('Краснодарские маршруты не найдены',
                      style: TextStyle(color: CupertinoColors.systemGrey)),
          ],
        ],
      ),
    );
  }

  Widget _buildControlsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey4,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.settings, 
                   color: CupertinoColors.systemGrey),
              SizedBox(width: 8),
              Text('🔧 Управление', 
                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Кнопка обновления статуса
          CupertinoButton(
            color: CupertinoColors.systemBlue,
            onPressed: _isLoading ? null : _checkStatus,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.refresh),
                SizedBox(width: 8),
                Text('Обновить статус'),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Кнопка перезагрузки маршрутов
          CupertinoButton(
            color: CupertinoColors.systemOrange,
            onPressed: _isLoading ? null : _reloadRoutes,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrow_clockwise),
                SizedBox(width: 8),
                Text('Перезагрузить маршруты'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, 
               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}