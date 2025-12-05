import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/auth/auth_state.dart';
import '../../../business_logic/profile/profile_bloc.dart';
import '../../../business_logic/profile/profile_event.dart';
import '../../../business_logic/profile/profile_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profileState = context.read<ProfileBloc>().state;
    final authState = context.read<AuthBloc>().state;

    _nameController = TextEditingController(
      text: profileState.name ?? authState.user?.name ?? '',
    );
    _emailController = TextEditingController(
      text: profileState.email ?? authState.user?.email ?? '',
    );
    _phoneController = TextEditingController(
      text: profileState.phone ?? '',
    );
    _bioController = TextEditingController(
      text: profileState.bio ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ============================================================
  // Toast Implementierung
  // ============================================================
  void _showToast(String message, {bool isSuccess = true}) {
    if (Platform.isIOS) {
      _showIOSToast(message, isSuccess: isSuccess);
    } else {
      _showAndroidSnackBar(message, isSuccess: isSuccess);
    }
  }

  void _showIOSToast(String message, {bool isSuccess = true}) {
    final overlay = Overlay.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _IOSBottomToast(
        message: message,
        isDark: isDark,
        isSuccess: isSuccess,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _showAndroidSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_rounded : Icons.error_rounded,
                color: AppColors.textLight,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        elevation: 4,
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });

      final userId = context.read<AuthBloc>().state.user?.id;
      if (userId != null) {
        context.read<ProfileBloc>().add(
              ProfileImageUpdateRequested(
                userId: userId,
                imagePath: image.path,
              ),
            );
      }
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
      });

      final userId = context.read<AuthBloc>().state.user?.id;
      if (userId != null) {
        context.read<ProfileBloc>().add(
              ProfileImageUpdateRequested(
                userId: userId,
                imagePath: photo.path,
              ),
            );
      }
    }
  }

  void _showImageSourceDialog() {
    if (Platform.isIOS) {
      _showImageSourceDialogIOS();
    } else {
      _showImageSourceDialogAndroid();
    }
  }

  void _showImageSourceDialogIOS() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.changeProfileImage,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.divider,
                ),
                _buildIOSActionSheetOption(
                  icon: CupertinoIcons.photo,
                  title: AppStrings.chooseFromGallery,
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage();
                  },
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: isDark ? AppColors.borderDark : AppColors.divider,
                ),
                _buildIOSActionSheetOption(
                  icon: CupertinoIcons.camera,
                  title: AppStrings.takePhoto,
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _takePhoto();
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.divider,
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      AppStrings.cancel,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIOSActionSheetOption({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                color: isDark ? AppColors.accent : AppColors.primary,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialogAndroid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  AppStrings.changeProfileImage,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
              ),
              _buildAndroidBottomSheetOption(
                context: ctx,
                icon: Icons.photo_library_rounded,
                title: AppStrings.chooseFromGallery,
                isDark: isDark,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage();
                },
              ),
              _buildAndroidBottomSheetOption(
                context: ctx,
                icon: Icons.camera_alt_rounded,
                title: AppStrings.takePhoto,
                isDark: isDark,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _takePhoto();
                },
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppStrings.cancel,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidBottomSheetOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.toastBackgroundDark
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final userId = context.read<AuthBloc>().state.user?.id;
      if (userId != null) {
        context.read<ProfileBloc>().add(
              ProfileUpdateRequested(
                userId: userId,
                name: _nameController.text,
                email: _emailController.text,
                phone: _phoneController.text,
                bio: _bioController.text,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.isSuccess && state.successMessage != null) {
          _showToast(state.successMessage!, isSuccess: true);

          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
        }

        if (state.hasError && state.errorMessage != null) {
          _showToast(state.errorMessage!, isSuccess: false);
        }
      },
      builder: (context, state) {
        if (Platform.isIOS) {
          return _buildIOSLayout(context, state, isDark);
        } else {
          return _buildAndroidLayout(context, state, isDark);
        }
      },
    );
  }

  // ==================== iOS LAYOUT ====================
  Widget _buildIOSLayout(
      BuildContext context, ProfileState state, bool isDark) {
    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          AppStrings.editProfile,
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
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 24),
              _buildIOSProfileImageCard(state, isDark),
              const SizedBox(height: 24),
              _buildIOSSectionHeader('Persönliche Informationen', isDark),
              const SizedBox(height: 8),
              _buildIOSInfoCard(
                isDark: isDark,
                children: [
                  _buildIOSCardTextField(
                    controller: _nameController,
                    label: AppStrings.name,
                    icon: CupertinoIcons.person,
                    isDark: isDark,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.enterName;
                      }
                      return null;
                    },
                  ),
                  _buildIOSDivider(isDark),
                  _buildIOSCardTextField(
                    controller: _emailController,
                    label: AppStrings.email,
                    icon: CupertinoIcons.mail,
                    isDark: isDark,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.enterEmail;
                      }
                      if (!value.contains('@')) {
                        return AppStrings.enterValidEmail;
                      }
                      return null;
                    },
                  ),
                  _buildIOSDivider(isDark),
                  _buildIOSCardTextField(
                    controller: _phoneController,
                    label: AppStrings.phoneOptional,
                    icon: CupertinoIcons.phone,
                    isDark: isDark,
                    keyboardType: TextInputType.phone,
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildIOSSectionHeader('Über mich', isDark),
              const SizedBox(height: 8),
              _buildIOSInfoCard(
                isDark: isDark,
                children: [
                  _buildIOSCardTextField(
                    controller: _bioController,
                    label: AppStrings.aboutMeOptional,
                    icon: CupertinoIcons.info_circle,
                    isDark: isDark,
                    maxLines: 4,
                    maxLength: 200,
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildIOSSaveButton(state, isDark),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSProfileImageCard(ProfileState state, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.4),
                  border: Border.all(
                    color: AppColors.accent,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : (state.profileImageUrl != null
                          ? Image.network(state.profileImageUrl!,
                              fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                  fontFamily: '.SF Pro Display',
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            )),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.backgroundDarkElevated
                            : AppColors.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.camera_fill,
                      size: 16,
                      color: isDark ? AppColors.primary : AppColors.background,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.isNotEmpty
                ? _nameController.text
                : 'Dein Name',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
              fontFamily: '.SF Pro Display',
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _emailController.text.isNotEmpty
                ? _emailController.text
                : 'deine@email.de',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
              fontFamily: '.SF Pro Text',
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.grey,
          letterSpacing: 0.5,
          fontFamily: '.SF Pro Text',
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildIOSInfoCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildIOSDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: isDark ? AppColors.borderDark : AppColors.divider,
      ),
    );
  }

  Widget _buildIOSCardTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        maxLines > 1 ? 12 : 0,
        16,
        maxLines > 1 ? 12 : 0,
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.grey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              maxLength: maxLength,
              style: TextStyle(
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontSize: 17,
                fontFamily: '.SF Pro Text',
              ),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(
                  color: AppColors.grey,
                  fontSize: 17,
                  fontFamily: '.SF Pro Text',
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: maxLines > 1 ? 8 : 12,
                ),
                counterText: '',
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSSaveButton(ProfileState state, bool isDark) {
    return SizedBox(
      height: 50,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        color: state.isLoading
            ? (isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter)
            : (isDark ? AppColors.accent : AppColors.primary),
        borderRadius: BorderRadius.circular(12),
        onPressed: state.isLoading ? null : _saveProfile,
        child: state.isLoading
            ? CupertinoActivityIndicator(
                color: AppColors.grey,
              )
            : Text(
                AppStrings.saveChanges,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: state.isLoading
                      ? AppColors.grey
                      : (isDark ? AppColors.primary : AppColors.background),
                  fontFamily: '.SF Pro Text',
                ),
              ),
      ),
    );
  }

  // ==================== ANDROID LAYOUT ====================
  Widget _buildAndroidLayout(
      BuildContext context, ProfileState state, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.editProfile,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? AppColors.backgroundDarkElevated.withOpacity(0.8)
            : AppColors.surface.withOpacity(0.94),
        foregroundColor: isDark ? AppColors.textLight : AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 24),
            _buildAndroidProfileImageCard(state, isDark),
            const SizedBox(height: 24),
            _buildAndroidSectionHeader('Persönliche Informationen', isDark),
            const SizedBox(height: 8),
            _buildAndroidInfoCard(
              isDark: isDark,
              children: [
                _buildAndroidCardTextField(
                  controller: _nameController,
                  label: AppStrings.name,
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.enterName;
                    }
                    return null;
                  },
                ),
                _buildAndroidDivider(isDark),
                _buildAndroidCardTextField(
                  controller: _emailController,
                  label: AppStrings.email,
                  icon: Icons.email_outlined,
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.enterEmail;
                    }
                    if (!value.contains('@')) {
                      return AppStrings.enterValidEmail;
                    }
                    return null;
                  },
                ),
                _buildAndroidDivider(isDark),
                _buildAndroidCardTextField(
                  controller: _phoneController,
                  label: AppStrings.phoneOptional,
                  icon: Icons.phone_outlined,
                  isDark: isDark,
                  keyboardType: TextInputType.phone,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildAndroidSectionHeader('Über mich', isDark),
            const SizedBox(height: 8),
            _buildAndroidInfoCard(
              isDark: isDark,
              children: [
                _buildAndroidCardTextField(
                  controller: _bioController,
                  label: AppStrings.aboutMeOptional,
                  icon: Icons.info_outline_rounded,
                  isDark: isDark,
                  maxLines: 4,
                  maxLength: 200,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildAndroidSaveButton(state, isDark),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidProfileImageCard(ProfileState state, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.4),
                  border: Border.all(
                    color: AppColors.accent,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : (state.profileImageUrl != null
                          ? Image.network(state.profileImageUrl!,
                              fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            )),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.backgroundDarkElevated
                            : AppColors.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: isDark ? AppColors.primary : AppColors.background,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.isNotEmpty
                ? _nameController.text
                : 'Dein Name',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _emailController.text.isNotEmpty
                ? _emailController.text
                : 'deine@email.de',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAndroidInfoCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.greyLighter,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildAndroidDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: isDark ? AppColors.borderDark : AppColors.divider,
      ),
    );
  }

  Widget _buildAndroidCardTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        maxLines > 1 ? 12 : 0,
        16,
        maxLines > 1 ? 12 : 0,
      ),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.grey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              maxLength: maxLength,
              style: TextStyle(
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
                fontSize: 17,
              ),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(
                  color: AppColors.grey,
                  fontSize: 17,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: maxLines > 1 ? 8 : 12,
                ),
                counterText: '',
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidSaveButton(ProfileState state, bool isDark) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: state.isLoading ? null : _saveProfile,
        style: FilledButton.styleFrom(
          backgroundColor: state.isLoading
              ? (isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter)
              : (isDark ? AppColors.accent : AppColors.primary),
          foregroundColor: state.isLoading
              ? AppColors.grey
              : (isDark ? AppColors.primary : AppColors.background),
          disabledBackgroundColor:
              isDark ? AppColors.toastBackgroundDark : AppColors.greyLighter,
          disabledForegroundColor: AppColors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: state.isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.grey),
                ),
              )
            : Text(
                AppStrings.saveChanges,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

// ============================================================
// iOS Native Bottom Toast
// ============================================================
class _IOSBottomToast extends StatefulWidget {
  final String message;
  final bool isDark;
  final bool isSuccess;
  final VoidCallback onDismiss;

  const _IOSBottomToast({
    required this.message,
    required this.isDark,
    required this.isSuccess,
    required this.onDismiss,
  });

  @override
  State<_IOSBottomToast> createState() => _IOSBottomToastState();
}

class _IOSBottomToastState extends State<_IOSBottomToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();

    HapticFeedback.lightImpact();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: bottomPadding + 100,
      left: 0,
      right: 0,
      child: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? AppColors.toastBackgroundDark.withOpacity(0.95)
                        : AppColors.toastBackgroundLight.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isDark
                            ? AppColors.shadowDark
                            : AppColors.shadow,
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: widget.isDark
                          ? AppColors.borderDarkLight
                          : AppColors.greyLighter,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: widget.isSuccess
                              ? AppColors.success
                              : AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isSuccess
                              ? CupertinoIcons.checkmark_alt
                              : CupertinoIcons.xmark,
                          color: AppColors.textLight,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                            fontFamily: '.SF Pro Text',
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
