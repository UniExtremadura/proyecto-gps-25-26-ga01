// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:audira_frontend/core/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/auth_service.dart';
import '../../../config/theme.dart';
import '../../../core/api/api_client.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;

  bool _isLoading = false;
  bool _hasChanges = false;
  File? _selectedImage;
  File? _selectedBanner;
  bool _isUploadingBanner = false;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _locationController = TextEditingController(text: user?.location ?? '');
    _websiteController = TextEditingController(text: user?.website ?? '');

    _firstNameController.addListener(() => setState(() => _hasChanges = true));
    _lastNameController.addListener(() => setState(() => _hasChanges = true));
    _bioController.addListener(() => setState(() => _hasChanges = true));
    _locationController.addListener(() => setState(() => _hasChanges = true));
    _websiteController.addListener(() => setState(() => _hasChanges = true));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final updates = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
      };

      final ApiResponse<User> response =
          await authService.updateProfile(updates);

      if (response.success) {
        await context.read<AuthProvider>().refreshProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          setState(() => _hasChanges = false);
        }
      } else {
        throw Exception(response.error ?? 'Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuario no identificado');
      }

      final authService = AuthService();
      final response =
          await authService.uploadProfileImage(_selectedImage!, userId);

      if (response.success) {
        await authProvider.refreshProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil actualizada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response.error ?? 'Error al subir imagen');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _pickBannerImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedBanner = File(pickedFile.path);
        });
        await _uploadBannerImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar banner: $e')),
        );
      }
    }
  }

  Future<void> _uploadBannerImage() async {
    if (_selectedBanner == null) return;

    setState(() => _isUploadingBanner = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;

      if (userId == null) throw Exception('Usuario no identificado');

      final authService = AuthService();
      final response = await authService.uploadBannerImage(_selectedBanner!, userId);

      if (response.success) {
        await authProvider.refreshProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Banner actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response.error ?? 'Error al subir banner');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingBanner = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    // Banner editable
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: _selectedBanner == null &&
                                        context.read<AuthProvider>().currentUser?.bannerImageUrl == null
                                    ? AppTheme.primaryBlue.withOpacity(0.2)
                                    : null,
                                image: _selectedBanner != null
                                    ? DecorationImage(
                                        image: FileImage(_selectedBanner!),
                                        fit: BoxFit.cover,
                                      )
                                    : (context.read<AuthProvider>().currentUser?.bannerImageUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(
                                                context.read<AuthProvider>().currentUser!.bannerImageUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                              ),
                              child: (_selectedBanner == null &&
                                      context.read<AuthProvider>().currentUser?.bannerImageUrl == null)
                                  ? Center(
                                      child: Text(
                                        'Seleccione una imagen para el baner',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: AppTheme.textGrey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    )
                                  : null,
                            ),
                            // Botón para cambiar banner
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                  onPressed: _isUploadingBanner ? null : _pickBannerImage,
                                ),
                              ),
                            ),
                            // Loader banner
                            if (_isUploadingBanner)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black45,
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16), // Separación entre banner y avatar

                    // Avatar editable
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppTheme.primaryBlue,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (context.read<AuthProvider>().currentUser?.profileImageUrl != null
                                  ? NetworkImage(context.read<AuthProvider>().currentUser!.profileImageUrl!)
                                  : null) as ImageProvider?,
                          child: (_selectedImage == null &&
                                  context.read<AuthProvider>().currentUser?.profileImageUrl == null)
                              ? const Icon(Icons.person, size: 60, color: Colors.white)
                              : null,
                        ),
                        // Loader avatar
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.black54,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        // Botón para cambiar avatar
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue,
                            radius: 20,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 20),
                              onPressed: _isUploadingImage ? null : _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: 32),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  return null;
                },
              ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.2),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.2),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.2),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ).animate(delay: 400.ms).fadeIn().slideX(begin: -0.2),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ).animate(delay: 500.ms).fadeIn().slideX(begin: -0.2),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _hasChanges && !_isLoading ? _saveChanges : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Changes',
                        style: TextStyle(fontSize: 16)),
              )
                  .animate(delay: 600.ms)
                  .fadeIn()
                  .scale(begin: const Offset(0.9, 0.9)),
            ],
          ),
        ),
      ),
    );
  }
}
