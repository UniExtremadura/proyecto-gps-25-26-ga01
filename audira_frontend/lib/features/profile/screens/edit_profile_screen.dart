import 'dart:io';
import 'dart:async';
import 'package:audira_frontend/core/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/auth_service.dart';
import '../../../config/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/social_media_validator.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Controladores (Lógica Original) ---
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  late TextEditingController _artistNameController;
  late TextEditingController _artistBioController;
  late TextEditingController _recordLabelController;
  late TextEditingController _twitterController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;
  late TextEditingController _youtubeController;
  late TextEditingController _spotifyController;
  late TextEditingController _tiktokController;

  bool _isLoading = false;
  bool _hasChanges = false;
  File? _selectedImage;
  bool _isUploadingImage = false;
  File? _selectedBanner;
  bool _isUploadingBanner = false;
  final ImagePicker _picker = ImagePicker();

  // --- Estados de validación (Lógica Original) ---
  SocialMediaValidationState _twitterValidation =
      SocialMediaValidationState.initial();
  SocialMediaValidationState _instagramValidation =
      SocialMediaValidationState.initial();
  SocialMediaValidationState _facebookValidation =
      SocialMediaValidationState.initial();
  SocialMediaValidationState _youtubeValidation =
      SocialMediaValidationState.initial();
  SocialMediaValidationState _spotifyValidation =
      SocialMediaValidationState.initial();
  SocialMediaValidationState _tiktokValidation =
      SocialMediaValidationState.initial();

  // --- Timers (Lógica Original) ---
  Timer? _twitterDebounce;
  Timer? _instagramDebounce;
  Timer? _facebookDebounce;
  Timer? _youtubeDebounce;
  Timer? _spotifyDebounce;
  Timer? _tiktokDebounce;

  // --- Colores del Nuevo Diseño ---
  final Color darkBg = Colors.black;
  final Color inputFill = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;

    // Inicialización idéntica a tu código
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _locationController = TextEditingController(text: user?.location ?? '');
    _websiteController = TextEditingController(text: user?.website ?? '');
    _artistNameController = TextEditingController(text: user?.artistName ?? '');
    _artistBioController = TextEditingController(text: user?.artistBio ?? '');
    _recordLabelController =
        TextEditingController(text: user?.recordLabel ?? '');
    _twitterController = TextEditingController(text: user?.twitterUrl ?? '');
    _instagramController =
        TextEditingController(text: user?.instagramUrl ?? '');
    _facebookController = TextEditingController(text: user?.facebookUrl ?? '');
    _youtubeController = TextEditingController(text: user?.youtubeUrl ?? '');
    _spotifyController = TextEditingController(text: user?.spotifyUrl ?? '');
    _tiktokController = TextEditingController(text: user?.tiktokUrl ?? '');

    // Listeners originales
    _firstNameController.addListener(() => setState(() => _hasChanges = true));
    _lastNameController.addListener(() => setState(() => _hasChanges = true));
    _bioController.addListener(() => setState(() => _hasChanges = true));
    _locationController.addListener(() => setState(() => _hasChanges = true));
    _websiteController.addListener(() => setState(() => _hasChanges = true));
    _artistNameController.addListener(() => setState(() => _hasChanges = true));
    _artistBioController.addListener(() => setState(() => _hasChanges = true));
    _recordLabelController
        .addListener(() => setState(() => _hasChanges = true));
    _twitterController.addListener(() => setState(() => _hasChanges = true));
    _instagramController.addListener(() => setState(() => _hasChanges = true));
    _facebookController.addListener(() => setState(() => _hasChanges = true));
    _youtubeController.addListener(() => setState(() => _hasChanges = true));
    _spotifyController.addListener(() => setState(() => _hasChanges = true));
    _tiktokController.addListener(() => setState(() => _hasChanges = true));

    // Validaciones al cargar (Lógica Original)
    if (user?.twitterUrl != null && user!.twitterUrl!.isNotEmpty) {
      _validateTwitter(user.twitterUrl!);
    }
    if (user?.instagramUrl != null && user!.instagramUrl!.isNotEmpty) {
      _validateInstagram(user.instagramUrl!);
    }
    if (user?.facebookUrl != null && user!.facebookUrl!.isNotEmpty) {
      _validateFacebook(user.facebookUrl!);
    }
    if (user?.youtubeUrl != null && user!.youtubeUrl!.isNotEmpty) {
      _validateYoutube(user.youtubeUrl!);
    }
    if (user?.spotifyUrl != null && user!.spotifyUrl!.isNotEmpty) {
      _validateSpotify(user.spotifyUrl!);
    }
    if (user?.tiktokUrl != null && user!.tiktokUrl!.isNotEmpty) {
      _validateTiktok(user.tiktokUrl!);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _artistNameController.dispose();
    _artistBioController.dispose();
    _recordLabelController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _youtubeController.dispose();
    _spotifyController.dispose();
    _tiktokController.dispose();
    _twitterDebounce?.cancel();
    _instagramDebounce?.cancel();
    _facebookDebounce?.cancel();
    _youtubeDebounce?.cancel();
    _spotifyDebounce?.cancel();
    _tiktokDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(EditProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _updateControllersFromUser(user);
    }
  }

  // --- Lógica Original Intacta ---

  void _updateControllersFromUser(User user) {
    _firstNameController.text = user.firstName ?? '';
    _lastNameController.text = user.lastName ?? '';
    _bioController.text = user.bio ?? '';
    _locationController.text = user.location ?? '';
    _websiteController.text = user.website ?? '';
    _artistNameController.text = user.artistName ?? '';
    _artistBioController.text = user.artistBio ?? '';
    _recordLabelController.text = user.recordLabel ?? '';
    _twitterController.text = user.twitterUrl ?? '';
    _instagramController.text = user.instagramUrl ?? '';
    _facebookController.text = user.facebookUrl ?? '';
    _youtubeController.text = user.youtubeUrl ?? '';
    _spotifyController.text = user.spotifyUrl ?? '';
    _tiktokController.text = user.tiktokUrl ?? '';

    if (user.twitterUrl != null && user.twitterUrl!.isNotEmpty) {
      _validateTwitter(user.twitterUrl!);
    }
    if (user.instagramUrl != null && user.instagramUrl!.isNotEmpty) {
      _validateInstagram(user.instagramUrl!);
    }
    if (user.facebookUrl != null && user.facebookUrl!.isNotEmpty) {
      _validateFacebook(user.facebookUrl!);
    }
    if (user.youtubeUrl != null && user.youtubeUrl!.isNotEmpty) {
      _validateYoutube(user.youtubeUrl!);
    }
    if (user.spotifyUrl != null && user.spotifyUrl!.isNotEmpty) {
      _validateSpotify(user.spotifyUrl!);
    }
    if (user.tiktokUrl != null && user.tiktokUrl!.isNotEmpty) {
      _validateTiktok(user.tiktokUrl!);
    }
  }

  void _validateTwitter(String url) {
    setState(() {
      if (url.isEmpty) {
        _twitterValidation = SocialMediaValidationState.empty();
      } else if (SocialMediaValidator.isValidTwitterUrl(url)) {
        final username = SocialMediaValidator.extractTwitterUsername(url);
        if (username != null) {
          _twitterValidation = SocialMediaValidationState.valid(username);
        } else {
          _twitterValidation = SocialMediaValidationState.invalid(
              'No se pudo extraer el nombre de usuario');
        }
      } else {
        _twitterValidation = SocialMediaValidationState.invalid(
            'URL de Twitter/X no válida. Formato: https://twitter.com/usuario');
      }
    });
  }

  void _validateInstagram(String url) {
    setState(() {
      if (url.isEmpty) {
        _instagramValidation = SocialMediaValidationState.empty();
      } else if (SocialMediaValidator.isValidInstagramUrl(url)) {
        final username = SocialMediaValidator.extractInstagramUsername(url);
        if (username != null) {
          _instagramValidation = SocialMediaValidationState.valid(username);
        } else {
          _instagramValidation = SocialMediaValidationState.invalid(
              'No se pudo extraer el nombre de usuario');
        }
      } else {
        _instagramValidation = SocialMediaValidationState.invalid(
            'URL de Instagram no válida. Formato: https://instagram.com/usuario');
      }
    });
  }

  void _validateFacebook(String url) {
    setState(() {
      if (url.isEmpty) {
        _facebookValidation = SocialMediaValidationState.empty();
      } else if (SocialMediaValidator.isValidFacebookUrl(url)) {
        final username = SocialMediaValidator.extractFacebookUsername(url);
        if (username != null) {
          _facebookValidation = SocialMediaValidationState.valid(username);
        } else {
          _facebookValidation = SocialMediaValidationState.invalid(
              'No se pudo extraer el nombre de usuario');
        }
      } else {
        _facebookValidation = SocialMediaValidationState.invalid(
            'URL de Facebook no válida. Formato: https://facebook.com/usuario');
      }
    });
  }

  void _validateYoutube(String url) {
    setState(() {
      if (url.isEmpty) {
        _youtubeValidation = SocialMediaValidationState.empty();
      } else if (SocialMediaValidator.isValidYoutubeUrl(url)) {
        final username = SocialMediaValidator.extractYoutubeId(url);
        if (username != null) {
          _youtubeValidation = SocialMediaValidationState.valid(username);
        } else {
          _youtubeValidation = SocialMediaValidationState.invalid(
              'No se pudo extraer el identificador');
        }
      } else {
        _youtubeValidation = SocialMediaValidationState.invalid(
            'URL de YouTube no válida. Formato: https://youtube.com/@canal');
      }
    });
  }

  void _validateSpotify(String url) {
    setState(() {
      if (url.isEmpty) {
        _spotifyValidation = SocialMediaValidationState.empty();
      } else if (SocialMediaValidator.isValidSpotifyUrl(url)) {
        final artistId = SocialMediaValidator.extractSpotifyArtistId(url);
        if (artistId != null) {
          _spotifyValidation = SocialMediaValidationState.valid(artistId);
        } else {
          _spotifyValidation = SocialMediaValidationState.invalid(
              'No se pudo extraer el ID del artista');
        }
      } else {
        _spotifyValidation = SocialMediaValidationState.invalid(
            'URL de Spotify no válida. Formato: https://open.spotify.com/artist/ID');
      }
    });
  }

  void _validateTiktok(String url) {
    setState(() {
      if (url.isEmpty) {
        _tiktokValidation = SocialMediaValidationState.empty();
      } else if (SocialMediaValidator.isValidTiktokUrl(url)) {
        final username = SocialMediaValidator.extractTiktokUsername(url);
        if (username != null) {
          _tiktokValidation = SocialMediaValidationState.valid(username);
        } else {
          _tiktokValidation = SocialMediaValidationState.invalid(
              'No se pudo extraer el nombre de usuario');
        }
      } else {
        _tiktokValidation = SocialMediaValidationState.invalid(
            'URL de TikTok no válida. Formato: https://tiktok.com/@usuario');
      }
    });
  }

  void _onTwitterChanged(String value) {
    _twitterDebounce?.cancel();
    _twitterDebounce = Timer(const Duration(milliseconds: 500), () {
      _validateTwitter(value);
    });
  }

  void _onInstagramChanged(String value) {
    _instagramDebounce?.cancel();
    _instagramDebounce = Timer(const Duration(milliseconds: 500), () {
      _validateInstagram(value);
    });
  }

  void _onFacebookChanged(String value) {
    _facebookDebounce?.cancel();
    _facebookDebounce = Timer(const Duration(milliseconds: 500), () {
      _validateFacebook(value);
    });
  }

  void _onYoutubeChanged(String value) {
    _youtubeDebounce?.cancel();
    _youtubeDebounce = Timer(const Duration(milliseconds: 500), () {
      _validateYoutube(value);
    });
  }

  void _onSpotifyChanged(String value) {
    _spotifyDebounce?.cancel();
    _spotifyDebounce = Timer(const Duration(milliseconds: 500), () {
      _validateSpotify(value);
    });
  }

  void _onTiktokChanged(String value) {
    _tiktokDebounce?.cancel();
    _tiktokDebounce = Timer(const Duration(milliseconds: 500), () {
      _validateTiktok(value);
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_twitterValidation.isValid &&
        _twitterController.text.trim().isNotEmpty) {
      _showSnack('Por favor, corrige la URL de Twitter antes de guardar',
          isError: true);
      return;
    }
    if (!_instagramValidation.isValid &&
        _instagramController.text.trim().isNotEmpty) {
      _showSnack('Por favor, corrige la URL de Instagram antes de guardar',
          isError: true);
      return;
    }
    if (!_facebookValidation.isValid &&
        _facebookController.text.trim().isNotEmpty) {
      _showSnack('Por favor, corrige la URL de Facebook antes de guardar',
          isError: true);
      return;
    }
    if (!_youtubeValidation.isValid &&
        _youtubeController.text.trim().isNotEmpty) {
      _showSnack('Por favor, corrige la URL de YouTube antes de guardar',
          isError: true);
      return;
    }
    if (!_spotifyValidation.isValid &&
        _spotifyController.text.trim().isNotEmpty) {
      _showSnack('Por favor, corrige la URL de Spotify antes de guardar',
          isError: true);
      return;
    }
    if (!_tiktokValidation.isValid &&
        _tiktokController.text.trim().isNotEmpty) {
      _showSnack('Por favor, corrige la URL de TikTok antes de guardar',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final user = context.read<AuthProvider>().currentUser;
      final updates = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
      };

      if (user?.isArtist == true) {
        updates['artistName'] = _artistNameController.text.trim();
        updates['artistBio'] = _artistBioController.text.trim();
        updates['recordLabel'] = _recordLabelController.text.trim();
      }

      final twitterUrl = _twitterController.text.trim();
      final instagramUrl = _instagramController.text.trim();
      final facebookUrl = _facebookController.text.trim();
      final youtubeUrl = _youtubeController.text.trim();
      final spotifyUrl = _spotifyController.text.trim();
      final tiktokUrl = _tiktokController.text.trim();

      if (twitterUrl.isNotEmpty) updates['twitterUrl'] = twitterUrl;
      if (instagramUrl.isNotEmpty) updates['instagramUrl'] = instagramUrl;
      if (facebookUrl.isNotEmpty) updates['facebookUrl'] = facebookUrl;
      if (youtubeUrl.isNotEmpty) updates['youtubeUrl'] = youtubeUrl;
      if (spotifyUrl.isNotEmpty) updates['spotifyUrl'] = spotifyUrl;
      if (tiktokUrl.isNotEmpty) updates['tiktokUrl'] = tiktokUrl;

      final ApiResponse<User> response =
          await authService.updateProfile(updates);

      if (response.success && response.data != null) {
        final updatedUser = response.data!;
        if (mounted) {
          final authProvider = context.read<AuthProvider>();
          authProvider.updateUser(updatedUser);
          _updateControllersFromUser(updatedUser);
          _showSnack('Perfil actualizado exitosamente', isSuccess: true);
          setState(() => _hasChanges = false);
        }
      } else {
        throw Exception(response.error ?? 'Error al actualizar perfil');
      }
    } catch (e) {
      if (mounted) _showSnack('Error al actualizar perfil: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      if (mounted) _showSnack('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    setState(() => _isUploadingImage = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;
      if (userId == null) throw Exception('Usuario no identificado');

      final authService = AuthService();
      final response =
          await authService.uploadProfileImage(_selectedImage!, userId);

      if (response.success) {
        await authProvider.refreshProfile();
        if (mounted) {
          _showSnack('Foto de perfil actualizada exitosamente',
              isSuccess: true);
        }
      } else {
        throw Exception(response.error ?? 'Error al subir imagen');
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _pickBanner() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedBanner = File(pickedFile.path);
        });
        await _uploadBanner();
      }
    } catch (e) {
      if (mounted) _showSnack('Error al seleccionar banner: $e');
    }
  }

  Future<void> _uploadBanner() async {
    if (_selectedBanner == null) return;
    setState(() => _isUploadingBanner = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;
      if (userId == null) throw Exception('Usuario no identificado');

      final authService = AuthService();
      final response =
          await authService.uploadBannerImage(_selectedBanner!, userId);

      if (response.success) {
        await authProvider.refreshProfile();
        if (mounted) {
          _showSnack('Banner actualizado exitosamente', isSuccess: true);
        }
      } else {
        throw Exception(response.error ?? 'Error al subir banner');
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isUploadingBanner = false);
    }
  }

  void _showSnack(String msg, {bool isError = false, bool isSuccess = false}) {
    Color color = Colors.grey;
    if (isError) color = Colors.red[900]!;
    if (isSuccess) color = Colors.green[800]!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // --- UI BUILD REFACTORIZADA CON MANTENIMIENTO DE LÓGICA ---

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isArtist = user?.isArtist == true;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text('Editar Perfil',
            style: TextStyle(
                color: AppTheme.primaryBlue, fontWeight: FontWeight.w800)),
        backgroundColor: darkBg,
        elevation: 0,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primaryBlue))
                  : const Text('Guardar',
                      style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header (Banner & Avatar) - Reestilizado
              _buildHeader(user),

              const SizedBox(height: 60), // Espacio para el avatar superpuesto

              // 2. Info Principal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      user?.displayName ?? 'Usuario',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                              color: lightText, fontWeight: FontWeight.bold),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 4),
                    Text(
                      '@${user?.username ?? 'nombre_usuario'}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: subText),
                    ).animate().fadeIn(delay: 350.ms),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isUploadingImage ? null : _pickImage,
                      icon: const Icon(Icons.photo_camera, size: 18),
                      label: const Text('Cambiar Imagen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 3. Formularios
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Información Personal'),
                    _buildDarkTextField(
                      controller: _firstNameController,
                      label: 'Nombre',
                      icon: Icons.person_outline,
                    ),
                    _buildDarkTextField(
                      controller: _lastNameController,
                      label: 'Apellido',
                      icon: Icons.person,
                    ),
                    _buildDarkTextField(
                      controller: _bioController,
                      label: 'Biografía',
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    _buildDarkTextField(
                      controller: _locationController,
                      label: 'Ubicación',
                      icon: Icons.location_on,
                    ),
                    _buildDarkTextField(
                      controller: _websiteController,
                      label: 'Sitio Web',
                      icon: Icons.link,
                      keyboardType: TextInputType.url,
                    ),
                    if (isArtist) ...[
                      const SizedBox(height: 30),
                      _buildSectionTitle('Información de Artista',
                          icon: Icons.star_border),
                      _buildDarkTextField(
                        controller: _artistNameController,
                        label: 'Nombre de Artista',
                        icon: Icons.stars,
                        hint: 'Tu nombre artístico profesional',
                      ),
                      _buildDarkTextField(
                        controller: _artistBioController,
                        label: 'Biografía de Artista',
                        icon: Icons.music_note,
                        maxLines: 4,
                        hint: 'Háblales a tus fans sobre tu música',
                      ),
                      _buildDarkTextField(
                        controller: _recordLabelController,
                        label: 'Sello Discográfico',
                        icon: Icons.album,
                        hint: 'Independiente o nombre del sello',
                      ),
                    ],
                    const SizedBox(height: 30),
                    _buildSectionTitle('Redes Sociales', icon: Icons.share),
                    _buildSocialField(
                      controller: _twitterController,
                      label: 'Twitter / X',
                      icon: Icons.alternate_email,
                      hint: 'https://twitter.com/nombre_usuario',
                      validationState: _twitterValidation,
                      onChanged: _onTwitterChanged,
                    ),
                    _buildSocialField(
                      controller: _instagramController,
                      label: 'Instagram',
                      icon: Icons.camera_alt,
                      hint: 'https://instagram.com/nombre_usuario',
                      validationState: _instagramValidation,
                      onChanged: _onInstagramChanged,
                    ),
                    _buildSocialField(
                      controller: _facebookController,
                      label: 'Facebook',
                      icon: Icons.facebook,
                      hint: 'https://facebook.com/nombre_usuario',
                      validationState: _facebookValidation,
                      onChanged: _onFacebookChanged,
                    ),
                    _buildSocialField(
                      controller: _youtubeController,
                      label: 'YouTube',
                      icon: Icons.play_circle_outline,
                      hint: 'https://youtube.com/c/canal',
                      validationState: _youtubeValidation,
                      onChanged: _onYoutubeChanged,
                    ),
                    _buildSocialField(
                      controller: _spotifyController,
                      label: 'Spotify',
                      icon: Icons.music_note_outlined,
                      hint: 'http://googleusercontent.com/spotify.com/...',
                      validationState: _spotifyValidation,
                      onChanged: _onSpotifyChanged,
                    ),
                    _buildSocialField(
                      controller: _tiktokController,
                      label: 'TikTok',
                      icon: Icons.video_library_outlined,
                      hint: 'https://tiktok.com/@nombre_usuario',
                      validationState: _tiktokValidation,
                      onChanged: _onTiktokChanged,
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE COMPOSICIÓN (Nuevo Estilo) ---

  Widget _buildHeader(User? user) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Banner Area
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            gradient: (_selectedBanner == null && user?.bannerImageUrl == null)
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.8),
                      AppTheme.primaryBlue.withValues(alpha: 0.4)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            image: _selectedBanner != null
                ? DecorationImage(
                    image: FileImage(_selectedBanner!), fit: BoxFit.cover)
                : (user?.bannerImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(user!.bannerImageUrl!),
                        fit: BoxFit.cover)
                    : null),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7)
                ],
              ),
            ),
          ),
        ),

        // Upload Banner Button
        Positioned(
          top: 16,
          right: 16,
          child: ElevatedButton.icon(
            onPressed: _isUploadingBanner ? null : _pickBanner,
            icon: const Icon(Icons.photo_camera, size: 18),
            label: const Text('Editar Banner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),

        // Loader Banner
        if (_isUploadingBanner)
          Positioned.fill(
              child: Container(
                  color: Colors.black54,
                  child: const Center(
                      child: CircularProgressIndicator(color: Colors.white)))),

        // Avatar
        Positioned(
          bottom: -50,
          left: 20,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: darkBg, width: 5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: inputFill,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (user?.profileImageUrl != null
                          ? NetworkImage(user!.profileImageUrl!)
                              as ImageProvider
                          : null),
                  child: (_selectedImage == null &&
                          user?.profileImageUrl == null)
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
                if (_isUploadingImage)
                  const Positioned.fill(
                      child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.black54,
                          child:
                              CircularProgressIndicator(color: Colors.white))),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.primaryBlue, size: 20),
            const SizedBox(width: 8)
          ],
          Text(title,
              style: TextStyle(
                  color: lightText, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDarkTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: lightText),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: subText),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[700]),
          prefixIcon: Icon(icon, color: subText),
          filled: true,
          fillColor: inputFill, // Fondo oscuro sólido
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryBlue)),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: (value) => null, // Validación básica manejada en submit
      ),
    );
  }

  Widget _buildSocialField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required SocialMediaValidationState validationState,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            style: TextStyle(color: lightText),
            keyboardType: TextInputType.url,
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: subText),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[700]),
              prefixIcon: Icon(icon,
                  color: controller.text.isNotEmpty
                      ? AppTheme.primaryBlue
                      : subText),
              suffixIcon: validationState.isValid
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : (controller.text.isNotEmpty
                      ? const Icon(Icons.error, color: Colors.red)
                      : null),
              filled: true,
              fillColor: inputFill,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue)),
            ),
          ),
          // Feedback de validación
          if (controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: validationState.isValid
                  ? Text('Validado: @${validationState.username}',
                      style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold))
                  : Text(validationState.errorMessage ?? 'URL inválida',
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
