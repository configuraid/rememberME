import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_event.dart';
import 'package:rememberme/business_logic/memorial/memorial_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

enum CreateTab { details, design }

class MemorialCreateScreen extends StatefulWidget {
  const MemorialCreateScreen({super.key});

  @override
  State<MemorialCreateScreen> createState() => _MemorialCreateScreenState();
}

class _MemorialCreateScreenState extends State<MemorialCreateScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  DateTime? _birthDate;
  DateTime? _deathDate;
  String _selectedTemplate = 'classic';
  bool _isPublic = false;
  CreateTab _currentTab = CreateTab.details;

  late TabController _tabController;

  final List<Map<String, dynamic>> _templates = [
    {
      'id': 'classic',
      'name': AppStrings.templateClassic,
      'description': AppStrings.templateClassicDescription,
      'icon': Icons.auto_awesome,
    },
    {
      'id': 'modern',
      'name': AppStrings.templateModern,
      'description': AppStrings.templateModernDescription,
      'icon': Icons.light_mode,
    },
    {
      'id': 'nature',
      'name': AppStrings.templateNature,
      'description': AppStrings.templateNatureDescription,
      'icon': Icons.nature,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTab =
              _tabController.index == 0 ? CreateTab.details : CreateTab.design;
        });
      }
    });

    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _selectBirthDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      _showIOSDatePicker(
        initialDate: _birthDate ?? DateTime(1950),
        onDateChanged: (date) {
          setState(() => _birthDate = date);
        },
      );
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _birthDate ?? DateTime(1950),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          final theme = Theme.of(context);
          return Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() => _birthDate = picked);
      }
    }
  }

  void _selectDeathDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      _showIOSDatePicker(
        initialDate: _deathDate ?? DateTime.now(),
        onDateChanged: (date) {
          setState(() => _deathDate = date);
        },
      );
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _deathDate ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          final theme = Theme.of(context);
          return Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() => _deathDate = picked);
      }
    }
  }

  void _showIOSDatePicker({
    required DateTime initialDate,
    required Function(DateTime) onDateChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime tempDate = initialDate;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text(
                    AppStrings.cancel,
                    style: TextStyle(color: AppColors.interactive),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: Text(
                    AppStrings.done,
                    style: TextStyle(color: AppColors.interactive),
                  ),
                  onPressed: () {
                    onDateChanged(tempDate);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: DateTime(1900),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (date) {
                  tempDate = date;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createMemorial() {
    if (_formKey.currentState?.validate() ?? false) {
      final authState = context.read<AuthBloc>().state;
      final user = authState.user;

      if (user == null) {
        _showError(AppStrings.userNotFound);
        return;
      }

      if (user.primaryOrganizationId == null) {
        _showError(AppStrings.organizationNotFound);
        return;
      }

      context.read<MemorialBloc>().add(
            MemorialCreateRequested(
              organizationId: user.primaryOrganizationId!,
              ownerId: user.id,
              name: _nameController.text.trim(),
              templateId: _selectedTemplate,
              birthDate: _birthDate,
              deathDate: _deathDate,
              isPublic: _isPublic,
            ),
          );
    }
  }

  bool _isFormValid() {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasBirthDate = _birthDate != null;
    final hasDeathDate = _deathDate != null;

    return hasName && hasBirthDate && hasDeathDate;
  }

  void _showError(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            AppStrings.errorTitle,
            style: TextStyle(
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                AppStrings.ok,
                style: TextStyle(color: AppColors.interactive),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MemorialBloc, MemorialState>(
      listener: (context, state) {
        if (state.status == MemorialStatus.success) {
          Navigator.of(context).pop();
        } else if (state.hasError) {
          _showError(state.errorMessage ?? AppStrings.errorOccurred);
        }
      },
      child: Platform.isIOS ? _buildIOSView() : _buildAndroidView(),
    );
  }

  Widget _buildAndroidView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDarkSecondary : AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.createMemorialPage),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildMaterialTabBar(isDark),
        ),
      ),
      body: BlocBuilder<MemorialBloc, MemorialState>(
        builder: (context, state) {
          if (state.status == MemorialStatus.creating) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.creatingMemorial,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsContent(isDark),
              _buildDesignContent(isDark),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(isDark),
    );
  }

  Widget _buildMaterialTabBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.textLight,
        indicatorWeight: 3,
        labelColor: AppColors.textLight,
        unselectedLabelColor: AppColors.textLight.withOpacity(0.6),
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(
            icon: const Icon(Icons.person_outline_rounded, size: 20),
            text: AppStrings.details,
          ),
          Tab(
            icon: const Icon(Icons.palette_outlined, size: 20),
            text: AppStrings.design,
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(bool isDark) {
    if (!_isFormValid()) {
      return FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: isDark ? AppColors.greyDark : AppColors.greyLight,
        icon: Icon(
          Icons.check_rounded,
          color: AppColors.grey,
        ),
        label: Text(
          AppStrings.create,
          style: TextStyle(
            color: AppColors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return FloatingActionButton.extended(
      onPressed: _createMemorial,
      backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
      elevation: 4,
      icon: const Icon(Icons.check_rounded, color: AppColors.textLight),
      label: const Text(
        AppStrings.create,
        style: TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  // ============================================================
  // iOS View
  // ============================================================
  Widget _buildIOSView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          AppStrings.createMemorialPage,
          style: TextStyle(
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.94)
            : AppColors.surface.withOpacity(0.94),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: BlocBuilder<MemorialBloc, MemorialState>(
            builder: (context, state) {
              if (state.status == MemorialStatus.creating) {
                return Center(
                  child: CupertinoActivityIndicator(
                    radius: 20,
                    color: isDark ? AppColors.grey : null,
                  ),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildIOSSegmentedControl(isDark),
                  ),
                  Expanded(
                    child: _currentTab == CreateTab.details
                        ? _buildIOSDetailsContent(isDark)
                        : _buildIOSDesignContent(isDark),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: _isFormValid() ? _createMemorial : null,
                        disabledColor: isDark
                            ? AppColors.borderDarkSubtle
                            : AppColors.greyLighter,
                        child: Text(
                          AppStrings.createMemorialPage,
                          style: TextStyle(
                            fontSize: 16,
                            color: _isFormValid()
                                ? AppColors.textLight
                                : AppColors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIOSSegmentedControl(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBorderDark : AppColors.greyLighter,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoSlidingSegmentedControl<CreateTab>(
        groupValue: _currentTab,
        backgroundColor:
            isDark ? AppColors.cardBorderDark : AppColors.greyLighter,
        thumbColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        padding: const EdgeInsets.all(0),
        children: {
          CreateTab.details:
              _buildSegment(AppStrings.details, CreateTab.details, isDark),
          CreateTab.design:
              _buildSegment(AppStrings.design, CreateTab.design, isDark),
        },
        onValueChanged: (value) {
          if (value != null) {
            setState(() => _currentTab = value);
          }
        },
      ),
    );
  }

  Widget _buildSegment(String text, CreateTab tab, bool isDark) {
    final isSelected = _currentTab == tab;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? (isDark ? AppColors.textLight : AppColors.textPrimary)
              : AppColors.grey,
        ),
      ),
    );
  }

  // ============================================================
  // iOS Details Content
  // ============================================================
  Widget _buildIOSDetailsContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIOSHeader(isDark),
            const SizedBox(height: 32),
            CupertinoTextField(
              controller: _nameController,
              placeholder: AppStrings.personName,
              placeholderStyle: TextStyle(color: AppColors.grey),
              style: TextStyle(
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
              prefix: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  CupertinoIcons.person,
                  size: 20,
                  color: isDark ? AppColors.accent : AppColors.interactive,
                ),
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDarkElevated
                    : AppColors.surface,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.divider,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 20),
            _buildIOSDateField(
              label: AppStrings.birthDate,
              date: _birthDate,
              onTap: _selectBirthDate,
              icon: CupertinoIcons.calendar,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildIOSDateField(
              label: AppStrings.deathDate,
              date: _deathDate,
              onTap: _selectDeathDate,
              icon: CupertinoIcons.calendar_badge_minus,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            _buildIOSVisibilityToggle(isDark),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryLight.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.primaryLight.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.fieldsCanBeEditedLater,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSHeader(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.primaryLight.withOpacity(0.2),
                      AppColors.accent.withOpacity(0.2),
                    ]
                  : [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.accent.withOpacity(0.1),
                    ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.primaryLight.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            CupertinoIcons.heart_fill,
            size: 48,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.createMemorialTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
            fontFamily: '.SF Pro Display',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.preserveMemoriesForever,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.grey,
            fontFamily: '.SF Pro Text',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildIOSDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.divider,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? '${date.day}.${date.month}.${date.year}'
                        : AppStrings.selectDate,
                    style: TextStyle(
                      fontSize: 16,
                      color: date != null
                          ? (isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary)
                          : AppColors.grey,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSVisibilityToggle(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _isPublic = !_isPublic),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.divider,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              _isPublic ? CupertinoIcons.globe : CupertinoIcons.lock_fill,
              size: 20,
              color: _isPublic ? AppColors.success : AppColors.interactive,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isPublic ? 'Öffentlich' : 'Privat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  Text(
                    _isPublic
                        ? 'Jeder mit dem Link kann die Seite sehen'
                        : 'Nur eingeladene Personen',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.85,
              child: CupertinoSwitch(
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                activeTrackColor: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // iOS Design Content
  // ============================================================
  Widget _buildIOSDesignContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.chooseDesign,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Display',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.designCanBeChangedLater,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          const SizedBox(height: 24),
          ..._templates.map((template) {
            return _buildIOSTemplateCard(template, isDark);
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildIOSTemplateCard(Map<String, dynamic> template, bool isDark) {
    final isSelected = _selectedTemplate == template['id'];

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTemplate = template['id']);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.primaryLight.withOpacity(0.1)
                  : AppColors.textPrimary)
              : (isDark ? AppColors.backgroundDarkElevated : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryLight : AppColors.textPrimary)
                : (isDark ? AppColors.borderDark : AppColors.divider),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: isDark
                    ? AppColors.primaryLight.withOpacity(0.3)
                    : AppColors.shadowDark,
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              )
            else
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isSelected ? 140 : 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? (isDark
                          ? [
                              AppColors.primaryLight.withOpacity(0.3),
                              AppColors.primaryLight.withOpacity(0.1),
                            ]
                          : [
                              AppColors.textPrimary,
                              AppColors.primaryDark,
                            ])
                      : (isDark
                          ? [
                              AppColors.backgroundDarkElevated,
                              AppColors.toastBackgroundDark,
                            ]
                          : [
                              AppColors.greyLighter,
                              AppColors.greyLight,
                            ]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      scale: isSelected ? 1.2 : 1.0,
                      child: Icon(
                        template['icon'],
                        size: 56,
                        color: isSelected
                            ? (isDark
                                ? AppColors.textLight.withOpacity(0.3)
                                : AppColors.textLight.withOpacity(0.2))
                            : (isDark
                                ? AppColors.textLight.withOpacity(0.1)
                                : AppColors.grey),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppStrings.selected,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? AppColors.primaryLight.withOpacity(0.1)
                        : AppColors.textPrimary)
                    : (isDark
                        ? AppColors.backgroundDarkElevated
                        : AppColors.surface),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template['name'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.textLight
                                    : (isDark
                                        ? AppColors.textLight
                                        : AppColors.textPrimary),
                                fontFamily: '.SF Pro Display',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              template['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.grey
                                        : AppColors.greyLight)
                                    : AppColors.grey,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getTemplateFeatureTags(template['id'])
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.primaryLight
                                            .withOpacity(0.2)
                                        : AppColors.textLight.withOpacity(0.15))
                                    : (isDark
                                        ? AppColors.toastBackgroundDark
                                        : AppColors.greyLighter),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.primaryLight
                                              .withOpacity(0.3)
                                          : AppColors.textLight
                                              .withOpacity(0.3))
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.textLight
                                      : (isDark
                                          ? AppColors.textLight
                                          : AppColors.grey),
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Android Content
  // ============================================================
  Widget _buildDetailsContent(bool isDark) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              style: TextStyle(
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: AppStrings.personName,
                hintText: AppStrings.personNameHint,
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintStyle: TextStyle(color: AppColors.grey),
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.enterPersonName;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildDateField(
              label: AppStrings.birthDateRequired,
              date: _birthDate,
              onTap: _selectBirthDate,
              icon: Icons.cake_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildDateField(
              label: AppStrings.deathDateRequired,
              date: _deathDate,
              onTap: _selectDeathDate,
              icon: Icons.event_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            _buildAndroidVisibilityToggle(isDark),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryLight.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.primaryLight.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.fieldsCanBeEditedLater,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidVisibilityToggle(bool isDark) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => setState(() => _isPublic = !_isPublic),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.greyLight,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              _isPublic ? Icons.public_rounded : Icons.lock_rounded,
              size: 20,
              color: isDark
                  ? AppColors.grey
                  : (_isPublic ? AppColors.success : AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isPublic ? 'Öffentlich' : 'Privat',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _isPublic
                        ? 'Jeder mit dem Link kann die Seite sehen'
                        : 'Nur eingeladene Personen',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          isDark ? AppColors.greyDark : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                activeColor: AppColors.success,
                activeTrackColor: AppColors.success.withOpacity(0.3),
                inactiveThumbColor:
                    isDark ? AppColors.greyDark : AppColors.grey,
                inactiveTrackColor:
                    isDark ? AppColors.cardBorderDark : AppColors.greyLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignContent(bool isDark) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.chooseDesign,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.designCanBeChangedLater,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ..._templates.map((template) {
            return _buildTemplateCard(template, isDark);
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.primaryLight.withOpacity(0.2),
                      AppColors.accent.withOpacity(0.2),
                    ]
                  : [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.accent.withOpacity(0.1),
                    ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.primaryLight.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.favorite_rounded,
            size: 48,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.createMemorialTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.preserveMemoriesForever,
          style: theme.textTheme.bodyLarge?.copyWith(
            color:
                isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(
            icon,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
          suffixIcon: Icon(
            Icons.calendar_today_rounded,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
        child: Text(
          date != null
              ? '${date.day}.${date.month}.${date.year}'
              : AppStrings.selectDate,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: date != null
                ? (isDark ? AppColors.textLight : AppColors.textPrimary)
                : (isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template, bool isDark) {
    final isSelected = _selectedTemplate == template['id'];

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTemplate = template['id']);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.primaryLight.withOpacity(0.1)
                  : AppColors.textPrimary)
              : (isDark ? AppColors.cardBorderDark : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryLight : AppColors.textPrimary)
                : (isDark ? AppColors.borderDarkSubtle : AppColors.greyLight),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: isDark
                    ? AppColors.primaryLight.withOpacity(0.3)
                    : AppColors.shadowDark,
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              )
            else
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isSelected ? 140 : 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? (isDark
                          ? [
                              AppColors.primaryLight.withOpacity(0.3),
                              AppColors.primaryLight.withOpacity(0.1),
                            ]
                          : [
                              AppColors.textPrimary,
                              AppColors.primaryDark,
                            ])
                      : (isDark
                          ? [
                              AppColors.surfaceDark,
                              AppColors.cardBorderDark,
                            ]
                          : [
                              AppColors.greyLighter,
                              AppColors.greyLight,
                            ]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      scale: isSelected ? 1.2 : 1.0,
                      child: Icon(
                        template['icon'],
                        size: 56,
                        color: isSelected
                            ? (isDark
                                ? AppColors.textLight.withOpacity(0.3)
                                : AppColors.textLight.withOpacity(0.2))
                            : (isDark
                                ? AppColors.textLight.withOpacity(0.1)
                                : AppColors.grey),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.textPrimary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppStrings.selected,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? AppColors.primaryLight.withOpacity(0.1)
                        : AppColors.textPrimary)
                    : (isDark ? AppColors.cardBorderDark : AppColors.surface),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.textLight
                                    : (isDark
                                        ? AppColors.textLight
                                        : AppColors.textPrimary),
                              ),
                              child: Text(template['name']),
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.textDarkSecondary
                                        : AppColors.grey)
                                    : (isDark
                                        ? AppColors.textDarkSecondary
                                        : AppColors.greyDark),
                              ),
                              child: Text(template['description']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getTemplateFeatureTags(template['id'])
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.primaryLight
                                            .withOpacity(0.2)
                                        : AppColors.textLight.withOpacity(0.15))
                                    : (isDark
                                        ? AppColors.surfaceDark
                                        : AppColors.greyLighter),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.primaryLight
                                              .withOpacity(0.3)
                                          : AppColors.textLight
                                              .withOpacity(0.3))
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.textLight
                                      : (isDark
                                          ? AppColors.textLight
                                          : AppColors.greyDark),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getTemplateFeatureTags(String templateId) {
    switch (templateId) {
      case 'classic':
        return [
          AppStrings.featureTimeless,
          AppStrings.featureElegant,
          AppStrings.featureTraditional,
        ];
      case 'modern':
        return [
          AppStrings.featureModern,
          AppStrings.featureMinimalist,
          AppStrings.featureInteractive,
        ];
      case 'nature':
        return [
          AppStrings.featureNatural,
          AppStrings.featureCalming,
          AppStrings.featureHarmonious,
        ];
      default:
        return [];
    }
  }
}
