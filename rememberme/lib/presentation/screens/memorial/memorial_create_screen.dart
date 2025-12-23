import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/memorial/memorial_bloc.dart';
import '../../../business_logic/memorial/memorial_event.dart';
import '../../../business_logic/memorial/memorial_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';

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
  final _biographyController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  File? _profileImage;

  DateTime? _birthDate;
  DateTime? _deathDate;
  String _selectedTemplate = 'classic';
  bool _isPublic = false;
  CreateTab _currentTab = CreateTab.details;

  late TabController _tabController;

  static const int _maxBiographyLength = 200;

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

    _biographyController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _biographyController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // Image Picker Methoden
  // ============================================================
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError('Fehler beim Auswählen des Bildes: $e');
    }
  }

  void _showImageSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(
            'Foto auswählen',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.camera,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Kamera',
                    style: TextStyle(
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.photo,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Galerie',
                    style: TextStyle(
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.cancel,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor:
            isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Foto auswählen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.accent.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                  title: Text(
                    'Kamera',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Neues Foto aufnehmen',
                    style: TextStyle(color: AppColors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.accent.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                  title: Text(
                    'Galerie',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Aus Fotos auswählen',
                    style: TextStyle(color: AppColors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _profileImage = null;
    });
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
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: isDark ? AppColors.accent : AppColors.primary,
                    surface: isDark
                        ? AppColors.backgroundDarkElevated
                        : AppColors.surface,
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
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: isDark ? AppColors.accent : AppColors.primary,
                    surface: isDark
                        ? AppColors.backgroundDarkElevated
                        : AppColors.surface,
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
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text(
                    AppStrings.cancel,
                    style: TextStyle(
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: Text(
                    AppStrings.done,
                    style: TextStyle(
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
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

  // ============================================================
  // Memorial erstellen
  // ============================================================
  void _createMemorial() {
    if (_formKey.currentState?.validate() ?? false) {
      final authState = context.read<AuthBloc>().state;
      final user = authState.user;

      if (user == null) {
        _showError(AppStrings.userNotFound);
        return;
      }

      if (_profileImage == null) {
        _showError('Bitte wählen Sie ein Foto aus');
        return;
      }

      context.read<MemorialBloc>().add(
            MemorialCreateRequested(
              ownerId: user.id,
              name: _nameController.text.trim(),
              templateId: _selectedTemplate,
              profileImage: _profileImage!,
              biography: _biographyController.text.trim(),
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
    final hasProfileImage = _profileImage != null;
    final hasBiography = _biographyController.text.trim().isNotEmpty;

    return hasName &&
        hasBirthDate &&
        hasDeathDate &&
        hasProfileImage &&
        hasBiography;
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
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                AppStrings.ok,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
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
        // ✅ FIX: Nach erfolgreicher Erstellung zum HomeScreen navigieren
        // Das stellt sicher, dass die Tab-Bar sichtbar ist
        if (state.status == MemorialBlocStatus.success &&
            state.memorials.isNotEmpty) {
          // Navigiere zum HomeScreen (ersetzt den gesamten Stack)
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
            AppRoutes.home,
            (route) => false,
          );
        }

        if (state.hasError) {
          _showError(state.errorMessage ?? AppStrings.errorOccurred);
        }
      },
      child: Platform.isIOS ? _buildIOSView() : _buildAndroidView(),
    );
  }

  Widget _buildAndroidView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.createMemorialPage,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
        foregroundColor: isDark ? AppColors.textLight : AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading:
            false, // Kein Back-Button da inline gerendert
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildMaterialTabBar(isDark),
        ),
      ),
      body: BlocBuilder<MemorialBloc, MemorialState>(
        builder: (context, state) {
          if (state.status == MemorialBlocStatus.creating) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.creatingMemorial,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: isDark ? AppColors.textLight : AppColors.textPrimary,
        unselectedLabelColor: AppColors.grey,
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
        tabs: [
          Tab(text: AppStrings.details),
          Tab(text: AppStrings.design),
        ],
      ),
    );
  }

  Widget _buildFAB(bool isDark) {
    final isValid = _isFormValid();

    return FloatingActionButton.extended(
      onPressed: isValid ? _createMemorial : null,
      backgroundColor: isValid
          ? (isDark ? AppColors.accent : AppColors.primary)
          : (isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter),
      elevation: isValid ? 4 : 0,
      icon: Icon(
        Icons.check_rounded,
        color: isValid
            ? (isDark ? AppColors.primary : AppColors.background)
            : AppColors.grey,
      ),
      label: Text(
        AppStrings.create,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isValid
              ? (isDark ? AppColors.primary : AppColors.background)
              : AppColors.grey,
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
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
            fontFamily: '.SF Pro Text',
          ),
        ),
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
        automaticallyImplyLeading: false, // Kein Back-Button
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: BlocBuilder<MemorialBloc, MemorialState>(
            builder: (context, state) {
              if (state.status == MemorialBlocStatus.creating) {
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
                      height: 50,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        color: _isFormValid()
                            ? (isDark ? AppColors.accent : AppColors.primary)
                            : (isDark
                                ? AppColors.toastBackgroundDark
                                : AppColors.greyLighter),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _isFormValid() ? _createMemorial : null,
                        child: Text(
                          AppStrings.createMemorialPage,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _isFormValid()
                                ? (isDark
                                    ? AppColors.primary
                                    : AppColors.background)
                                : AppColors.grey,
                            fontFamily: '.SF Pro Text',
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
        color: isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoSlidingSegmentedControl<CreateTab>(
        groupValue: _currentTab,
        backgroundColor:
            isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
        thumbColor:
            isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
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
          fontFamily: '.SF Pro Text',
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
            _buildIOSProfileImagePicker(isDark),
            const SizedBox(height: 20),
            CupertinoTextField(
              controller: _nameController,
              placeholder: AppStrings.personName,
              placeholderStyle: TextStyle(color: AppColors.grey),
              style: TextStyle(
                fontSize: 17,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontFamily: '.SF Pro Text',
              ),
              prefix: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  CupertinoIcons.person,
                  size: 20,
                  color: isDark ? AppColors.accent : AppColors.primary,
                ),
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDarkElevated
                    : AppColors.surface,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            _buildIOSBiographyField(isDark),
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
                color: AppColors.info.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withOpacity(isDark ? 0.4 : 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle,
                    color: isDark
                        ? AppColors.info.withOpacity(0.9)
                        : AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.fieldsCanBeEditedLater,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.info.withOpacity(0.9)
                            : AppColors.info,
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

  Widget _buildIOSProfileImagePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Foto',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
                fontFamily: '.SF Pro Text',
              ),
            ),
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
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              border: Border.all(
                color: _profileImage != null
                    ? (isDark ? AppColors.accent : AppColors.primary)
                    : (isDark ? AppColors.borderDark : AppColors.greyLighter),
                width: _profileImage != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _profileImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _profileImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.xmark,
                              size: 16,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.camera,
                                size: 14,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Ändern',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textLight,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.accent.withOpacity(0.2)
                              : AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.camera,
                          size: 32,
                          color: isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Foto hinzufügen',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.accent : AppColors.primary,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tippen zum Auswählen',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.grey,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildIOSBiographyField(bool isDark) {
    final currentLength = _biographyController.text.length;
    final isOverLimit = currentLength > _maxBiographyLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Gedenkspruch',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
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
            ),
            Text(
              '$currentLength/$_maxBiographyLength',
              style: TextStyle(
                fontSize: 12,
                color: isOverLimit ? AppColors.error : AppColors.grey,
                fontWeight: isOverLimit ? FontWeight.w600 : FontWeight.normal,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: _biographyController,
          placeholder: 'Erzählen Sie etwas über diese Person...',
          placeholderStyle: TextStyle(color: AppColors.grey),
          maxLines: 4,
          maxLength: _maxBiographyLength,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
            fontFamily: '.SF Pro Text',
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            border: Border.all(
              color: isOverLimit
                  ? AppColors.error
                  : (isDark ? AppColors.borderDark : AppColors.greyLighter),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  Widget _buildIOSHeader(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.accent : AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.accent.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            CupertinoIcons.heart_fill,
            size: 48,
            color: isDark ? AppColors.background : AppColors.primary,
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
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          ),
          borderRadius: BorderRadius.circular(10),
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
                      fontSize: 17,
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
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              _isPublic ? CupertinoIcons.globe : CupertinoIcons.lock_fill,
              size: 20,
              color: _isPublic
                  ? AppColors.accent
                  : (isDark ? AppColors.grey : AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isPublic ? 'Öffentlich' : 'Privat',
                    style: TextStyle(
                      fontSize: 17,
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
                      fontSize: 13,
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
                activeTrackColor: AppColors.accent,
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
                : (isDark ? AppColors.borderDark : AppColors.greyLighter),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 32),
            _buildAndroidProfileImagePicker(isDark),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDarkElevated
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                ),
              ),
              child: TextFormField(
                controller: _nameController,
                style: TextStyle(
                  fontSize: 17,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: AppStrings.personName,
                  hintText: AppStrings.personNameHint,
                  labelStyle: TextStyle(color: AppColors.grey),
                  hintStyle: TextStyle(color: AppColors.grey),
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: isDark ? AppColors.accent : AppColors.primary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.enterPersonName;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildAndroidBiographyField(isDark),
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
                color: AppColors.info.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withOpacity(isDark ? 0.4 : 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isDark
                        ? AppColors.info.withOpacity(0.9)
                        : AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.fieldsCanBeEditedLater,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.info.withOpacity(0.9)
                            : AppColors.info,
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

  Widget _buildAndroidProfileImagePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Foto',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
            ),
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
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showImageSourceSheet,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              border: Border.all(
                color: _profileImage != null
                    ? (isDark ? AppColors.accent : AppColors.primary)
                    : (isDark ? AppColors.borderDark : AppColors.greyLighter),
                width: _profileImage != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _profileImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _profileImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: _removeImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Ändern',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.accent.withOpacity(0.2)
                              : AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 32,
                          color: isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Foto hinzufügen',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tippen zum Auswählen',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAndroidBiographyField(bool isDark) {
    final currentLength = _biographyController.text.length;
    final isOverLimit = currentLength > _maxBiographyLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Gedenkspruch',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                  ),
                ),
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
            ),
            Text(
              '$currentLength/$_maxBiographyLength',
              style: TextStyle(
                fontSize: 12,
                color: isOverLimit ? AppColors.error : AppColors.grey,
                fontWeight: isOverLimit ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isOverLimit
                  ? AppColors.error
                  : (isDark ? AppColors.borderDark : AppColors.greyLighter),
            ),
          ),
          child: TextFormField(
            controller: _biographyController,
            maxLines: 4,
            maxLength: _maxBiographyLength,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Erzählen Sie etwas über diese Person...',
              hintStyle: TextStyle(color: AppColors.grey),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAndroidVisibilityToggle(bool isDark) {
    return InkWell(
      onTap: () => setState(() => _isPublic = !_isPublic),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              _isPublic ? Icons.public_rounded : Icons.lock_rounded,
              size: 20,
              color: _isPublic
                  ? AppColors.accent
                  : (isDark ? AppColors.grey : AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isPublic ? 'Öffentlich' : 'Privat',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _isPublic
                        ? 'Jeder mit dem Link kann die Seite sehen'
                        : 'Nur eingeladene Personen',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey,
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
                activeColor: AppColors.accent,
                activeTrackColor: AppColors.accent.withOpacity(0.3),
                inactiveThumbColor:
                    isDark ? AppColors.greyDark : AppColors.grey,
                inactiveTrackColor: isDark
                    ? AppColors.toastBackgroundDark
                    : AppColors.greyLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignContent(bool isDark) {
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
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.designCanBeChangedLater,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.accent : AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.accent.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.favorite_rounded,
            size: 48,
            color: isDark ? AppColors.background : AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.createMemorialTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.greyLighter,
          ),
          borderRadius: BorderRadius.circular(10),
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
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? '${date.day}.${date.month}.${date.year}'
                        : AppStrings.selectDate,
                    style: TextStyle(
                      fontSize: 17,
                      color: date != null
                          ? (isDark
                              ? AppColors.textLight
                              : AppColors.textPrimary)
                          : AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 20,
              color: AppColors.grey,
            ),
          ],
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
              : (isDark ? AppColors.backgroundDarkElevated : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryLight : AppColors.textPrimary)
                : (isDark ? AppColors.borderDark : AppColors.greyLighter),
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
                                        ? AppColors.grey
                                        : AppColors.greyLight)
                                    : AppColors.grey,
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
