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
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickImage();
            },
            child: const Text('Aus Galerie wählen'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _takePhoto();
            },
            child: const Text('Foto aufnehmen'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Abbrechen'),
        ),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final userId = context.read<AuthBloc>().state.user?.id;
      if (userId != null) {
        print('💾 Speichere Profil für User: $userId');
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
    // ✅ BlocConsumer mit CupertinoAlertDialog
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.isSuccess && state.successMessage != null) {
          // ✅ Zeige Erfolg mit Cupertino Dialog
          showCupertinoDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 48,
              ),
              content: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(state.successMessage!),
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Dialog schließen
                    Navigator.of(context).pop(); // Screen schließen
                  },
                ),
              ],
            ),
          );
        }

        if (state.hasError && state.errorMessage != null) {
          // ✅ Zeige Fehler mit Cupertino Dialog
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Icon(
                Icons.error,
                color: AppColors.error,
                size: 48,
              ),
              content: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(state.errorMessage!),
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil bearbeiten'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profilbild
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (state.profileImageUrl != null
                                ? NetworkImage(state.profileImageUrl!)
                                : null) as ImageProvider?,
                        child: _selectedImage == null &&
                                state.profileImageUrl == null
                            ? Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 48,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte geben Sie einen Namen ein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // E-Mail
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-Mail',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte geben Sie eine E-Mail-Adresse ein';
                    }
                    if (!value.contains('@')) {
                      return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Telefon
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Telefon (optional)',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Bio
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'Über mich (optional)',
                    prefixIcon: const Icon(Icons.info_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 200,
                ),

                const SizedBox(height: 32),

                // ✅ Speichern Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Änderungen speichern',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
