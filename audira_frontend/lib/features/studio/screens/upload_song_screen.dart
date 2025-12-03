// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/api/services/file_service.dart';
import '../../../core/models/genre.dart';

class UploadSongScreen extends StatefulWidget {
  const UploadSongScreen({super.key});

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _priceController = TextEditingController(text: '9.99');
  final _durationController = TextEditingController();
  final _categoryController = TextEditingController();
  final _collaboratorNameController = TextEditingController();
  final _collaboratorRoleController = TextEditingController();

  // Services
  final MusicService _musicService = MusicService();
  final FileService _fileService = FileService();

  // State
  bool _showPreview = false;
  bool _isUploading = false;
  bool _isLoadingGenres = true;
  double _uploadProgress = 0.0;

  // Files
  String? _audioFileName;
  String? _audioFilePath;
  String? _imageFilePath;
  int? _audioFileSizeBytes;
  String? _audioFileExtension;

  // Data
  List<Genre> _availableGenres = [];
  final List<int> _selectedGenreIds = [];
  final List<Map<String, String>> _collaborators = [];

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _lyricsController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _categoryController.dispose();
    _collaboratorNameController.dispose();
    _collaboratorRoleController.dispose();
    super.dispose();
  }

  // --- Lógica del Negocio (Mantenida Intacta) ---

  Future<void> _loadGenres() async {
    setState(() => _isLoadingGenres = true);
    try {
      final response = await _musicService.getAllGenres();
      if (response.success && response.data != null) {
        setState(() {
          _availableGenres = response.data!;
          _isLoadingGenres = false;
        });
      } else {
        setState(() => _isLoadingGenres = false);
        if (mounted) {
          _showSnack('Error al cargar géneros: ${response.error}',
              isError: true);
        }
      }
    } catch (e) {
      setState(() => _isLoadingGenres = false);
      if (mounted) _showSnack('Error al cargar géneros: $e', isError: true);
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final extension = file.extension?.toLowerCase();

        if (extension == null ||
            !['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'].contains(extension)) {
          _showSnack('Formato no válido. Use MP3, WAV, FLAC, AAC, M4A u OGG',
              isError: true);
          return;
        }

        if (file.size > 100 * 1024 * 1024) {
          _showSnack('Archivo demasiado grande (Máx 100MB)', isError: true);
          return;
        }

        if (file.path == null) {
          _showSnack('No se pudo obtener la ruta del archivo', isError: true);
          return;
        }

        try {
          final player = AudioPlayer();
          final duration = await player.setFilePath(file.path!);
          _durationController.text =
              duration != null ? duration.inSeconds.toString() : '180';
          await player.dispose();
        } catch (e) {
          debugPrint('Error duration: $e');
          _durationController.text = '180';
        }

        setState(() {
          _audioFileName = file.name;
          _audioFilePath = file.path;
          _audioFileSizeBytes = file.size;
          _audioFileExtension = extension;

          if (_nameController.text.isEmpty) {
            _nameController.text = file.name.replaceAll(RegExp(r'\.\w+$'), '');
          }
        });

        _showSnack(
            'Audio seleccionado: ${file.name} (${_formatFileSize(file.size)})');
      }
    } catch (e) {
      _showSnack('Error al seleccionar audio: $e', isError: true);
    }
  }

  Future<void> _pickImageFile() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFilePath = image.path;
        });
        _showSnack('Imagen seleccionada: ${image.name}');
      }
    } catch (e) {
      _showSnack('Error al seleccionar imagen: $e', isError: true);
    }
  }

  Future<void> _uploadSong() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audioFileName == null || _audioFilePath == null) {
      _showSnack('Por favor selecciona un archivo de audio', isError: true);
      return;
    }
    if (_selectedGenreIds.isEmpty) {
      _showSnack('Por favor selecciona al menos un género', isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Paso 1: Subir Audio (0% - 30%)
      setState(() => _uploadProgress = 0.1);
      final audioUploadResponse = await _fileService.uploadAudioFile(
        _audioFilePath!,
        onProgress: (sent, total) {
          if (total > 0) {
            setState(() {
              _uploadProgress = 0.1 + (sent / total) * 0.3;
            });
          }
        },
      );

      if (!audioUploadResponse.success) {
        throw Exception('Error al subir audio: ${audioUploadResponse.error}');
      }
      final audioUrl = audioUploadResponse.data!.fileUrl;

      // Paso 2: Subir Imagen (40% - 60%)
      setState(() => _uploadProgress = 0.4);
      String? coverImageUrl;
      if (_imageFilePath != null) {
        final imageUploadResponse = await _fileService.uploadImageFile(
          _imageFilePath!,
          onProgress: (sent, total) {
            if (total > 0) {
              setState(() {
                _uploadProgress = 0.4 + (sent / total) * 0.2;
              });
            }
          },
        );
        if (!imageUploadResponse.success) {
          throw Exception(
              'Error al subir imagen: ${imageUploadResponse.error}');
        }
        coverImageUrl = imageUploadResponse.data!.fileUrl;
      }

      // Paso 3: IDs y Datos (60% - 70%)
      setState(() => _uploadProgress = 0.6);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final artistId = authProvider.currentUser?.id;
      if (artistId == null) {
        throw Exception('No se pudo obtener el ID del artista');
      }

      setState(() => _uploadProgress = 0.7);
      final songData = {
        'title': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'artistId': artistId,
        'price': double.parse(_priceController.text),
        'duration': int.parse(_durationController.text),
        'audioUrl': audioUrl,
        'coverImageUrl': coverImageUrl,
        'lyrics': _lyricsController.text.trim().isEmpty
            ? null
            : _lyricsController.text.trim(),
        'category': _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        'genreIds': _selectedGenreIds,
        'plays': 0,
        'productType': 'SONG',
        'collaborators': _collaborators,
      };

      // Paso 4: Crear Canción en Backend (80% - 100%)
      setState(() => _uploadProgress = 0.8);
      final createSongResponse = await _musicService.createSong(songData);

      if (!createSongResponse.success) {
        throw Exception('Error al crear canción: ${createSongResponse.error}');
      }

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        _showSnack('¡Canción subida exitosamente! Pendiente de revisión.',
            isError: false);
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted && !_isUploading) {
        // Asegurar que el estado de carga se limpie si no se hizo antes
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // --- UI (Remodelada con diseño Dark) ---

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'SUBIR CANCIÓN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showPreview
                ? Icons.edit_note_rounded
                : Icons.visibility_rounded),
            tooltip: _showPreview ? 'Editar' : 'Vista Previa',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() => _showPreview = !_showPreview);
              } else {
                _showSnack('Completa los campos obligatorios', isError: true);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _showPreview ? _buildPreview() : _buildForm(),
            ),
            // Contenedor de subida SIN animación de entrada para evitar reinicios
            if (_isUploading)
              Container(
                color: AppTheme.surfaceBlack,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subiendo...',
                            style: TextStyle(color: Colors.white)),
                        Text('${(_uploadProgress * 100).toInt()}%',
                            style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.white10,
                      color: AppTheme.primaryBlue,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Selector de Audio (Destacado)
            GestureDetector(
              onTap: _pickAudioFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _audioFileName != null
                      ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                      : AppTheme.cardBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _audioFileName != null
                          ? AppTheme.primaryBlue
                          : Colors.white10,
                      width: 1.5,
                      style: _audioFileName != null
                          ? BorderStyle.solid
                          : BorderStyle.none),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _audioFileName != null
                            ? AppTheme.primaryBlue
                            : AppTheme.surfaceBlack,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _audioFileName != null
                            ? Icons.check
                            : Icons.audio_file_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _audioFileName ?? 'Seleccionar Archivo de Audio *',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: _audioFileName != null ? 14 : 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _audioFileName != null &&
                                    _audioFileSizeBytes != null
                                ? '${_audioFileExtension?.toUpperCase()} • ${_formatFileSize(_audioFileSizeBytes!)}'
                                : 'MP3, WAV, FLAC, M4A (Máx 100MB)',
                            style: const TextStyle(
                                color: AppTheme.textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (_audioFileName == null)
                      const Icon(Icons.upload_rounded,
                          color: AppTheme.textGrey),
                  ],
                ),
              ),
            ).animate().fadeIn().scale(),

            const SizedBox(height: 24),

            // 2. Imagen y Datos Principales
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen Portada
                GestureDetector(
                  onTap: _pickImageFile,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBlack,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                      image: _imageFilePath != null
                          ? DecorationImage(
                              image: FileImage(File(_imageFilePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageFilePath == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: AppTheme.textGrey),
                              SizedBox(height: 4),
                              Text('Portada',
                                  style: TextStyle(
                                      fontSize: 10, color: AppTheme.textGrey)),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.edit, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Inputs Título y Categoría
                Expanded(
                  child: Column(
                    children: [
                      _buildDarkInput(
                        controller: _nameController,
                        label: 'Título',
                        hint: 'Nombre de la canción',
                        icon: Icons.title,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildDarkInput(
                        controller: _categoryController,
                        label: 'Categoría',
                        hint: 'Ej: Single, Remix',
                        icon: Icons.tag,
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),

            // 3. Descripción
            _buildSectionLabel('DETALLES'),
            _buildDarkInput(
              controller: _descriptionController,
              label: 'Descripción',
              hint: 'Historia, mood, inspiración...',
              icon: Icons.description_outlined,
              maxLines: 3,
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 16),

            // 4. Precio y Duración
            Row(
              children: [
                Expanded(
                  child: _buildDarkInput(
                    controller: _priceController,
                    label: 'Precio',
                    icon: Icons.attach_money,
                    inputType: TextInputType.number,
                    validator: (v) => (v!.isEmpty || double.tryParse(v) == null)
                        ? 'Inválido'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDarkInput(
                    controller: _durationController,
                    label: 'Duración (s)',
                    icon: Icons.timer_outlined,
                    inputType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // 5. Géneros
            _buildSectionLabel('GÉNEROS'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBlack,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: _isLoadingGenres
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : _availableGenres.isEmpty
                      ? const Text('No hay géneros disponibles',
                          style: TextStyle(color: AppTheme.textGrey))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableGenres.map((genre) {
                            final isSelected =
                                _selectedGenreIds.contains(genre.id);
                            return FilterChip(
                              label: Text(genre.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  selected
                                      ? _selectedGenreIds.add(genre.id)
                                      : _selectedGenreIds.remove(genre.id);
                                });
                              },
                              backgroundColor: AppTheme.surfaceBlack,
                              selectedColor:
                                  AppTheme.primaryBlue.withValues(alpha: 0.2),
                              checkmarkColor: AppTheme.primaryBlue,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textGrey,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                    color: isSelected
                                        ? AppTheme.primaryBlue
                                        : Colors.white10),
                              ),
                              padding: EdgeInsets.zero,
                            );
                          }).toList(),
                        ),
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 24),

            // 6. Letra
            _buildSectionLabel('LETRA (OPCIONAL)'),
            _buildDarkInput(
              controller: _lyricsController,
              label: 'Letra de la canción',
              hint: 'Pega la letra aquí...',
              icon: Icons.lyrics_outlined,
              maxLines: 5,
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 24),

            // 7. Info Moderación
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.primaryBlue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tu canción será revisada por un administrador antes de estar disponible públicamente.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms),

            const SizedBox(height: 32),

            // 8. Botón Submit
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadSong,
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text('PUBLICAR CANCIÓN',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).scale(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color: AppTheme.cardBlack,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10)),
              ],
              image: _imageFilePath != null
                  ? DecorationImage(
                      image: FileImage(File(_imageFilePath!)),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: _imageFilePath == null
                ? const Icon(Icons.music_note_rounded,
                    size: 80, color: AppTheme.textGrey)
                : null,
          ).animate().scale(),
          const SizedBox(height: 32),
          Text(
            _nameController.text.isEmpty ? 'Sin Título' : _nameController.text,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _descriptionController.text.isEmpty
                ? 'Sin descripción'
                : _descriptionController.text,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBlack,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildPreviewRow('Archivo', _audioFileName ?? 'N/A'),
                const Divider(color: Colors.white10),
                _buildPreviewRow('Duración', '${_durationController.text} seg'),
                const Divider(color: Colors.white10),
                _buildPreviewRow('Precio', '\$${_priceController.text}'),
                const Divider(color: Colors.white10),
                _buildPreviewRow(
                    'Géneros', _selectedGenreIds.length.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textGrey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDarkInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: inputType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        labelStyle: const TextStyle(color: AppTheme.textGrey),
        prefixIcon: Icon(icon, color: AppTheme.textGrey, size: 20),
        filled: true,
        fillColor: AppTheme.cardBlack,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryBlue)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.errorRed)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textGrey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
