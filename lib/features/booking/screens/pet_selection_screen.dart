import 'package:flutter/cupertino.dart';
import '../../../models/pet_info.dart';
import '../../../services/pet_agreement_service.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';

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
  PetSize _selectedSize = PetSize.s;
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
      // Сбрасываем согласие при смене размера
      _agreementAccepted = false;
    });
  }

  void _showIndividualTripWarning() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Требуется индивидуальная поездка'),
        content: const Text(
          'Для средних и крупных животных доступна только индивидуальная поездка. '
          'Это обеспечит комфорт и безопасность вашего питомца.',
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

  bool _canSavePet() {
    if (!_hasPet) return true;
    if (_breedController.text.trim().isEmpty) return false;

    // Проверяем согласие для средних и крупных животных
    if (_selectedSize == PetSize.m || _selectedSize == PetSize.l) {
      return _agreementAccepted;
    }

    return true;
  }

  void _savePet() {
    if (!_hasPet) {
      widget.onPetSelected(null);
    } else {
      final petInfo = PetInfo(
        size: _selectedSize,
        breed: _breedController.text.trim(),
        customDescription: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        agreementAccepted: _agreementAccepted,
        weight: '', // TODO: Add weight input field
      );
      widget.onPetSelected(petInfo);
    }
    Navigator.of(context).pop();
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
                      CupertinoTextField(
                        controller: _breedController,
                        placeholder: 'Укажите породу',
                        style: TextStyle(color: theme.label),
                        decoration: BoxDecoration(
                          color: theme.tertiarySystemBackground,
                          borderRadius: BorderRadius.circular(8),
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

                // Согласие для средних и крупных животных
                if (_selectedSize == PetSize.m ||
                    _selectedSize == PetSize.l) ...[
                  const SizedBox(height: 24),
                  _buildAgreementSection(theme),
                ],
              ],
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
        onPressed: () {
          _onSizeSelected(size);
          if (requiresIndividual) {
            _showIndividualTripWarning();
          }
        },
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

  Widget _buildAgreementSection(CustomTheme theme) {
    final agreementText = _agreementTexts[_selectedSize] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemOrange.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: CupertinoColors.systemOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Обязательное согласие',
                style: TextStyle(
                  color: theme.label,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            agreementText,
            style: TextStyle(color: theme.label, fontSize: 14, height: 1.4),
          ),

          const SizedBox(height: 16),

          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _agreementAccepted = !_agreementAccepted;
              });
            },
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _agreementAccepted
                        ? CupertinoColors.activeBlue
                        : theme.quaternaryLabel,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _agreementAccepted
                      ? const Icon(
                          CupertinoIcons.check_mark,
                          color: CupertinoColors.white,
                          size: 16,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Я принимаю условия перевозки животного',
                    style: TextStyle(
                      color: theme.label,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
