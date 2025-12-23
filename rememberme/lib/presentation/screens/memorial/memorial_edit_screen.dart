import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../business_logic/memorial/memorial_bloc.dart';
import '../../../business_logic/memorial/memorial_event.dart';
import '../../../business_logic/memorial/memorial_state.dart';
import '../../../data/models/memorial_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class MemorialEditScreen extends StatefulWidget {
  final MemorialModel memorial;

  const MemorialEditScreen({super.key, required this.memorial});

  @override
  State<MemorialEditScreen> createState() => _MemorialEditScreenState();
}

class _MemorialEditScreenState extends State<MemorialEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _biographyController;

  final ImagePicker _imagePicker = ImagePicker();
  File? _newProfileImage;
  String? _existingImageUrl;

  DateTime? _birthDate;
  DateTime? _deathDate;
  bool _isPublic = false;

  bool _hasChanges = false;

  static const int _maxBiographyLength = 200;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.memorial.name);
    _biographyController =
        TextEditingController(text: widget.memorial.biography ?? '');
    _existingImageUrl = widget.memorial.profileImageUrl;
    _birthDate = widget.memorial.birthDate;
    _deathDate = widget.memorial.deathDate;
    _isPublic = widget.memorial.isPublic;

    _nameController.addListener(_onFieldChanged);
    _biographyController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = _checkForChanges();
    });
  }

  bool _checkForChanges() {
    if (_nameController.text.trim() != widget.memorial.name) return true;
    if (_biographyController.text.trim() != (widget.memorial.biography ?? '')) {
      return true;
    }
    if (_newProfileImage != null) return true;
    if (_birthDate != widget.memorial.birthDate) return true;
    if (_deathDate != widget.memorial.deathDate) return true;
    if (_isPublic != widget.memorial.isPublic) return true;
    return false;
  }

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
          _newProfileImage = File(pickedFile.path);
          _hasChanges = true;
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
            'Foto ändern',
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
                  'Foto ändern',
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

  void _selectBirthDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      _showIOSDatePicker(
        initialDate: _birthDate ?? DateTime(1950),
        onDateChanged: (date) {
          setState(() {
            _birthDate = date;
            _hasChanges = _checkForChanges();
          });
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
        setState(() {
          _birthDate = picked;
          _hasChanges = _checkForChanges();
        });
      }
    }
  }

  void _selectDeathDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      _showIOSDatePicker(
        initialDate: _deathDate ?? DateTime.now(),
        onDateChanged: (date) {
          setState(() {
            _deathDate = date;
            _hasChanges = _checkForChanges();
          });
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
        setState(() {
          _deathDate = picked;
          _hasChanges = _checkForChanges();
        });
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
  // REFACTORED: Speichern mit MemorialModel
  // ============================================================
  void _saveChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedMemorial = widget.memorial.copyWith(
        name: _nameController.text.trim(),
        biography: _biographyController.text.trim(),
        birthDate: _birthDate,
        deathDate: _deathDate,
        isPublic: _isPublic,
      );

      // Event mit optionalem neuen Profilbild senden
      context.read<MemorialBloc>().add(
            MemorialUpdateRequested(
              memorial: updatedMemorial,
              newProfileImage: _newProfileImage,
            ),
          );
    }
  }

  bool _isFormValid() {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasBirthDate = _birthDate != null;
    final hasDeathDate = _deathDate != null;
    final hasBiography = _biographyController.text.trim().isNotEmpty;
    final hasImage = _newProfileImage != null ||
        (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

    return hasName && hasBirthDate && hasDeathDate && hasBiography && hasImage;
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
          content:
              Text(message, style: const TextStyle(color: AppColors.textLight)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showSuccessAndPop() {
    if (Platform.isIOS) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Änderungen gespeichert',
            style: TextStyle(color: AppColors.textLight),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MemorialBloc, MemorialState>(
      listenWhen: (previous, current) {
        return previous.status == MemorialBlocStatus.updating &&
            previous.status != current.status;
      },
      listener: (context, state) {
        if (state.status == MemorialBlocStatus.success) {
          _showSuccessAndPop();
        } else if (state.hasError) {
          _showError(state.errorMessage ?? AppStrings.errorOccurred);
        }
      },
      child: Platform.isIOS ? _buildIOSView() : _buildAndroidView(),
    );
  }

  // ============================================================
  // Android View
  // ============================================================
  Widget _buildAndroidView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.textLight : AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Gedenkseite bearbeiten',
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
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textLight : AppColors.primary,
        ),
        surfaceTintColor: Colors.transparent,
        actions: [
          BlocBuilder<MemorialBloc, MemorialState>(
            builder: (context, state) {
              final isLoading = state.status == MemorialBlocStatus.updating;
              return TextButton(
                onPressed: (_hasChanges && _isFormValid() && !isLoading)
                    ? _saveChanges
                    : null,
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? AppColors.accent : AppColors.primary,
                          ),
                        ),
                      )
                    : Text(
                        'Speichern',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: (_hasChanges && _isFormValid())
                              ? (isDark ? AppColors.accent : AppColors.primary)
                              : AppColors.grey,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAndroidProfileImagePicker(isDark),
              const SizedBox(height: 24),
              _buildAndroidNameField(isDark),
              const SizedBox(height: 20),
              _buildAndroidBiographyField(isDark),
              const SizedBox(height: 20),
              _buildAndroidDateField(
                label: 'Geburtsdatum',
                date: _birthDate,
                onTap: _selectBirthDate,
                icon: Icons.cake_outlined,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildAndroidDateField(
                label: 'Sterbedatum',
                date: _deathDate,
                onTap: _selectDeathDate,
                icon: Icons.event_outlined,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              _buildAndroidVisibilityToggle(isDark),
              const SizedBox(height: 40),
            ],
          ),
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
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showImageSourceSheet,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_newProfileImage != null)
                    Image.file(_newProfileImage!, fit: BoxFit.cover)
                  else if (_existingImageUrl != null &&
                      _existingImageUrl!.isNotEmpty)
                    Image.network(
                      _existingImageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? AppColors.accent : AppColors.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder(isDark, false);
                      },
                    )
                  else
                    _buildImagePlaceholder(isDark, false),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Ändern',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(bool isDark, bool isIOS) {
    return Container(
      color: isDark ? AppColors.backgroundDarkElevated : AppColors.greyLighter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isIOS ? CupertinoIcons.camera : Icons.camera_alt_rounded,
            size: 48,
            color: AppColors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            'Foto hinzufügen',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
              fontFamily: isIOS ? '.SF Pro Text' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidNameField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Name',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
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
              hintText: 'Name der Person',
              hintStyle: TextStyle(color: AppColors.grey),
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
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
              contentPadding: const EdgeInsets.all(12),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAndroidDateField({
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
            Icon(icon, size: 20, color: AppColors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? '${date.day}.${date.month}.${date.year}'
                        : 'Datum auswählen',
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
            Icon(Icons.arrow_forward_ios_rounded,
                size: 20, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidVisibilityToggle(bool isDark) {
    return InkWell(
      onTap: () {
        setState(() {
          _isPublic = !_isPublic;
          _hasChanges = _checkForChanges();
        });
      },
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
                    style: TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                    _hasChanges = _checkForChanges();
                  });
                },
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

  // ============================================================
  // iOS View
  // ============================================================
  Widget _buildIOSView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoNavigationBarBackButton(
          color: isDark ? AppColors.primaryLight : AppColors.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: Text(
          'Gedenkseite bearbeiten',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
            fontFamily: '.SF Pro Text',
          ),
        ),
        trailing: BlocBuilder<MemorialBloc, MemorialState>(
          builder: (context, state) {
            final isLoading = state.status == MemorialBlocStatus.updating;
            return CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: (_hasChanges && _isFormValid() && !isLoading)
                  ? _saveChanges
                  : null,
              child: isLoading
                  ? CupertinoActivityIndicator(
                      color: isDark ? AppColors.grey : null,
                    )
                  : Text(
                      'Sichern',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: (_hasChanges && _isFormValid())
                            ? (isDark ? AppColors.accent : AppColors.primary)
                            : AppColors.grey,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
            );
          },
        ),
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
      ),
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildIOSProfileImagePicker(isDark),
                  const SizedBox(height: 24),
                  _buildIOSNameField(isDark),
                  const SizedBox(height: 20),
                  _buildIOSBiographyField(isDark),
                  const SizedBox(height: 20),
                  _buildIOSDateField(
                    label: 'Geburtsdatum',
                    date: _birthDate,
                    onTap: _selectBirthDate,
                    icon: CupertinoIcons.calendar,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildIOSDateField(
                    label: 'Sterbedatum',
                    date: _deathDate,
                    onTap: _selectDeathDate,
                    icon: CupertinoIcons.calendar_badge_minus,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildIOSVisibilityToggle(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
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
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.greyLighter,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_newProfileImage != null)
                    Image.file(_newProfileImage!, fit: BoxFit.cover)
                  else if (_existingImageUrl != null &&
                      _existingImageUrl!.isNotEmpty)
                    Image.network(
                      _existingImageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CupertinoActivityIndicator(
                            color: isDark ? AppColors.grey : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder(isDark, true);
                      },
                    )
                  else
                    _buildImagePlaceholder(isDark, true),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.camera,
                            size: 16,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Ändern',
                            style: TextStyle(
                              fontSize: 13,
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
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIOSNameField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Name',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: _nameController,
          placeholder: 'Name der Person',
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
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.greyLighter,
            ),
            borderRadius: BorderRadius.circular(10),
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
            Icon(icon, size: 20, color: AppColors.grey),
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
                        : 'Datum auswählen',
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
            Icon(CupertinoIcons.chevron_right, size: 20, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSVisibilityToggle(bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPublic = !_isPublic;
          _hasChanges = _checkForChanges();
        });
      },
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
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                    _hasChanges = _checkForChanges();
                  });
                },
                activeTrackColor: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
