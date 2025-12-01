import 'package:flutter/cupertino.dart';
import '../../../models/pet_info_v3.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';

/// Упрощённый выбор животного через Bottom Sheet
/// Высота: 65% экрана
/// 3 фиксированных варианта выбора категории животного (для групповой)
/// 2 варианта для индивидуального трансфера
class SimplePetSelectionSheet extends StatefulWidget {
  final PetInfo? initialPet;
  final Function(PetInfo?) onPetSelected;
  final bool isIndividualTrip; // Индивидуальный трансфер или групповая поездка

  const SimplePetSelectionSheet({
    super.key,
    this.initialPet,
    required this.onPetSelected,
    this.isIndividualTrip = false, // По умолчанию - групповая поездка
  });

  @override
  State<SimplePetSelectionSheet> createState() =>
      _SimplePetSelectionSheetState();
}

class _SimplePetSelectionSheetState extends State<SimplePetSelectionSheet> {
  PetCategory _selectedCategory = PetCategory.upTo5kgWithCarrier;

  @override
  void initState() {
    super.initState();
    if (widget.initialPet != null) {
      _selectedCategory = widget.initialPet!.category;
    }
  }

  void _savePet() {
    // Создаём PetInfo с автозаполнением breed
    final pet = PetInfo(
      category: _selectedCategory,
      breed: PetInfo.getDefaultBreed(_selectedCategory),
      agreementAccepted: true, // Автоматически true
    );

    widget.onPetSelected(pet);
    Navigator.of(context).pop(); // Закрываем диалог
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.70, // 70% экрана (было 65%)
      decoration: BoxDecoration(
        color: theme.systemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
              ), // Добавлен padding снизу
              child: Column(
                children: [
                  _buildCategorySelection(theme),
                  const SizedBox(height: 24),
                  _buildInfoCard(theme),
                ],
              ),
            ),
          ),
          _buildButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(CustomTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.separator.withOpacity(0.2)),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                widget.onPetSelected(null);
                Navigator.of(context).pop(); // Закрываем диалог
              },
              child: Icon(CupertinoIcons.xmark, color: theme.label),
            ),
          ),
          Text(
            'Выбор животного',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.label,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection(CustomTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Категория животного',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.label,
          ),
        ),
        const SizedBox(height: 12),
        _buildCategoryOption(PetCategory.upTo5kgWithCarrier, theme),
        // Для групповой поездки показываем вариант "без переноски"
        if (!widget.isIndividualTrip) ...[
          const SizedBox(height: 12),
          _buildCategoryOption(PetCategory.upTo5kgWithoutCarrier, theme),
        ],
        const SizedBox(height: 12),
        _buildCategoryOption(PetCategory.over6kg, theme),
      ],
    );
  }

  Widget _buildCategoryOption(PetCategory category, CustomTheme theme) {
    final isSelected = _selectedCategory == category;
    final petInfo = PetInfo(
      category: category,
      breed: '',
      agreementAccepted: false,
    );

    // Получаем текст категории с учетом типа трансфера
    String categoryText = petInfo.categoryDescription;
    if (widget.isIndividualTrip && category == PetCategory.upTo5kgWithCarrier) {
      categoryText = 'До 5 кг'; // Убираем "в переноске" для индивидуального
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primary.withOpacity(0.1)
              : theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.primary
                : theme.separator.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: isSelected ? theme.primary : theme.secondaryLabel,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.label,
                    ),
                  ),
                  if (category == PetCategory.over6kg &&
                      !widget.isIndividualTrip) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Только индивидуальный трансфер',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              category == PetCategory.upTo5kgWithCarrier
                  ? 'Бесплатно'
                  : '+${petInfo.cost.toInt()} ₽',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: category == PetCategory.upTo5kgWithCarrier
                    ? CupertinoColors.systemGreen
                    : theme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(CustomTheme theme) {
    final petInfo = PetInfo(
      category: _selectedCategory,
      breed: '',
      agreementAccepted: false,
    );

    // Предупреждение для категории over6kg (только для групповой поездки)
    if (petInfo.requiresIndividualTrip && !widget.isIndividualTrip) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.systemOrange.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: CupertinoColors.systemOrange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Важно!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Для животных свыше 6 кг доступна только индивидуальная поездка (8000₽). Итого: ${petInfo.totalCost.toInt()} ₽',
                    style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Для индивидуального трансфера не показываем информационную карточку
    if (widget.isIndividualTrip) {
      return const SizedBox.shrink();
    }

    // Информация для других категорий (только для групповой поездки)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _selectedCategory == PetCategory.upTo5kgWithCarrier
                ? CupertinoIcons.checkmark_seal_fill
                : CupertinoIcons.info_circle_fill,
            color: CupertinoColors.systemBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedCategory == PetCategory.upTo5kgWithCarrier
                  ? 'Животное перевозится в переноске в салоне автомобиля'
                  : 'Животное перевозится без переноски в салоне автомобиля',
              style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(CustomTheme theme) {
    return SafeArea(
      top: false, // Верх не нужен
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondarySystemBackground,
          border: Border(
            top: BorderSide(color: theme.separator.withOpacity(0.2)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: CupertinoButton(
                onPressed: () {
                  widget.onPetSelected(null);
                  Navigator.of(context).pop(); // Закрываем диалог
                },
                color: theme.quaternaryLabel,
                child: const Text(
                  'Отмена',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CupertinoButton(
                onPressed: _savePet,
                color: CupertinoColors.systemRed,
                child: const Text(
                  'Выбрать',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
