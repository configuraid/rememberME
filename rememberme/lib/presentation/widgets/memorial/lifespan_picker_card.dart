import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

import 'package:rememberme/core/constants/app_colors.dart';

class LifespanPickerCard extends StatelessWidget {
  final DateTime? birthDate;
  final DateTime? deathDate;
  final ValueChanged<DateTime?> onBirthDateChanged;
  final ValueChanged<DateTime?> onDeathDateChanged;
  final bool isRequired;

  const LifespanPickerCard({
    super.key,
    this.birthDate,
    this.deathDate,
    required this.onBirthDateChanged,
    required this.onDeathDateChanged,
    this.isRequired = true,
  });

  String? _calculateAge() {
    if (birthDate == null || deathDate == null) return null;
    int years = deathDate!.year - birthDate!.year;
    if (deathDate!.month < birthDate!.month ||
        (deathDate!.month == birthDate!.month &&
            deathDate!.day < birthDate!.day)) {
      years--;
    }
    if (years < 0) return null;
    return years == 1 ? '1 Jahr' : '$years Jahre';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _showLifespanPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (Platform.isIOS) {
      _showIOSLifespanPicker(context, isDark);
    } else {
      _showAndroidLifespanPicker(context, isDark);
    }
  }

  void _showIOSLifespanPicker(BuildContext context, bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _IOSLifespanPickerSheet(
        initialBirthDate: birthDate,
        initialDeathDate: deathDate,
        onBirthDateChanged: onBirthDateChanged,
        onDeathDateChanged: onDeathDateChanged,
        isDark: isDark,
      ),
    );
  }

  void _showAndroidLifespanPicker(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AndroidLifespanPickerSheet(
        initialBirthDate: birthDate,
        initialDeathDate: deathDate,
        onBirthDateChanged: onBirthDateChanged,
        onDeathDateChanged: onDeathDateChanged,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final age = _calculateAge();
    final hasAnyDate = birthDate != null || deathDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              'Lebensdaten',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
                fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Karte
        GestureDetector(
          onTap: () => _showLifespanPicker(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
              ),
            ),
            child: hasAnyDate
                ? _buildFilledContent(isDark, age)
                : _buildEmptyContent(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyContent(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Lebensdaten eingeben',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.accent : AppColors.primary,
            fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Platform.isIOS
              ? CupertinoIcons.chevron_right
              : Icons.chevron_right_rounded,
          size: 20,
          color: AppColors.grey,
        ),
      ],
    );
  }

  Widget _buildFilledContent(bool isDark, String? age) {
    final primaryColor = isDark ? AppColors.accent : AppColors.primary;
    final ageBgColor = Color.fromRGBO(
      primaryColor.red,
      primaryColor.green,
      primaryColor.blue,
      0.1,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: _DateDisplay(
                label: 'geb.',
                date: _formatDate(birthDate),
                isDark: isDark,
                isEmpty: birthDate == null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Flexible(
              child: _DateDisplay(
                label: 'gest.',
                date: _formatDate(deathDate),
                isDark: isDark,
                isEmpty: deathDate == null,
              ),
            ),
          ],
        ),
        if (age != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: ageBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              age,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.accent : AppColors.primary,
                fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DateDisplay extends StatelessWidget {
  final String label;
  final String date;
  final bool isDark;
  final bool isEmpty;

  const _DateDisplay({
    required this.label,
    required this.date,
    required this.isDark,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            date,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
              color: isEmpty
                  ? AppColors.grey
                  : (isDark ? AppColors.textLight : AppColors.textPrimary),
              fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// iOS Bottom Sheet
// ============================================================
class _IOSLifespanPickerSheet extends StatefulWidget {
  final DateTime? initialBirthDate;
  final DateTime? initialDeathDate;
  final ValueChanged<DateTime?> onBirthDateChanged;
  final ValueChanged<DateTime?> onDeathDateChanged;
  final bool isDark;

  const _IOSLifespanPickerSheet({
    this.initialBirthDate,
    this.initialDeathDate,
    required this.onBirthDateChanged,
    required this.onDeathDateChanged,
    required this.isDark,
  });

  @override
  State<_IOSLifespanPickerSheet> createState() =>
      _IOSLifespanPickerSheetState();
}

class _IOSLifespanPickerSheetState extends State<_IOSLifespanPickerSheet> {
  late DateTime _birthDate;
  late DateTime _deathDate;
  int _selectedSegment = 0;

  @override
  void initState() {
    super.initState();
    _birthDate = widget.initialBirthDate ?? DateTime(1950);
    _deathDate = widget.initialDeathDate ?? DateTime.now();
  }

  String? _calculateAge() {
    int years = _deathDate.year - _birthDate.year;
    if (_deathDate.month < _birthDate.month ||
        (_deathDate.month == _birthDate.month &&
            _deathDate.day < _birthDate.day)) {
      years--;
    }
    if (years < 0) return null;
    return years == 1 ? '1 Jahr' : '$years Jahre';
  }

  void _save() {
    widget.onBirthDateChanged(_birthDate);
    widget.onDeathDateChanged(_deathDate);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge();
    final primaryColor = widget.isDark ? AppColors.accent : AppColors.primary;
    final ageBgColor = Color.fromRGBO(
      primaryColor.red,
      primaryColor.green,
      primaryColor.blue,
      0.1,
    );
    final segmentBgColor = widget.isDark
        ? AppColors.backgroundDark
        : Color.fromRGBO(
            AppColors.greyLighter.red,
            AppColors.greyLighter.green,
            AppColors.greyLighter.blue,
            0.5,
          );

    return Container(
      height: 420,
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppColors.backgroundDarkElevated
            : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Abbrechen',
                    style: TextStyle(
                      color:
                          widget.isDark ? AppColors.accent : AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _save,
                  child: Text(
                    'Fertig',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          widget.isDark ? AppColors.accent : AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _selectedSegment,
                backgroundColor: segmentBgColor,
                thumbColor: widget.isDark
                    ? AppColors.backgroundDarkElevated
                    : AppColors.surface,
                children: {
                  0: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Geboren',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontWeight: FontWeight.w500,
                        color: widget.isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  1: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Verstorben',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontWeight: FontWeight.w500,
                        color: widget.isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                },
                onValueChanged: (value) {
                  setState(() => _selectedSegment = value!);
                },
              ),
            ),
          ),

          // Altersanzeige
          if (age != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ageBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  age,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? AppColors.accent : AppColors.primary,
                    fontFamily: '.SF Pro Text',
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),

          Expanded(
            child: CupertinoDatePicker(
              key: ValueKey(_selectedSegment),
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _selectedSegment == 0 ? _birthDate : _deathDate,
              minimumDate: DateTime(1900),
              maximumDate: DateTime.now(),
              onDateTimeChanged: (date) {
                setState(() {
                  if (_selectedSegment == 0) {
                    _birthDate = date;
                  } else {
                    _deathDate = date;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Android Bottom Sheet
// ============================================================
class _AndroidLifespanPickerSheet extends StatefulWidget {
  final DateTime? initialBirthDate;
  final DateTime? initialDeathDate;
  final ValueChanged<DateTime?> onBirthDateChanged;
  final ValueChanged<DateTime?> onDeathDateChanged;
  final bool isDark;

  const _AndroidLifespanPickerSheet({
    this.initialBirthDate,
    this.initialDeathDate,
    required this.onBirthDateChanged,
    required this.onDeathDateChanged,
    required this.isDark,
  });

  @override
  State<_AndroidLifespanPickerSheet> createState() =>
      _AndroidLifespanPickerSheetState();
}

class _AndroidLifespanPickerSheetState
    extends State<_AndroidLifespanPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _birthDate;
  late DateTime _deathDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _birthDate = widget.initialBirthDate ?? DateTime(1950);
    _deathDate = widget.initialDeathDate ?? DateTime.now();
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _calculateAge() {
    int years = _deathDate.year - _birthDate.year;
    if (_deathDate.month < _birthDate.month ||
        (_deathDate.month == _birthDate.month &&
            _deathDate.day < _birthDate.day)) {
      years--;
    }
    if (years < 0) return null;
    return years == 1 ? '1 Jahr' : '$years Jahre';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _selectDate(bool isBirth) async {
    final initialDate = isBirth ? _birthDate : _deathDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: widget.isDark ? AppColors.accent : AppColors.primary,
                  surface: widget.isDark
                      ? AppColors.backgroundDarkElevated
                      : AppColors.surface,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isBirth) {
          _birthDate = picked;
        } else {
          _deathDate = picked;
        }
      });
    }
  }

  void _save() {
    widget.onBirthDateChanged(_birthDate);
    widget.onDeathDateChanged(_deathDate);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge();
    final primaryColor = widget.isDark ? AppColors.accent : AppColors.primary;
    final ageBgColor = Color.fromRGBO(
      primaryColor.red,
      primaryColor.green,
      primaryColor.blue,
      0.1,
    );
    final tabBgColor = widget.isDark
        ? AppColors.backgroundDark
        : Color.fromRGBO(
            AppColors.greyLighter.red,
            AppColors.greyLighter.green,
            AppColors.greyLighter.blue,
            0.5,
          );
    final previewBgColor = Color.fromRGBO(
      primaryColor.red,
      primaryColor.green,
      primaryColor.blue,
      0.05,
    );
    final previewBorderColor = Color.fromRGBO(
      primaryColor.red,
      primaryColor.green,
      primaryColor.blue,
      0.2,
    );

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppColors.backgroundDarkElevated
            : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Abbrechen',
                    style: TextStyle(
                      color:
                          widget.isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  'Lebensdaten',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? AppColors.textLight
                        : AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: Text(
                    'Fertig',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          widget.isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: tabBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: widget.isDark
                    ? AppColors.backgroundDarkElevated
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              dividerColor: Colors.transparent,
              labelColor:
                  widget.isDark ? AppColors.textLight : AppColors.textPrimary,
              unselectedLabelColor: AppColors.grey,
              tabs: const [
                Tab(text: 'Geboren'),
                Tab(text: 'Verstorben'),
              ],
            ),
          ),

          // Altersanzeige
          if (age != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: ageBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                age,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? AppColors.accent : AppColors.primary,
                ),
              ),
            ),

          // Date Selection Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _tabController.index == 0
                  ? _buildDateCard(
                      key: const ValueKey('birth'),
                      label: 'Geburtsdatum',
                      date: _birthDate,
                      onTap: () => _selectDate(true),
                    )
                  : _buildDateCard(
                      key: const ValueKey('death'),
                      label: 'Sterbedatum',
                      date: _deathDate,
                      onTap: () => _selectDate(false),
                    ),
            ),
          ),

          // Visual Preview
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: previewBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: previewBorderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'geb. ${_formatDate(_birthDate)}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          widget.isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 16,
                    height: 2,
                    color: AppColors.greyLight,
                  ),
                ),
                Flexible(
                  child: Text(
                    'gest. ${_formatDate(_deathDate)}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark
                          ? AppColors.textLight
                          : AppColors.textPrimary,
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

  Widget _buildDateCard({
    required Key key,
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              widget.isDark ? AppColors.backgroundDark : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isDark ? AppColors.borderDark : AppColors.greyLighter,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color:
                    widget.isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tippen zum Ändern',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
