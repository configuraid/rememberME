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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark
                ? AppColors.primaryLight.withOpacity(0.2)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
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

              // Title
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

              // Galerie Option
              _buildBottomSheetOption(
                context: ctx,
                icon: Icons.photo_library_rounded,
                title: AppStrings.chooseFromGallery,
                isDark: isDark,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage();
                },
              ),

              // Kamera Option
              _buildBottomSheetOption(
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

              // Abbrechen
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

  Widget _buildBottomSheetOption({
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
                            AppColors.primaryLight.withOpacity(0.25),
                            AppColors.primaryLight.withOpacity(0.15),
                          ]
                        : [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.primary.withOpacity(0.08),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.primaryLight.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? (isSuccess
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.error.withOpacity(0.3))
                  : Colors.grey.shade200,
              width: 1,
            ),
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

              // Icon mit Animation
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

              // Title
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

              // Message
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

              // Button
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
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : null,
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

                // Profilbild mit besserem Design
                Center(
                  child: Stack(
                    children: [
                      // Outer Glow Ring
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
                                    AppColors.primaryLight.withOpacity(0.3),
                                    AppColors.accent.withOpacity(0.2),
                                  ]
                                : [
                                    AppColors.primary.withOpacity(0.2),
                                    AppColors.accent.withOpacity(0.15),
                                  ],
                          ),
                        ),
                      ),

                      // Avatar
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.4)
                                      : Colors.black.withOpacity(0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : AppColors.primary.withOpacity(0.1),
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (state.profileImageUrl != null
                                      ? NetworkImage(state.profileImageUrl!)
                                      : null) as ImageProvider?,
                              child: _selectedImage == null &&
                                      state.profileImageUrl == null
                                  ? Text(
                                      _nameController.text.isNotEmpty
                                          ? _nameController.text[0]
                                              .toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.primaryLight
                                            : AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),

                      // Camera Button
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
                                        AppColors.primaryLight,
                                        AppColors.primaryLight.withOpacity(0.8),
                                      ]
                                    : [
                                        AppColors.accent,
                                        AppColors.accent.withOpacity(0.9),
                                      ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? AppColors.primaryLight.withOpacity(0.3)
                                      : AppColors.accent.withOpacity(0.4),
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
                ),

                const SizedBox(height: 40),

                // Name Field
                _buildTextField(
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

                // E-Mail Field
                _buildTextField(
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

                // Telefon Field
                _buildTextField(
                  controller: _phoneController,
                  label: AppStrings.phoneOptional,
                  icon: Icons.phone_rounded,
                  isDark: isDark,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 20),

                // Bio Field
                _buildTextField(
                  controller: _bioController,
                  label: AppStrings.aboutMeOptional,
                  icon: Icons.info_outline_rounded,
                  isDark: isDark,
                  maxLines: 4,
                  maxLength: 200,
                ),

                const SizedBox(height: 32),

                // Speichern Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: state.isLoading
                          ? [Colors.grey.shade400, Colors.grey.shade500]
                          : (isDark
                              ? [
                                  AppColors.primaryLight,
                                  AppColors.primaryLight.withOpacity(0.8),
                                ]
                              : [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.9),
                                ]),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: state.isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: isDark
                                  ? AppColors.primaryLight.withOpacity(0.3)
                                  : AppColors.primary.withOpacity(0.4),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
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
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? const Color(0xFF909090) : AppColors.textSecondary,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12, left: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.primaryLight.withOpacity(0.2),
                        AppColors.primaryLight.withOpacity(0.1),
                      ]
                    : [
                        AppColors.primary.withOpacity(0.12),
                        AppColors.primary.withOpacity(0.06),
                      ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              size: 22,
            ),
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: validator,
      ),
    );
  }
}
