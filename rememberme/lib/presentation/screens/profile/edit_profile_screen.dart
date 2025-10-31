import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../business_logic/auth/auth_state.dart';
import '../../../business_logic/profile/profile_bloc.dart';
import '../../../business_logic/profile/profile_event.dart';
import '../../../business_logic/profile/profile_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/common/loading_indicator.dart';

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

      // Bild sofort hochladen
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

      // Bild sofort hochladen
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
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Aus Galerie wählen'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Foto aufnehmen'),
              onTap: () {
                Navigator.of(ctx).pop();
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Abbrechen'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
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

        // Nach erfolgreichem Speichern zurück
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil bearbeiten'),
            actions: [
              if (state.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: _saveProfile,
                  child: const Text(
                    'Speichern',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
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
              ],
            ),
          ),
        );
      },
    );
  }
}
