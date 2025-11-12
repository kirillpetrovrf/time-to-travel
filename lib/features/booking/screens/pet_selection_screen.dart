import 'package:flutter/cupertino.dart';
import '../../../models/pet_info.dart';
import '../../../services/pet_agreement_service.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';
import 'breed_selection_screen.dart';

/// Экран выбора животных (ПОЛНОСТЬЮ ПЕРЕДЕЛАН под ТЗ v3.0)
/// ИЗМЕНЕНИЯ: Убран размер XS, добавлена система согласий, тексты от диспетчера
class PetSelectionScreen extends StatefulWidget {
  final PetInfo? initialPetInfo;
  final Function(PetInfo?) onPetSelected;

  const PetSelectionScreen({
    super.key,
    this.initialPetInfo,
    required this.onPetSelected,
  });

  @override
  State<PetSelectionScreen> createState() => _PetSelectionScreenState();
}

class _PetSelectionScreenState extends State<PetSelectionScreen> {
  bool _hasPet = false;
  PetSize?
  _selectedSize; // Изменено на nullable - размер не выбран по умолчанию
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _agreementAccepted = false;
  Map<PetSize, String> _agreementTexts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeFromExisting();
    _loadAgreementTexts();
  }

  void _initializeFromExisting() {
    if (widget.initialPetInfo != null) {
      _hasPet = true;
      _selectedSize = widget.initialPetInfo!.size;
      _breedController.text = widget.initialPetInfo!.breed;
      _descriptionController.text =
          widget.initialPetInfo!.customDescription ?? '';
      _agreementAccepted = widget.initialPetInfo!.agreementAccepted;
    }
  }

  Future<void> _loadAgreementTexts() async {
    try {
      final texts = {
        PetSize.s: await PetAgreementService.getPetAgreementText(PetSize.s),
        PetSize.m: await PetAgreementService.getPetAgreementText(PetSize.m),
        PetSize.l: await PetAgreementService.getPetAgreementText(PetSize.l),
      };

      if (mounted) {
        setState(() {
          _agreementTexts = texts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки текстов согласий: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _breedController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSizeSelected(PetSize size) {
    setState(() {
      _selectedSize = size;
      // Сбрасываем согласие и породу при смене размера
      _agreementAccepted = false;
    });

    // Показываем предупреждение и сразу предлагаем выбрать породу
    if (size == PetSize.m || size == PetSize.l) {
      _showBreedSelectionWarning(size, isIndividual: true);
    } else {
      _showBreedSelectionWarning(size, isIndividual: false);
    }
  }

  void _showBreedSelectionWarning(PetSize size, {required bool isIndividual}) {
    if (isIndividual) {
      // Для M и L размеров показываем диалог с согласием
      _showAgreementDialog(size);
    } else {
      // Для S размера просто предлагаем выбрать породу
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Выбор породы'),
          content: const Text('Пожалуйста, укажите породу вашего питомца.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Выбрать породу'),
              onPressed: () {
                Navigator.pop(context);
                _openBreedSelection();
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedSize = null;
                });
              },
            ),
          ],
        ),
      );
    }
  }

  void _showAgreementDialog(PetSize size) {
    bool tempAgreement = false;

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final agreementText = _agreementTexts[size] ?? 'Загрузка...';

          return CupertinoAlertDialog(
            title: Row(
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: CupertinoColors.systemOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('Обязательное согласие')),
              ],
            ),
            content: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  'Для ${_getSizeTitle(size).toLowerCase()} доступна только индивидуальная поездка (+2000₽).',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(agreementText, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 16),
                // Чекбокс согласия
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setDialogState(() {
                      tempAgreement = !tempAgreement;
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: tempAgreement
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey4,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: tempAgreement
                            ? const Icon(
                                CupertinoIcons.check_mark,
                                color: CupertinoColors.white,
                                size: 16,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Я принимаю условия перевозки животного',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Отмена'),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  setState(() {
                    _selectedSize = null;
                    _agreementAccepted = false;
                  });
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Выбрать породу'),
                onPressed: tempAgreement
                    ? () {
                        Navigator.pop(dialogContext);
                        setState(() {
                          _agreementAccepted = true;
                        });
                        _openBreedSelection();
                      }
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  bool _canSavePet() {
    if (!_hasPet) return true;

    // Проверяем, что размер выбран
    if (_selectedSize == null) return false;

    // Для маленьких животных порода не обязательна
    if (_selectedSize == PetSize.s) {
      return true;
    }

    // Для средних и крупных животных требуется порода и согласие
    if (_selectedSize == PetSize.m || _selectedSize == PetSize.l) {
      return _breedController.text.trim().isNotEmpty && _agreementAccepted;
    }

    return false;
  }

  void _savePet() {
    if (!_hasPet) {
      widget.onPetSelected(null);
      Navigator.of(context).pop();
      return;
    }

    // Проверяем, что размер выбран
    if (_selectedSize == null) {
      _showSizeRequiredDialog();
      return;
    }

    // Для средних и крупных животных проверяем наличие породы
    if ((_selectedSize == PetSize.m || _selectedSize == PetSize.l) &&
        _breedController.text.trim().isEmpty) {
      _showBreedRequiredDialog();
      return;
    }

    final petInfo = PetInfo(
      size: _selectedSize!,
      breed: _breedController.text.trim(),
      customDescription: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      agreementAccepted: _agreementAccepted,
      weight: '', // TODO: Add weight input field
    );
    widget.onPetSelected(petInfo);
    Navigator.of(context).pop();
  }

  void _showSizeRequiredDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Выберите размер'),
        content: const Text('Пожалуйста, выберите размер животного.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Понятно'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showBreedRequiredDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Укажите породу'),
        content: const Text(
          'Для средних и крупных животных необходимо указать породу.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Понятно'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openBreedSelection() async {
    final selectedBreed = await Navigator.push<String>(
      context,
      CupertinoPageRoute(builder: (context) => const BreedSelectionScreen()),
    );

    if (selectedBreed != null) {
      setState(() {
        _breedController.text = selectedBreed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    if (_isLoading) {
      return CupertinoPageScaffold(
        backgroundColor: theme.systemBackground,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: theme.secondarySystemBackground,
          middle: Text('Животные', style: TextStyle(color: theme.label)),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text('Животные', style: TextStyle(color: theme.label)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Отмена', style: TextStyle(color: theme.quaternaryLabel)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
            'Готово',
            style: TextStyle(
              color: _canSavePet()
                  ? CupertinoColors.activeBlue
                  : theme.quaternaryLabel,
            ),
          ),
          onPressed: _canSavePet() ? _savePet : null,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Переключатель "Везу животное"
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.secondarySystemBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.paw, color: theme.label, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Везу животное',
                        style: TextStyle(
                          color: theme.label,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    CupertinoSwitch(
                      value: _hasPet,
                      onChanged: (value) {
                        setState(() {
                          _hasPet = value;
                          if (!value) {
                            // Сбрасываем все поля при отключении
                            _selectedSize = null;
                            _breedController.clear();
                            _descriptionController.clear();
                            _agreementAccepted = false;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),

              if (_hasPet) ...[
                const SizedBox(height: 24),

                // Выбор размера животного
                Text(
                  'Размер животного',
                  style: TextStyle(
                    color: theme.label,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                ...PetSize.values.map((size) => _buildSizeCard(size, theme)),

                const SizedBox(height: 24),

                // Порода животного
                Text(
                  'Порода и описание',
                  style: TextStyle(
                    color: theme.label,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.secondarySystemBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Кнопка выбора породы
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _openBreedSelection,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: theme.tertiarySystemBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _breedController.text.isEmpty
                                      ? 'Выберите породу'
                                      : _breedController.text,
                                  style: TextStyle(
                                    color: _breedController.text.isEmpty
                                        ? theme.secondaryLabel
                                        : theme.label,
                                    fontSize: 16,
                                  ),
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
                      ),

                      const SizedBox(height: 12),
                      CupertinoTextField(
                        controller: _descriptionController,
                        placeholder:
                            'Дополнительная информация (необязательно)',
                        style: TextStyle(color: theme.label),
                        maxLines: 3,
                        decoration: BoxDecoration(
                          color: theme.tertiarySystemBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Отступ снизу для системных кнопок навигации
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeCard(PetSize size, CustomTheme theme) {
    final isSelected = _selectedSize == size;
    final costText = size == PetSize.s ? '+500₽' : '+2000₽';
    final requiresIndividual = size == PetSize.m || size == PetSize.l;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _onSizeSelected(size),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.secondarySystemBackground,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: CupertinoColors.activeBlue, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Иконка размера
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getSizeColor(size),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getSizeIcon(size),
                      color: CupertinoColors.white,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Информация о размере
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getSizeTitle(size),
                          style: TextStyle(
                            color: theme.label,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getSizeWeight(size),
                          style: TextStyle(
                            color: theme.secondaryLabel,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Цена
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        costText,
                        style: TextStyle(
                          color: theme.label,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (requiresIndividual)
                        Text(
                          'Индивид.',
                          style: TextStyle(
                            color: CupertinoColors.systemOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Примеры животных
              Text(
                _getSizeExamples(size),
                style: TextStyle(color: theme.secondaryLabel, fontSize: 12),
              ),

              const SizedBox(height: 8),

              // Способ транспортировки
              Text(
                _getTransportMethod(size),
                style: TextStyle(
                  color: theme.secondaryLabel,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Вспомогательные методы для отображения информации о размерах
  String _getSizeTitle(PetSize size) {
    switch (size) {
      case PetSize.s:
        return 'Размер S (Маленький)';
      case PetSize.m:
        return 'Размер M (Средний)';
      case PetSize.l:
        return 'Размер L (Большой)';
    }
  }

  String _getSizeWeight(PetSize size) {
    switch (size) {
      case PetSize.s:
        return 'до 8 кг';
      case PetSize.m:
        return 'до 25 кг';
      case PetSize.l:
        return 'свыше 25 кг';
    }
  }

  String _getSizeExamples(PetSize size) {
    switch (size) {
      case PetSize.s:
        return 'Кошка, маленькая собака (чихуахуа, той-терьер)';
      case PetSize.m:
        return 'Средняя собака (спаниель, бигль)';
      case PetSize.l:
        return 'Крупная собака (лабрадор, немецкая овчарка)';
    }
  }

  String _getTransportMethod(PetSize size) {
    switch (size) {
      case PetSize.s:
        return 'В переноске в салоне';
      case PetSize.m:
      case PetSize.l:
        return 'Только индивидуальная поездка (отдельное место)';
    }
  }

  IconData _getSizeIcon(PetSize size) {
    switch (size) {
      case PetSize.s:
        return CupertinoIcons.paw;
      case PetSize.m:
        return CupertinoIcons.paw_solid;
      case PetSize.l:
        return CupertinoIcons.heart_solid;
    }
  }

  Color _getSizeColor(PetSize size) {
    switch (size) {
      case PetSize.s:
        return CupertinoColors.activeGreen;
      case PetSize.m:
        return CupertinoColors.systemOrange;
      case PetSize.l:
        return CupertinoColors.systemRed;
    }
  }
}
