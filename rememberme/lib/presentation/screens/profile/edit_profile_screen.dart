import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
            color: isDark ? AppColors.surfaceDark : Colors.white,
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
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.changeProfileImage,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.divider.withOpacity(0.2)
                        : AppColors.divider),
                _buildIOSActionSheetOption(
                  icon: Icons.photo_library_outlined,
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
                    color: isDark
                        ? AppColors.divider.withOpacity(0.2)
                        : AppColors.divider),
                _buildIOSActionSheetOption(
                  icon: Icons.camera_alt_outlined,
                  title: AppStrings.takePhoto,
                  isDark: isDark,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _takePhoto();
                  },
                ),
                Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.divider.withOpacity(0.2)
                        : AppColors.divider),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      AppStrings.cancel,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.accent : AppColors.primary,
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
    return InkWell(
      onTap: onTap,
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
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF404040) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  AppStrings.changeProfileImage,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF909090)
                            : Colors.grey.shade600,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.accent.withOpacity(0.25),
                            AppColors.accent.withOpacity(0.15),
                          ]
                        : [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.primary.withOpacity(0.08),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.textLight : AppColors.textPrimary,
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

  void _showResultDialog({
    required bool isSuccess,
    required String message,
    required bool isDark,
  }) {
    if (Platform.isIOS) {
      _showResultDialogIOS(
          isSuccess: isSuccess, message: message, isDark: isDark);
    } else {
      _showResultDialogAndroid(
        isSuccess: isSuccess,
        message: message,
        isDark: isDark,
      );
    }
  }

  void _showResultDialogIOS({
    required bool isSuccess,
    required String message,
    required bool isDark,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              size: 64,
              color: isSuccess ? AppColors.success : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              isSuccess ? AppStrings.successTitle : AppStrings.errorTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? AppColors.textSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (isSuccess) {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              AppStrings.ok,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDialogAndroid({
    required bool isSuccess,
    required String message,
    required bool isDark,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSuccess
                        ? [
                            AppColors.success.withOpacity(0.2),
                            AppColors.success.withOpacity(0.1),
                          ]
                        : [
                            AppColors.error.withOpacity(0.2),
                            AppColors.error.withOpacity(0.1),
                          ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSuccess
                        ? AppColors.success.withOpacity(0.4)
                        : AppColors.error.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                  size: 64,
                  color: isSuccess ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  isSuccess ? AppStrings.successTitle : AppStrings.errorTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? const Color(0xFFB0B0B0)
                            : AppColors.textSecondary,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      if (isSuccess) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSuccess ? AppColors.success : AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppStrings.ok,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.isSuccess && state.successMessage != null) {
          _showResultDialog(
            isSuccess: true,
            message: state.successMessage!,
            isDark: isDark,
          );
        }

        if (state.hasError && state.errorMessage != null) {
          _showResultDialog(
            isSuccess: false,
            message: state.errorMessage!,
            isDark: isDark,
          );
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
    return Scaffold(
      backgroundColor: isDark ? AppColors.primaryDark : AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.editProfile),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: Form(
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
                  icon: Icons.person_outline,
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
                _buildIOSDivider(isDark),
                _buildIOSCardTextField(
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
            _buildIOSSectionHeader('Über mich', isDark),
            const SizedBox(height: 8),
            _buildIOSInfoCard(
              isDark: isDark,
              children: [
                _buildIOSCardTextField(
                  controller: _bioController,
                  label: AppStrings.aboutMeOptional,
                  icon: Icons.info_outline,
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
    );
  }

  Widget _buildIOSProfileImageCard(ProfileState state, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.primaryLight.withOpacity(0.3),
                            AppColors.primary.withOpacity(0.2),
                          ]
                        : [
                            AppColors.secondary.withOpacity(0.3),
                            AppColors.secondaryLight.withOpacity(0.2),
                          ],
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
                                  color: isDark
                                      ? AppColors.accent
                                      : AppColors.primary,
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [AppColors.accent, AppColors.accentLight]
                            : [AppColors.primary, AppColors.primaryLight],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isDark ? AppColors.surfaceDark : AppColors.surface,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.accent : AppColors.primary)
                              .withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
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
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
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
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
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
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
        color: isDark ? AppColors.divider.withOpacity(0.2) : AppColors.divider,
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
            size: 22,
            color: isDark ? AppColors.accent : AppColors.primary,
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
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
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

  Widget _buildIOSSaveButton(ProfileState state, bool isDark) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: state.isLoading
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : (isDark
                  ? [AppColors.accent, AppColors.accentLight]
                  : [AppColors.primary, AppColors.primaryLight]),
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: state.isLoading
            ? []
            : [
                BoxShadow(
                  color: (isDark ? AppColors.accent : AppColors.primary)
                      .withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: state.isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: state.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                AppStrings.saveChanges,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
      ),
    );
  }

  // ==================== ANDROID LAYOUT ====================
  Widget _buildAndroidLayout(
      BuildContext context, ProfileState state, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.primaryDark : null,
      appBar: AppBar(
        title: const Text(AppStrings.editProfile),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            _buildAndroidProfileImage(state, isDark),
            const SizedBox(height: 40),
            _buildAndroidTextField(
              controller: _nameController,
              label: AppStrings.name,
              icon: Icons.person_rounded,
              isDark: isDark,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.enterName;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildAndroidTextField(
              controller: _emailController,
              label: AppStrings.email,
              icon: Icons.email_rounded,
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
            const SizedBox(height: 20),
            _buildAndroidTextField(
              controller: _phoneController,
              label: AppStrings.phoneOptional,
              icon: Icons.phone_rounded,
              isDark: isDark,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            _buildAndroidTextField(
              controller: _bioController,
              label: AppStrings.aboutMeOptional,
              icon: Icons.info_outline_rounded,
              isDark: isDark,
              maxLines: 4,
              maxLength: 200,
            ),
            const SizedBox(height: 32),
            _buildAndroidSaveButton(state, isDark),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidProfileImage(ProfileState state, bool isDark) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 136,
            height: 136,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.accent.withOpacity(0.3),
                        AppColors.accentLight.withOpacity(0.2),
                      ]
                    : [
                        AppColors.secondary.withOpacity(0.3),
                        AppColors.secondaryLight.withOpacity(0.2),
                      ],
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: isDark
                      ? AppColors.primaryLight.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.1),
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (state.profileImageUrl != null
                          ? NetworkImage(state.profileImageUrl!)
                          : null) as ImageProvider?,
                  child: _selectedImage == null && state.profileImageUrl == null
                      ? Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? AppColors.accent : AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.accent,
                            AppColors.accentLight,
                          ]
                        : [
                            AppColors.primary,
                            AppColors.primaryLight,
                          ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.accent : AppColors.primary)
                          .withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : AppColors.shadow.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        style: TextStyle(
          color: isDark ? AppColors.textLight : AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12, left: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.accent.withOpacity(0.25),
                        AppColors.accent.withOpacity(0.12),
                      ]
                    : [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.08),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.accent : AppColors.primary,
              size: 20,
            ),
          ),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          alignLabelWithHint: maxLines > 1,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildAndroidSaveButton(ProfileState state, bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: state.isLoading
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : (isDark
                  ? [
                      AppColors.accent,
                      AppColors.accentLight,
                    ]
                  : [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ]),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: state.isLoading
            ? []
            : [
                BoxShadow(
                  color: (isDark ? AppColors.accent : AppColors.primary)
                      .withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: state.isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: state.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.save_rounded,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.saveChanges,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}
