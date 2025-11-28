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
          final isDark = theme.brightness == Brightness.dark;
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
          final isDark = theme.brightness == Brightness.dark;
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
    DateTime tempDate = initialDate;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text(AppStrings.cancel),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: Text(AppStrings.done),
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
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(AppStrings.errorTitle),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: Text(AppStrings.ok),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
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
                          ? const Color(0xFFB0B0B0)
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
            color: Colors.black.withOpacity(0.1),
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
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        icon: Icon(
          Icons.check_rounded,
          color: Colors.grey.shade600,
        ),
        label: Text(
          AppStrings.create,
          style: TextStyle(
            color: Colors.grey.shade600,
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
      label: Text(
        AppStrings.create,
        style: const TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  // ============================================================
  // iOS View - Mit Material Wrapper für korrekte Text-Darstellung
  // ============================================================
  Widget _buildIOSView() {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.createMemorialPage),
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      ),
      // Material Wrapper entfernt gelbe Unterstriche
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: BlocBuilder<MemorialBloc, MemorialState>(
            builder: (context, state) {
              if (state.status == MemorialStatus.creating) {
                return const Center(
                  child: CupertinoActivityIndicator(radius: 20),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildIOSSegmentedControl(),
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
                        disabledColor: CupertinoColors.quaternarySystemFill
                            .resolveFrom(context),
                        child: Text(
                          AppStrings.createMemorialPage,
                          style: TextStyle(
                            fontSize: 16,
                            color: _isFormValid()
                                ? CupertinoColors.white
                                : CupertinoColors.systemGrey
                                    .resolveFrom(context),
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

  Widget _buildIOSSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoSlidingSegmentedControl<CreateTab>(
        groupValue: _currentTab,
        backgroundColor: CupertinoColors.systemGrey5.resolveFrom(context),
        thumbColor: CupertinoColors.white,
        padding: const EdgeInsets.all(0),
        children: {
          CreateTab.details:
              _buildSegment(AppStrings.details, CreateTab.details),
          CreateTab.design: _buildSegment(AppStrings.design, CreateTab.design),
        },
        onValueChanged: (value) {
          if (value != null) {
            setState(() => _currentTab = value);
          }
        },
      ),
    );
  }

  Widget _buildSegment(String text, CreateTab tab) {
    final isSelected = _currentTab == tab;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? CupertinoColors.black
              : CupertinoColors.systemGrey.resolveFrom(context),
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
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.person, size: 20),
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: CupertinoColors.separator.resolveFrom(context),
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
            color: isDark ? AppColors.accent : AppColors.accent,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.createMemorialTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
            fontFamily: '.SF Pro Display',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.preserveMemoriesForever,
          style: TextStyle(
            fontSize: 15,
            color: CupertinoColors.systemGrey,
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
          color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: CupertinoColors.systemGrey,
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
                      color: CupertinoColors.systemGrey.resolveFrom(context),
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
                              ? CupertinoColors.white
                              : CupertinoColors.black)
                          : CupertinoColors.systemGrey.resolveFrom(context),
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: CupertinoColors.systemGrey.resolveFrom(context),
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
          color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              _isPublic ? CupertinoIcons.globe : CupertinoIcons.lock_fill,
              size: 20,
              color: _isPublic
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.systemBlue,
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
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  Text(
                    _isPublic
                        ? 'Jeder mit dem Link kann die Seite sehen'
                        : 'Nur eingeladene Personen',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
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
                activeTrackColor: CupertinoColors.systemGreen,
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
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              fontFamily: '.SF Pro Display',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.designCanBeChangedLater,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.systemGrey,
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
                  : Colors.black)
              : (isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryLight : Colors.black)
                : (isDark
                    ? const Color(0xFF38383A)
                    : CupertinoColors.separator.resolveFrom(context)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: isDark
                    ? AppColors.primaryLight.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                              Colors.black,
                              Colors.grey.shade900,
                            ])
                      : (isDark
                          ? [
                              const Color(0xFF1C1C1E),
                              const Color(0xFF2C2C2E),
                            ]
                          : [
                              CupertinoColors.systemGrey6.color,
                              CupertinoColors.systemGrey5.color,
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
                                ? CupertinoColors.white.withOpacity(0.3)
                                : CupertinoColors.white.withOpacity(0.2))
                            : (isDark
                                ? CupertinoColors.white.withOpacity(0.1)
                                : CupertinoColors.systemGrey3.color),
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
                                : CupertinoColors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
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
                                    ? CupertinoColors.black
                                    : CupertinoColors.black,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppStrings.selected,
                                style: TextStyle(
                                  color: isDark
                                      ? CupertinoColors.black
                                      : CupertinoColors.black,
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
                        : Colors.black)
                    : (isDark
                        ? const Color(0xFF1C1C1E)
                        : CupertinoColors.white),
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
                                    ? (isDark
                                        ? CupertinoColors.white
                                        : CupertinoColors.white)
                                    : (isDark
                                        ? CupertinoColors.white
                                        : CupertinoColors.black),
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
                                        ? CupertinoColors.systemGrey
                                        : CupertinoColors.systemGrey3.color)
                                    : CupertinoColors.systemGrey,
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
                                        : CupertinoColors.white
                                            .withOpacity(0.15))
                                    : (isDark
                                        ? const Color(0xFF2C2C2E)
                                        : CupertinoColors.systemGrey6.color),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.primaryLight
                                              .withOpacity(0.3)
                                          : CupertinoColors.white
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
                                      ? (isDark
                                          ? CupertinoColors.white
                                          : CupertinoColors.white)
                                      : (isDark
                                          ? CupertinoColors.white
                                          : CupertinoColors.systemGrey),
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
  // Android Content (unverändert)
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
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: AppStrings.personName,
                hintText: AppStrings.personNameHint,
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
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
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
                  ? const Color(0xFF909090)
                  : (_isPublic ? Colors.green : AppColors.primary),
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
                      color: isDark
                          ? const Color(0xFF707070)
                          : AppColors.textSecondary,
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
                activeColor: Colors.green,
                activeTrackColor: Colors.green.withOpacity(0.3),
                inactiveThumbColor:
                    isDark ? const Color(0xFF606060) : Colors.grey.shade400,
                inactiveTrackColor:
                    isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
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
              color: isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary,
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
            color: isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary,
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
                : (isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary),
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
                  : Colors.black)
              : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryLight : Colors.black)
                : (isDark ? const Color(0xFF404040) : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: isDark
                    ? AppColors.primaryLight.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                              Colors.black,
                              Colors.grey.shade900,
                            ])
                      : (isDark
                          ? [
                              const Color(0xFF1E1E1E),
                              const Color(0xFF2A2A2A),
                            ]
                          : [
                              Colors.grey.shade100,
                              Colors.grey.shade200,
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
                                ? Colors.white.withOpacity(0.3)
                                : Colors.white.withOpacity(0.2))
                            : (isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade400),
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
                            color:
                                isDark ? AppColors.primaryLight : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
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
                                color: isDark ? Colors.black : Colors.black,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppStrings.selected,
                                style: TextStyle(
                                  color: isDark ? Colors.black : Colors.black,
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
                        : Colors.black)
                    : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
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
                                    ? (isDark
                                        ? AppColors.textLight
                                        : Colors.white)
                                    : (isDark
                                        ? AppColors.textLight
                                        : Colors.black87),
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
                                        ? const Color(0xFFB0B0B0)
                                        : Colors.grey.shade400)
                                    : (isDark
                                        ? const Color(0xFFB0B0B0)
                                        : Colors.grey.shade600),
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
                                        : Colors.white.withOpacity(0.15))
                                    : (isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.primaryLight
                                              .withOpacity(0.3)
                                          : Colors.white.withOpacity(0.3))
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.textLight
                                          : Colors.white)
                                      : (isDark
                                          ? AppColors.textLight
                                          : Colors.grey.shade700),
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
