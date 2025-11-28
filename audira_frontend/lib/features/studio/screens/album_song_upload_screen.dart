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
import '../../../core/models/genre.dart';

class AlbumSongUploadScreen extends StatefulWidget {
  final List<PlatformFile> audioFiles;
  final int currentIndex;
  final List<Map<String, dynamic>> completedSongs;

  const AlbumSongUploadScreen({
    super.key,
    required this.audioFiles,
    this.currentIndex = 0,
    this.completedSongs = const [],
  });

  @override
  State<AlbumSongUploadScreen> createState() => _AlbumSongUploadScreenState();
}

class _AlbumSongUploadScreenState extends State<AlbumSongUploadScreen> {
  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _priceController = TextEditingController(text: '9.99');
  final _durationController = TextEditingController();
  final _categoryController = TextEditingController();

  final MusicService _musicService = MusicService();

  // State
  bool _showPreview = false;
  bool _isLoadingGenres = true;
  String? _imageFilePath;
  List<Genre> _availableGenres = [];
  final List<int> _selectedGenreIds = [];

  // Data
  late List<Map<String, dynamic>> _completedSongsData;
  late int _currentFileIndex;

  // Collaborators (Mantenido aunque no visible en el código original, por si acaso)
  final List<Map<String, String>> _collaborators = [];
  final _collaboratorNameController = TextEditingController();
  final _collaboratorRoleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _completedSongsData = List.from(widget.completedSongs);
    _currentFileIndex = widget.currentIndex;
    _loadGenres();
    _initializeCurrentSong();
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
    _scrollController.dispose();
    super.dispose();
  }

  // --- Lógica de Negocio (Intacta) ---

  void _initializeCurrentSong() {
    final currentFile = widget.audioFiles[_currentFileIndex];
    _nameController.text = currentFile.name.replaceAll(RegExp(r'\.\w+$'), '');
    _extractAudioDuration(currentFile.path!);
  }

  Future<void> _extractAudioDuration(String path) async {
    try {
      final player = AudioPlayer();
      final duration = await player.setFilePath(path);
      if (duration != null) {
        _durationController.text = duration.inSeconds.toString();
      } else {
        _durationController.text = '180';
      }
      await player.dispose();
    } catch (e) {
      debugPrint('Error al extraer duración: $e');
      _durationController.text = '180';
    }
  }

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
        _showSnack('Error al cargar géneros: ${response.error}', isError: true);
      }
    } catch (e) {
      setState(() => _isLoadingGenres = false);
      _showSnack('Error al cargar géneros: $e', isError: true);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
      }
    } catch (e) {
      _showSnack('Error al seleccionar imagen: $e', isError: true);
    }
  }

  void _resetFormForNextSong() {
    _nameController.clear();
    _descriptionController.clear();
    _lyricsController.clear();
    _categoryController.clear();
    _collaboratorNameController.clear();
    _collaboratorRoleController.clear();

    setState(() {
      _imageFilePath = null;
      _selectedGenreIds.clear();
      _collaborators.clear();
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: 300.ms, curve: Curves.easeOut);
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGenreIds.isEmpty) {
      _showSnack('Por favor selecciona al menos un género', isError: true);
      return;
    }

    final currentFile = widget.audioFiles[_currentFileIndex];
    final songData = {
      'file': currentFile,
      'title': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text),
      'duration': int.parse(_durationController.text),
      'coverImagePath': _imageFilePath,
      'lyrics': _lyricsController.text.trim().isEmpty
          ? null
          : _lyricsController.text.trim(),
      'category': _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      'genreIds': List<int>.from(_selectedGenreIds),
      'collaborators': List<Map<String, String>>.from(_collaborators),
    };

    _completedSongsData.add(songData);

    if (_currentFileIndex < widget.audioFiles.length - 1) {
      _showSnack('Canción guardada. Preparando siguiente...', isError: false);
      _resetFormForNextSong();
      setState(() {
        _currentFileIndex++;
        _showPreview = false;
      });
      _initializeCurrentSong();
    } else {
      Navigator.pop(context, _completedSongsData);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // --- UI Construcción ---

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthProvider>(context); // Keep provider alive
    final currentFile = widget.audioFiles[_currentFileIndex];
    final progress = (_currentFileIndex + 1) / widget.audioFiles.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CANCIÓN ${_currentFileIndex + 1} DE ${widget.audioFiles.length}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textGrey,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Custom thin progress bar in app bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 4,
                width: 120,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.surfaceBlack,
                  valueColor:
                      const AlwaysStoppedAnimation(AppTheme.primaryBlue),
                ),
              ),
            ),
          ],
        ),
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
                _showSnack(
                    'Completa los campos obligatorios antes de previsualizar',
                    isError: true);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner de archivo actual
            _buildFileBanner(currentFile),

            // Contenido Principal
            Expanded(
              child: _showPreview ? _buildPreview() : _buildForm(),
            ),

            // Botón de Acción Inferior
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileBanner(PlatformFile file) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.audio_file_rounded,
                color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${file.extension?.toUpperCase()} • ${_formatFileSize(file.size)}',
                  style:
                      const TextStyle(color: AppTheme.textGrey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.2, end: 0, duration: 300.ms);
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabecera del Formulario (Imagen + Inputs Principales)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Picker
                GestureDetector(
                  onTap: _pickImageFile,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBlack,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
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
                              Icon(Icons.add_photo_alternate_outlined,
                                  color: AppTheme.textGrey, size: 28),
                              SizedBox(height: 4),
                              Text('Portada',
                                  style: TextStyle(
                                      color: AppTheme.textGrey, fontSize: 10)),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black26,
                            ),
                            child: const Center(
                              child: Icon(Icons.edit,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Main Info
                Expanded(
                  child: Column(
                    children: [
                      _buildDarkInput(
                        controller: _nameController,
                        label: 'Título',
                        hint: 'Nombre de la canción',
                        icon: Icons.title,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildDarkInput(
                        controller: _categoryController,
                        label: 'Categoría',
                        hint: 'Ej: Single, Intro...',
                        icon: Icons.tag,
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // 2. Descripción
            _buildSectionLabel('DETALLES'),
            _buildDarkInput(
              controller: _descriptionController,
              label: 'Descripción',
              hint: '¿De qué trata esta canción?',
              icon: Icons.description_outlined,
              maxLines: 3,
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            // 3. Precio y Duración
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
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 24),

            // 4. Géneros
            _buildSectionLabel('GÉNEROS'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBlack,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : Colors.white10,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 0),
                            );
                          }).toList(),
                        ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // 5. Letra (Opcional)
            _buildSectionLabel('LETRA (OPCIONAL)'),
            _buildDarkInput(
              controller: _lyricsController,
              label: 'Letra de la canción',
              hint: 'Pega la letra aquí...',
              icon: Icons.lyrics_outlined,
              maxLines: 6,
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 80), // Espacio para el botón flotante
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
          // Cover Preview
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.cardBlack,
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

          const SizedBox(height: 24),

          Text(
            _nameController.text.isEmpty ? 'Sin Título' : _nameController.text,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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

          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          _buildPreviewRow('Precio', '\$${_priceController.text}'),
          _buildPreviewRow('Duración', '${_durationController.text} seg'),
          _buildPreviewRow(
              'Categoría',
              _categoryController.text.isEmpty
                  ? 'N/A'
                  : _categoryController.text),
          _buildPreviewRow('Géneros', _selectedGenreIds.length.toString()),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLastSong = _currentFileIndex == widget.audioFiles.length - 1;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _saveAndContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLastSong ? 'FINALIZAR ÁLBUM' : 'GUARDAR Y SIGUIENTE',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(width: 8),
              Icon(
                  isLastSong ? Icons.check_circle : Icons.arrow_forward_rounded,
                  size: 20),
            ],
          ),
        ),
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
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
