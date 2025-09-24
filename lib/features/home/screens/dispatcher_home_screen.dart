import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../models/booking.dart';
import '../../../models/trip_type.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../theme/theme_manager.dart';
import '../../admin/screens/admin_panel_screen.dart';

class DispatcherHomeScreen extends StatefulWidget {
  const DispatcherHomeScreen({super.key});

  @override
  State<DispatcherHomeScreen> createState() => _DispatcherHomeScreenState();
}

class _DispatcherHomeScreenState extends State<DispatcherHomeScreen> {
  User? _currentUser;
  List<Booking> _activeBookings = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.instance.getCurrentUser();
      if (user != null) {
        final bookings = await BookingService().getActiveBookings();
        final stats = await BookingService().getBookingStats();

        setState(() {
          _currentUser = user;
          _activeBookings = bookings;
          _stats = stats;
        });
      }
    } catch (e) {
      print('Ошибка загрузки данных диспетчера: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text('Панель диспетчера', style: TextStyle(color: theme.label)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _loadData,
          child: Icon(CupertinoIcons.refresh, color: theme.primary),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _buildDispatcherContent(theme),
      ),
    );
  }

  Widget _buildDispatcherContent(theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Приветствие диспетчера
            _buildDispatcherWelcomeCard(theme),

            const SizedBox(height: 24),

            // Статистика
            _buildStatisticsSection(theme),

            const SizedBox(height: 24),

            // Быстрые действия диспетчера
            _buildDispatcherQuickActions(theme),

            const SizedBox(height: 24),

            // Активные заказы
            _buildActiveOrders(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDispatcherWelcomeCard(theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CupertinoColors.systemPurple,
            CupertinoColors.systemPurple.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.person_crop_circle_badge_checkmark,
                color: CupertinoColors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Добро пожаловать, диспетчер!',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _currentUser?.name ?? 'Диспетчер',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                'Активных заказов',
                '${_activeBookings.length}',
                CupertinoIcons.doc_text,
              ),
              const SizedBox(width: 20),
              _buildStatItem(
                'Ожидает',
                '${_getPendingCount()}',
                CupertinoIcons.clock,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: CupertinoColors.white.withOpacity(0.8), size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: CupertinoColors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getPendingCount() {
    return _activeBookings
        .where((booking) => booking.status == BookingStatus.pending)
        .length;
  }

  Widget _buildStatisticsSection(theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Статистика заказов',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.label,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.secondarySystemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.separator.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                      'Ожидают',
                      '${_stats[BookingStatus.pending.toString()] ?? 0}',
                      CupertinoColors.systemOrange,
                      CupertinoIcons.clock,
                      theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatsCard(
                      'Подтверждены',
                      '${_stats[BookingStatus.confirmed.toString()] ?? 0}',
                      CupertinoColors.systemBlue,
                      CupertinoIcons.checkmark_circle,
                      theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                      'В пути',
                      '${_stats[BookingStatus.inProgress.toString()] ?? 0}',
                      CupertinoColors.systemGreen,
                      CupertinoIcons.car,
                      theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatsCard(
                      'Завершены',
                      '${_stats[BookingStatus.completed.toString()] ?? 0}',
                      CupertinoColors.systemGrey,
                      CupertinoIcons.checkmark_seal,
                      theme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    Color color,
    IconData icon,
    theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: theme.secondaryLabel),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDispatcherQuickActions(theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрые действия',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.label,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Все заказы',
                'Управление всеми заказами',
                CupertinoIcons.list_dash,
                CupertinoColors.systemBlue,
                () => _switchToOrdersTab(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Админ панель',
                'Настройка маршрутов и цен',
                CupertinoIcons.settings,
                CupertinoColors.systemPurple,
                () => _openAdminPanel(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Подтвердить заказы',
                'Обработать ожидающие заказы',
                CupertinoIcons.checkmark_circle,
                CupertinoColors.systemOrange,
                () => _showConfirmOrdersDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Статистика',
                'Подробная аналитика',
                CupertinoIcons.chart_bar,
                CupertinoColors.systemGreen,
                () => _showStatisticsDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  void _switchToOrdersTab() {
    // Показываем информационное сообщение о переходе на вкладку заказов
    _showInfoDialog('Перейдите на вкладку "Заказы" в нижнем меню');
  }

  void _openAdminPanel() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const AdminPanelScreen()),
    );
  }

  void _showConfirmOrdersDialog() {
    final pendingBookings = _activeBookings
        .where((b) => b.status == BookingStatus.pending)
        .toList();

    if (pendingBookings.isEmpty) {
      _showInfoDialog('Нет заказов для подтверждения');
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Подтвердить заказы'),
        content: Text(
          '${pendingBookings.length} заказов ожидают подтверждения',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Перейти к заказам'),
            onPressed: () {
              Navigator.pop(context);
              _switchToOrdersTab();
            },
          ),
        ],
      ),
    );
  }

  void _showStatisticsDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Подробная статистика'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Всего заказов:', '${_getTotalOrders()}'),
            _buildStatRow('Активных:', '${_activeBookings.length}'),
            _buildStatRow(
              'Завершённых:',
              '${_stats[BookingStatus.completed.toString()] ?? 0}',
            ),
            _buildStatRow(
              'Отменённых:',
              '${_stats[BookingStatus.cancelled.toString()] ?? 0}',
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Закрыть'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  int _getTotalOrders() {
    return _stats.values.fold(0, (sum, count) => sum + count);
  }

  void _showInfoDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Информация'),
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

  Widget _buildActiveOrders(theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Активные заказы',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.label,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _switchToOrdersTab(),
              child: Text(
                'Все заказы',
                style: TextStyle(color: theme.primary, fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_activeBookings.isEmpty)
          _buildEmptyOrders(theme)
        else
          ..._activeBookings
              .take(5)
              .map((booking) => _buildOrderCard(booking, theme))
              .toList(),
      ],
    );
  }

  Widget _buildEmptyOrders(theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 48,
            color: theme.secondaryLabel.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Нет активных заказов',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.secondaryLabel,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Все заказы обработаны',
            style: TextStyle(
              fontSize: 14,
              color: theme.secondaryLabel.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Booking booking, theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(booking.status),
              color: _getStatusColor(booking.status),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDirectionText(booking.direction),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.label,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(booking.departureDate)} • ${booking.departureTime}',
                  style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
                ),
                Text(
                  'Пассажиров: ${booking.passengerCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.secondaryLabel.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusText(booking.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(booking.status),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${booking.totalPrice} ₽',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.label,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Вспомогательные методы
  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return CupertinoIcons.clock;
      case BookingStatus.confirmed:
        return CupertinoIcons.checkmark_circle;
      case BookingStatus.assigned:
        return CupertinoIcons.car;
      case BookingStatus.inProgress:
        return CupertinoIcons.location;
      case BookingStatus.completed:
        return CupertinoIcons.checkmark_seal;
      case BookingStatus.cancelled:
        return CupertinoIcons.xmark_circle;
    }
  }

  String _getDirectionText(Direction direction) {
    switch (direction) {
      case Direction.donetskToRostov:
        return 'Донецк → Ростов-на-Дону';
      case Direction.rostovToDonetsk:
        return 'Ростов-на-Дону → Донецк';
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Ожидает';
      case BookingStatus.confirmed:
        return 'Подтверждён';
      case BookingStatus.assigned:
        return 'Назначен';
      case BookingStatus.inProgress:
        return 'В пути';
      case BookingStatus.completed:
        return 'Завершён';
      case BookingStatus.cancelled:
        return 'Отменён';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return CupertinoColors.systemOrange;
      case BookingStatus.confirmed:
        return CupertinoColors.systemBlue;
      case BookingStatus.assigned:
        return CupertinoColors.systemPurple;
      case BookingStatus.inProgress:
        return CupertinoColors.systemGreen;
      case BookingStatus.completed:
        return CupertinoColors.systemGrey;
      case BookingStatus.cancelled:
        return CupertinoColors.systemRed;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'мая',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}
