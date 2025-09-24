import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_manager.dart';

class ThemeEditorScreen extends StatefulWidget {
  const ThemeEditorScreen({super.key});

  @override
  State<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends State<ThemeEditorScreen> {
  late CustomTheme _editingTheme;
  late CustomTheme _originalTheme;
  bool _isPreviewMode = false;
  late ThemeManager _themeManager;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _editingTheme = AppTheme.defaultLight;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _themeManager = ChangeNotifierProvider.of<ThemeManager>(context);
      // Загружаем текущую тему для редактирования
      _originalTheme = _themeManager.currentTheme;
      _editingTheme = _originalTheme;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Редактор дизайна'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _cancelEditing,
          child: const Text('Отмена'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saveTheme,
          child: const Text('Готово'),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Переключатель режима предварительного просмотра
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Предварительный просмотр'),
                  const Spacer(),
                  CupertinoSwitch(
                    value: _isPreviewMode,
                    onChanged: (value) {
                      setState(() {
                        _isPreviewMode = value;
                      });
                      if (value) {
                        // Применяем текущую редактируемую тему для предварительного просмотра
                        _themeManager.setTheme(_editingTheme);
                      } else {
                        // Возвращаем исходную тему
                        _themeManager.setTheme(_originalTheme);
                      }
                    },
                  ),
                ],
              ),
            ),

            Container(height: 1, color: CupertinoColors.separator),

            // Содержимое редактора
            Expanded(
              child: _isPreviewMode ? _buildPreviewMode() : _buildEditorMode(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorMode() {
    return ListView(
      children: [
        // Основная информация о теме
        _buildSection('Основная информация', [
          _buildTextInput(
            'Название темы',
            _editingTheme.name,
            (value) => _updateTheme(_editingTheme.copyWith(name: value)),
          ),
          _buildSwitch(
            'Темная тема',
            _editingTheme.isDark,
            (value) => _updateTheme(_editingTheme.copyWith(isDark: value)),
          ),
        ]),

        // Быстрые темы
        _buildSection('Быстрые темы', [
          _buildQuickThemeButtons(),
        ]),

        // Цвета
        _buildSection('Цвета', [
          _buildColorPicker(
            'Основной цвет',
            _editingTheme.primary,
            (color) => _updateTheme(_editingTheme.copyWith(primary: color)),
          ),
          _buildColorPicker(
            'Вторичный цвет',
            _editingTheme.secondary,
            (color) => _updateTheme(_editingTheme.copyWith(secondary: color)),
          ),
          _buildColorPicker(
            'Цвет успеха',
            _editingTheme.success,
            (color) => _updateTheme(_editingTheme.copyWith(success: color)),
          ),
          _buildColorPicker(
            'Цвет предупреждения',
            _editingTheme.warning,
            (color) => _updateTheme(_editingTheme.copyWith(warning: color)),
          ),
          _buildColorPicker(
            'Цвет ошибки',
            _editingTheme.danger,
            (color) => _updateTheme(_editingTheme.copyWith(danger: color)),
          ),
        ]),

        // Фон
        _buildSection('Фон', [
          _buildColorPicker(
            'Основной фон',
            _editingTheme.systemBackground,
            (color) =>
                _updateTheme(_editingTheme.copyWith(systemBackground: color)),
          ),
          _buildColorPicker(
            'Вторичный фон',
            _editingTheme.secondarySystemBackground,
            (color) => _updateTheme(
              _editingTheme.copyWith(secondarySystemBackground: color),
            ),
          ),
        ]),

        // Размеры
        _buildSection('Размеры', [
          _buildSlider(
            'Высота кнопок',
            _editingTheme.buttonHeight,
            32.0,
            64.0,
            (value) =>
                _updateTheme(_editingTheme.copyWith(buttonHeight: value)),
          ),
          _buildSlider(
            'Радиус скругления',
            _editingTheme.borderRadius,
            0.0,
            24.0,
            (value) =>
                _updateTheme(_editingTheme.copyWith(borderRadius: value)),
          ),
          _buildSlider(
            'Размер иконок',
            _editingTheme.iconSize,
            16.0,
            48.0,
            (value) => _updateTheme(_editingTheme.copyWith(iconSize: value)),
          ),
        ]),

        // Шрифты
        _buildSection('Шрифты', [
          _buildSlider(
            'Базовый размер шрифта',
            _editingTheme.baseFontSize,
            12.0,
            24.0,
            (value) =>
                _updateTheme(_editingTheme.copyWith(baseFontSize: value)),
          ),
          _buildFontWeightPicker(),
        ]),

        // Элементы интерфейса
        _buildSection('Элементы интерфейса', [
          _buildSwitch(
            'Показывать тени',
            _editingTheme.showShadows,
            (value) => _updateTheme(_editingTheme.copyWith(showShadows: value)),
          ),
          _buildSwitch(
            'Показывать границы',
            _editingTheme.showBorders,
            (value) => _updateTheme(_editingTheme.copyWith(showBorders: value)),
          ),
          _buildSwitch(
            'Показывать иконки',
            _editingTheme.showIcons,
            (value) => _updateTheme(_editingTheme.copyWith(showIcons: value)),
          ),
          _buildSwitch(
            'Компактный режим',
            _editingTheme.compactMode,
            (value) => _updateTheme(_editingTheme.copyWith(compactMode: value)),
          ),
        ]),

        // Действия
        _buildSection('Действия', [
          _buildActionButton(
            'Сбросить к стандартной теме',
            CupertinoColors.systemRed,
            _resetToDefault,
          ),
          _buildActionButton(
            'Экспортировать тему',
            CupertinoColors.systemBlue,
            _exportTheme,
          ),
          _buildActionButton(
            'Импортировать тему',
            CupertinoColors.systemGreen,
            _importTheme,
          ),
        ]),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPreviewMode() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Превью карточки
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _editingTheme.secondarySystemBackground,
            borderRadius: BorderRadius.circular(_editingTheme.borderRadius),
            border: _editingTheme.showBorders
                ? Border.all(color: _editingTheme.separator)
                : null,
            boxShadow: _editingTheme.showShadows
                ? [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_editingTheme.showIcons)
                    Icon(
                      CupertinoIcons.car,
                      size: _editingTheme.iconSize,
                      color: _editingTheme.primary,
                    ),
                  if (_editingTheme.showIcons) const SizedBox(width: 12),
                  Text(
                    'Превью карточки поездки',
                    style: TextStyle(
                      fontSize: _editingTheme.baseFontSize + 2,
                      fontWeight: _editingTheme.baseFontWeight,
                      color: _editingTheme.label,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Казань → Москва',
                style: TextStyle(
                  fontSize: _editingTheme.baseFontSize,
                  color: _editingTheme.secondaryLabel,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    height: _editingTheme.buttonHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _editingTheme.primary,
                      borderRadius: BorderRadius.circular(
                        _editingTheme.borderRadius,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Забронировать',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: _editingTheme.baseFontSize,
                          fontWeight: _editingTheme.baseFontWeight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: _editingTheme.buttonHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _editingTheme.success,
                      borderRadius: BorderRadius.circular(
                        _editingTheme.borderRadius,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '1500 ₽',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: _editingTheme.baseFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Превью списка
        Text(
          'Превью элементов списка',
          style: TextStyle(
            fontSize: _editingTheme.baseFontSize + 4,
            fontWeight: FontWeight.bold,
            color: _editingTheme.label,
          ),
        ),

        const SizedBox(height: 16),

        ...List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _editingTheme.secondarySystemBackground,
              borderRadius: BorderRadius.circular(_editingTheme.borderRadius),
              border: _editingTheme.showBorders
                  ? Border.all(color: _editingTheme.separator)
                  : null,
            ),
            child: Row(
              children: [
                if (_editingTheme.showIcons)
                  Container(
                    width: _editingTheme.iconSize + 8,
                    height: _editingTheme.iconSize + 8,
                    decoration: BoxDecoration(
                      color: _editingTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.person,
                      size: _editingTheme.iconSize * 0.6,
                      color: CupertinoColors.white,
                    ),
                  ),
                if (_editingTheme.showIcons) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Пользователь ${index + 1}',
                        style: TextStyle(
                          fontSize: _editingTheme.baseFontSize,
                          fontWeight: _editingTheme.baseFontWeight,
                          color: _editingTheme.label,
                        ),
                      ),
                      Text(
                        'Рейтинг: 4.${8 + index}',
                        style: TextStyle(
                          fontSize: _editingTheme.baseFontSize - 2,
                          color: _editingTheme.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: CupertinoColors.systemGrey6,
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildTextInput(
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
      ),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: CupertinoTextField(
              placeholder: label,
              controller: TextEditingController(text: value),
              onChanged: onChanged,
              decoration: const BoxDecoration(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildColorPicker(
    String label,
    Color color,
    Function(Color) onChanged,
  ) {
    return GestureDetector(
      onTap: () => _showColorPicker(label, color, onChanged),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CupertinoColors.separator),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label),
              const Spacer(),
              Text('${value.toStringAsFixed(0)}'),
            ],
          ),
          CupertinoSlider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildFontWeightPicker() {
    const weights = [
      FontWeight.w300,
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
    ];

    const weightNames = [
      'Легкий',
      'Обычный',
      'Средний',
      'Полужирный',
      'Жирный',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Толщина шрифта'),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: CupertinoPicker(
              itemExtent: 32,
              scrollController: FixedExtentScrollController(
                initialItem: weights.indexOf(_editingTheme.baseFontWeight),
              ),
              onSelectedItemChanged: (index) {
                _updateTheme(
                  _editingTheme.copyWith(baseFontWeight: weights[index]),
                );
              },
              children: weightNames
                  .map((name) => Center(child: Text(name)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Text(label, style: TextStyle(color: color)),
      ),
    );
  }

  void _updateTheme(CustomTheme newTheme) {
    setState(() {
      _editingTheme = newTheme;
    });

    if (_isPreviewMode) {
      // Применяем тему для предварительного просмотра
      _themeManager.setTheme(_editingTheme);
    }
  }  void _saveTheme() {
    // Сохраняем тему через ThemeManager
    _themeManager.setTheme(_editingTheme);
    
    // Обновляем оригинальную тему
    _originalTheme = _editingTheme;
    
    _showAlert('Успешно', 'Тема сохранена и применена');
    Navigator.pop(context);
  }

  void _cancelEditing() {
    // Если в режиме предварительного просмотра, возвращаем исходную тему
    if (_isPreviewMode) {
      _themeManager.setTheme(_originalTheme);
    }
    Navigator.pop(context);
  }

  void _resetToDefault() {
    setState(() {
      _editingTheme = AppTheme.defaultLight;
    });

    if (_isPreviewMode) {
      _themeManager.setTheme(_editingTheme);
    }
  }

  void _exportTheme() {
    // Создаем простую JSON строку для демонстрации
    final themeJson =
        '{"name": "${_editingTheme.name}", "id": "${_editingTheme.id}"}';
    Clipboard.setData(ClipboardData(text: themeJson));

    _showAlert('Успешно', 'Тема скопирована в буфер обмена');
  }

  void _importTheme() {
    // Здесь можно добавить диалог для ввода JSON
    _showAlert(
      'Информация',
      'Функция импорта будет добавлена в следующей версии',
    );
  }

  void _showColorPicker(
    String title,
    Color currentColor,
    Function(Color) onChanged,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Готово'),
                  ),
                ],
              ),
            ),
            const Text('Выбор цвета будет реализован в следующей версии'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickThemeButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              color: CupertinoColors.systemBlue,
              onPressed: () {
                _updateTheme(AppTheme.defaultLight);
              },
              child: const Text('Светлая'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoButton(
              color: CupertinoColors.systemGrey6,
              onPressed: () {
                _updateTheme(AppTheme.defaultDark);
              },
              child: const Text(
                'Тёмная',
                style: TextStyle(color: CupertinoColors.label),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoButton(
              color: CupertinoColors.systemGreen,
              onPressed: () {
                _updateTheme(AppTheme.compact);
              },
              child: const Text('Компактная'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
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
}
