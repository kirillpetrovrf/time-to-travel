import 'package:flutter/cupertino.dart';
import '../../../theme/theme_manager.dart';

/// Экран выбора породы собаки с поиском и популярными породами
class BreedSelectionScreen extends StatefulWidget {
  final String? initialBreed;

  const BreedSelectionScreen({super.key, this.initialBreed});

  @override
  State<BreedSelectionScreen> createState() => _BreedSelectionScreenState();
}

class _BreedSelectionScreenState extends State<BreedSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Популярные породы собак (топ-20)
  static const List<String> _popularBreeds = [
    'Лабрадор',
    'Немецкая овчарка',
    'Золотистый ретривер',
    'Французский бульдог',
    'Бульдог',
    'Бигль',
    'Пудель',
    'Ротвейлер',
    'Йоркширский терьер',
    'Боксер',
    'Такса',
    'Сибирский хаски',
    'Доберман',
    'Чихуахуа',
    'Мопс',
    'Шпиц',
    'Корги',
    'Джек-рассел-терьер',
    'Шиба-ину',
    'Акита-ину',
  ];

  // Полный список пород (можно расширить)
  static const List<String> _allBreeds = [
    'Лабрадор',
    'Немецкая овчарка',
    'Золотистый ретривер',
    'Французский бульдог',
    'Бульдог',
    'Бигль',
    'Пудель',
    'Ротвейлер',
    'Йоркширский терьер',
    'Боксер',
    'Такса',
    'Сибирский хаски',
    'Доберман',
    'Чихуахуа',
    'Мопс',
    'Шпиц',
    'Корги',
    'Джек-рассел-терьер',
    'Шиба-ину',
    'Акита-ину',
    'Английский кокер-спаниель',
    'Американский кокер-спаниель',
    'Бассет-хаунд',
    'Бордер-колли',
    'Бостон-терьер',
    'Вельш-корги',
    'Далматин',
    'Кавалер-кинг-чарльз-спаниель',
    'Кане-корсо',
    'Лхаса апсо',
    'Мальтезе',
    'Мастиф',
    'Ньюфаундленд',
    'Пекинес',
    'Питбуль',
    'Пойнтер',
    'Самоедская собака',
    'Сенбернар',
    'Стаффордширский терьер',
    'Той-терьер',
    'Цвергшнауцер',
    'Чау-чау',
    'Ши-тцу',
    'Шарпей',
    'Другая порода',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialBreed != null) {
      _searchController.text = widget.initialBreed!;
      _searchQuery = widget.initialBreed!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getFilteredBreeds() {
    if (_searchQuery.isEmpty) {
      return [];
    }

    final query = _searchQuery.toLowerCase();
    return _allBreeds
        .where((breed) => breed.toLowerCase().contains(query))
        .toList();
  }

  void _selectBreed(String breed) {
    Navigator.of(context).pop(breed);
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;
    final filteredBreeds = _getFilteredBreeds();

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text('Выбор породы', style: TextStyle(color: theme.label)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: theme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Поле поиска
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.secondarySystemBackground,
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Поиск породы',
                style: TextStyle(color: theme.label),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _selectBreed(value);
                  }
                },
              ),
            ),

            // Список пород
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildPopularBreeds(theme)
                  : _buildSearchResults(filteredBreeds, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularBreeds(theme) {
    return ListView(
      children: [
        // Заголовок популярных пород
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Популярные породы',
            style: TextStyle(
              color: theme.secondaryLabel,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.08,
            ),
          ),
        ),

        // Список популярных пород
        ..._popularBreeds.map((breed) {
          return _buildBreedItem(breed, theme);
        }),
      ],
    );
  }

  Widget _buildSearchResults(List<String> breeds, theme) {
    if (breeds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 64,
              color: theme.secondaryLabel.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Породы не найдены',
              style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              child: Text('Использовать "${_searchQuery}"'),
              onPressed: () => _selectBreed(_searchQuery),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: breeds.length,
      itemBuilder: (context, index) {
        return _buildBreedItem(breeds[index], theme);
      },
    );
  }

  Widget _buildBreedItem(String breed, theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.separator.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: () => _selectBreed(breed),
        child: Row(
          children: [
            Icon(CupertinoIcons.paw_solid, color: theme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                breed,
                style: TextStyle(color: theme.label, fontSize: 17),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: theme.secondaryLabel,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
