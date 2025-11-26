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

/// Pantalla para subir múltiples canciones como parte de un álbum
/// Muestra un formulario para cada canción y permite navegar entre ellas
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
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _priceController = TextEditingController(text: '9.99');
  final _durationController = TextEditingController();
  final _categoryController = TextEditingController();
  final MusicService _musicService = MusicService();

  bool _showPreview = false;
  final bool _isUploading = false;
  bool _isLoadingGenres = true;
  final double _uploadProgress = 0.0;
  String? _imageFileName;
  String? _imageFilePath;
  List<Genre> _availableGenres = [];
  final List<int> _selectedGenreIds = [];

  // Datos completados de las canciones ya procesadas
  late List<Map<String, dynamic>> _completedSongsData;
  late int _currentFileIndex;

  // Colaboradores
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
    super.dispose();
  }

  void _initializeCurrentSong() {
    final currentFile = widget.audioFiles[_currentFileIndex];

    // Inicializar nombre con el nombre del archivo (sin extensión)
    _nameController.text = currentFile.name.replaceAll(RegExp(r'\.\w+$'), '');

    // Intentar obtener duración del audio
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error al cargar géneros: ${response.error}')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingGenres = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar géneros: $e')),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickImageFile() async {
    final currentContext = context;
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
          _imageFileName = image.name;
          _imageFilePath = image.path;
        });
        if (!currentContext.mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Imagen seleccionada: ${image.name}')),
        );
      }
    } catch (e) {
      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
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
      _imageFileName = null;
      _imageFilePath = null;
      _selectedGenreIds.clear();
      _collaborators.clear();
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGenreIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un género'),
          backgroundColor: Colors.red,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Canción "${_nameController.text}" guardada. Siguiente...'),
          duration: const Duration(milliseconds: 800),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );

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

  void _addCollaborator() {
    if (_collaboratorNameController.text.trim().isEmpty ||
        _collaboratorRoleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa el nombre y rol del colaborador'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _collaborators.add({
        'name': _collaboratorNameController.text.trim(),
        'role': _collaboratorRoleController.text.trim(),
      });
      _collaboratorNameController.clear();
      _collaboratorRoleController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Colaborador añadido'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _removeCollaborator(int index) {
    setState(() {
      _collaborators.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthProvider>(context);
    final currentFile = widget.audioFiles[_currentFileIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Canción ${_currentFileIndex + 1} de ${widget.audioFiles.length}'),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() => _showPreview = !_showPreview);
              }
            },
          ),
        ],
      ),
      body: _showPreview ? _buildPreview() : _buildForm(currentFile),
      bottomNavigationBar: _isUploading
          ? Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Subiendo canción... ${(_uploadProgress * 100).toInt()}%'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _uploadProgress),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildForm(PlatformFile currentFile) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del progreso
            Card(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.audiotrack,
                            color: AppTheme.primaryBlue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentFile.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${currentFile.extension?.toUpperCase()} • ${_formatFileSize(currentFile.size)}',
                                style: const TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (_currentFileIndex + 1) / widget.audioFiles.length,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryBlue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Canción ${_currentFileIndex + 1} de ${widget.audioFiles.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 24),

            // Cover Image
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading:
                        const Icon(Icons.image, color: AppTheme.primaryBlue),
                    title: Text(_imageFileName ?? 'Seleccionar Portada'),
                    subtitle: const Text('JPG, PNG (Opcional)'),
                    trailing: Icon(
                      _imageFileName != null
                          ? Icons.check_circle
                          : Icons.upload_file,
                      color: _imageFileName != null ? Colors.green : null,
                    ),
                    onTap: _pickImageFile,
                  ),
                  if (_imageFilePath != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_imageFilePath!),
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 50.ms),
            const SizedBox(height: 24),

            // Canción Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Canción *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.music_note),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el nombre de la canción';
                }
                return null;
              },
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                helperText: 'Describe tu canción (estilo, mood, historia)',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa una descripción';
                }
                return null;
              },
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 16),

            // Géneros - Selección Múltiple
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category,
                            color: AppTheme.primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Géneros *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingGenres)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_availableGenres.isEmpty)
                      const Text(
                        'No hay géneros disponibles',
                        style: TextStyle(color: AppTheme.textGrey),
                      )
                    else
                      Wrap(
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
                                if (selected) {
                                  _selectedGenreIds.add(genre.id);
                                } else {
                                  _selectedGenreIds.remove(genre.id);
                                }
                              });
                            },
                            selectedColor:
                                AppTheme.primaryBlue.withValues(alpha: 0.3),
                            checkmarkColor: AppTheme.primaryBlue,
                            backgroundColor: AppTheme.surfaceBlack,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          );
                        }).toList(),
                      ),
                    if (_selectedGenreIds.isEmpty && !_isLoadingGenres)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Selecciona al menos un género',
                          style:
                              TextStyle(color: AppTheme.textGrey, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 175.ms),
            const SizedBox(height: 16),

            // Categoría/Metadata
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Categoría (Opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
                helperText: 'Ej: Single, Álbum, EP, Remix, Cover',
              ),
              maxLines: 1,
            ).animate().fadeIn(delay: 185.ms),
            const SizedBox(height: 16),

            // Colaboradores
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people,
                            color: AppTheme.primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Colaboradores (Opcional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _collaboratorNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _collaboratorRoleController,
                            decoration: const InputDecoration(
                              labelText: 'Rol',
                              border: OutlineInputBorder(),
                              isDense: true,
                              helperText: 'Ej: feat, productor',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addCollaborator,
                          icon: const Icon(Icons.add_circle,
                              color: AppTheme.primaryBlue),
                          tooltip: 'Añadir colaborador',
                        ),
                      ],
                    ),
                    if (_collaborators.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      ...List.generate(_collaborators.length, (index) {
                        final collab = _collaborators[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.person,
                                  size: 16, color: AppTheme.textGrey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${collab['name']} - ${collab['role']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeCollaborator(index),
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 190.ms),
            const SizedBox(height: 16),

            // Lyrics (Optional)
            TextFormField(
              controller: _lyricsController,
              decoration: const InputDecoration(
                labelText: 'Letra (Opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lyrics),
              ),
              maxLines: 5,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),

            // Precio and Duration
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duración (seg) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 24),

            // Botón de guardar y continuar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _saveAndContinue,
                icon: Icon(_currentFileIndex < widget.audioFiles.length - 1
                    ? Icons.arrow_forward
                    : Icons.check),
                label: Text(_currentFileIndex < widget.audioFiles.length - 1
                    ? 'Guardar y Continuar'
                    : 'Guardar y Finalizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).scale(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final selectedGenres = _availableGenres
        .where((genre) => _selectedGenreIds.contains(genre.id))
        .toList();
    final currentFile = widget.audioFiles[_currentFileIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image Preview
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlack,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _imageFilePath != null
                    ? Image.file(
                        File(_imageFilePath!),
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(Icons.music_note,
                            size: 100, color: AppTheme.primaryBlue),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Canción Details
          Text(
            _nameController.text.isEmpty
                ? 'Nombre de la Canción'
                : _nameController.text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _descriptionController.text.isEmpty
                ? 'Descripción'
                : _descriptionController.text,
            style: const TextStyle(color: AppTheme.textGrey),
          ),
          const SizedBox(height: 16),

          // Genres
          if (selectedGenres.isNotEmpty) ...[
            const Text(
              'Géneros',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedGenres.map((genre) {
                return Chip(
                  label: Text(genre.name),
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  labelStyle: const TextStyle(color: Colors.white),
                  avatar: const Icon(Icons.music_note,
                      color: AppTheme.primaryBlue, size: 16),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Audio File Info
          Card(
            color: AppTheme.surfaceBlack,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.audiotrack, color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentFile.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${currentFile.extension?.toUpperCase()} • ${_formatFileSize(currentFile.size)}',
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Price
          Row(
            children: [
              const Icon(Icons.attach_money, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                '\$${_priceController.text}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
