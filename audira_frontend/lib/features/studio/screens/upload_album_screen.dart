// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/api/services/file_service.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import 'album_song_upload_screen.dart';

class UploadAlbumScreen extends StatefulWidget {
  const UploadAlbumScreen({super.key});

  @override
  State<UploadAlbumScreen> createState() => _UploadAlbumScreenState();
}

class _UploadAlbumScreenState extends State<UploadAlbumScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _releaseDateController = TextEditingController();

  bool _showPreview = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  double _discountPercentage = 15.0;
  String? _coverImagePath;
  List<Song> _selectedSongs = [];
  final List<Map<String, dynamic>> _newSongsData = [];
  Album? _createdAlbum;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _releaseDateController.dispose();
    super.dispose();
  }

  // --- Lógica del Negocio (Intacta) ---

  double get _basePrice {
    double total = 0.0;
    for (var song in _selectedSongs) {
      total += song.price;
    }
    for (var songData in _newSongsData) {
      total += (songData['price'] as double);
    }
    return total;
  }

  double get _finalPrice {
    return _basePrice * (1 - _discountPercentage / 100);
  }

  Future<void> _pickCoverImage() async {
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
          _coverImagePath = image.path;
        });
        _showSnack('Imagen seleccionada: ${image.name}');
      }
    } catch (e) {
      _showSnack('Error al seleccionar imagen: $e', isError: true);
    }
  }

  Future<void> _selectSongs() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    try {
      final musicService = MusicService();
      final response =
          await musicService.getSongsByArtist(authProvider.currentUser!.id);

      if (!response.success || response.data == null) {
        if (mounted) {
          _showSnack('No se pudieron cargar las canciones', isError: true);
        }
        return;
      }

      final songs = response.data!;
      if (!mounted) return;

      final selectedSongs = await showDialog<List<Song>>(
        context: context,
        builder: (context) => _SongSelectionDialog(
          songs: songs,
          alreadySelected: _selectedSongs,
        ),
      );

      if (selectedSongs != null) {
        setState(() => _selectedSongs = selectedSongs);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _selectNewAudioFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final validFiles = <PlatformFile>[];

        for (final file in result.files) {
          final extension = file.extension?.toLowerCase();
          if (extension == null ||
              !['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg']
                  .contains(extension)) {
            if (mounted) {
              _showSnack('Archivo ${file.name} ignorado (formato inválido)',
                  isError: true);
            }
            continue;
          }
          if (file.size > 100 * 1024 * 1024) {
            if (mounted) {
              _showSnack('Archivo ${file.name} ignorado (>100MB)',
                  isError: true);
            }
            continue;
          }
          validFiles.add(file);
        }

        if (validFiles.isNotEmpty) {
          final result = await Navigator.push<List<Map<String, dynamic>>>(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AlbumSongUploadScreen(audioFiles: validFiles),
            ),
          );

          if (result != null && result.isNotEmpty) {
            setState(() {
              _newSongsData.addAll(result);
            });
            if (mounted) {
              _showSnack('${result.length} canción(es) configuradas');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error al seleccionar archivos: $e', isError: true);
      }
    }
  }

  Future<void> _uploadAlbum() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSongs.isEmpty && _newSongsData.isEmpty) {
      _showSnack('Por favor agrega al menos una canción', isError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final musicService = MusicService();
      final fileService = FileService();
      final List<int> allSongIds = _selectedSongs.map((s) => s.id).toList();

      // 1. Subir nuevas canciones
      if (_newSongsData.isNotEmpty) {
        setState(() => _uploadProgress = 0.1);
        final int totalNewSongs = _newSongsData.length;

        for (int i = 0; i < _newSongsData.length; i++) {
          final songData = _newSongsData[i];
          final audioFile = songData['file'] as PlatformFile;
          final progressBase = 0.1 + (i / totalNewSongs) * 0.4;

          try {
            // Audio
            final audioUploadResponse = await fileService.uploadAudioFile(
              audioFile.path!,
              onProgress: (sent, total) {
                if (total > 0) {
                  setState(() {
                    _uploadProgress =
                        progressBase + (sent / total) * (0.4 / totalNewSongs);
                  });
                }
              },
            );

            if (!audioUploadResponse.success) {
              throw Exception('Error al subir audio');
            }

            // Imagen Canción
            String? coverImageUrl;
            if (songData['coverImagePath'] != null) {
              final imageUploadResponse = await fileService.uploadImageFile(
                songData['coverImagePath'] as String,
                onProgress: (sent, total) {},
              );
              if (imageUploadResponse.success) {
                coverImageUrl = imageUploadResponse.data!.fileUrl;
              }
            }

            // Crear Canción
            final songCreateData = {
              'title': songData['title'],
              'artistId': authProvider.currentUser!.id,
              'audioUrl': audioUploadResponse.data!.fileUrl,
              'duration': songData['duration'],
              'price': songData['price'],
              'genreIds': songData['genreIds'],
              'description': songData['description'],
              'category': songData['category'],
              'lyrics': songData['lyrics'],
              'collaborators': songData['collaborators'],
              'coverImageUrl': coverImageUrl,
              'productType': 'SONG',
            };

            final songCreateResponse =
                await musicService.createSong(songCreateData);
            if (!songCreateResponse.success ||
                songCreateResponse.data == null) {
              throw Exception('Error al crear canción');
            }
            allSongIds.add(songCreateResponse.data!.id);
          } catch (e) {
            if (mounted) {
              _showSnack('Error con ${audioFile.name}: $e', isError: true);
            }
          }
        }
      }

      // 2. Subir portada Álbum
      String? coverImageUrl;
      if (_coverImagePath != null) {
        setState(() => _uploadProgress = 0.6);
        final imageUploadResponse = await fileService.uploadImageFile(
          _coverImagePath!,
          onProgress: (sent, total) {
            if (total > 0) {
              setState(() {
                _uploadProgress = 0.6 + (sent / total) * 0.2;
              });
            }
          },
        );
        if (!imageUploadResponse.success) {
          throw Exception('Error al subir portada');
        }
        coverImageUrl = imageUploadResponse.data!.fileUrl;
      }

      // 3. Crear Álbum
      setState(() => _uploadProgress = 0.85);
      final albumData = {
        'title': _titleController.text,
        'artistId': authProvider.currentUser!.id,
        'description': _descriptionController.text,
        'coverImageUrl': coverImageUrl,
        'genreIds': [],
        'releaseDate': _releaseDateController.text.isNotEmpty
            ? _releaseDateController.text
            : null,
        'discountPercentage': _discountPercentage,
        'songIds': allSongIds,
        'productType': 'ALBUM',
      };

      final createResponse = await musicService.createAlbum(albumData);
      if (!createResponse.success || createResponse.data == null) {
        throw Exception('Error final al crear álbum');
      }

      setState(() {
        _createdAlbum = createResponse.data!;
        _uploadProgress = 1.0;
      });

      if (mounted) {
        _showSnack('¡Álbum creado exitosamente! Pendiente de revisión.');
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnack('Error al crear álbum: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'CREAR ÁLBUM',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1),
        ),
        centerTitle: true,
        actions: [
          if (_createdAlbum == null)
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
                        const Text('Subiendo álbum...',
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
            // 1. Portada del Álbum
            Center(
              child: GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBlack,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                    image: _coverImagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_coverImagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: _coverImagePath == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: AppTheme.textGrey, size: 32),
                            SizedBox(height: 8),
                            Text('Portada',
                                style: TextStyle(color: AppTheme.textGrey)),
                          ],
                        )
                      : Container(
                          alignment: Alignment.bottomRight,
                          padding: const EdgeInsets.all(12),
                          child: const CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 16,
                            child:
                                Icon(Icons.edit, size: 16, color: Colors.white),
                          ),
                        ),
                ),
              ),
            ).animate().scale(),

            const SizedBox(height: 32),

            // 2. Información Principal
            _buildSectionLabel('DETALLES DEL ÁLBUM'),
            _buildDarkInput(
              controller: _titleController,
              label: 'Título',
              icon: Icons.album_outlined,
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            _buildDarkInput(
              controller: _descriptionController,
              label: 'Descripción',
              icon: Icons.description_outlined,
              maxLines: 3,
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 16),

            _buildDarkInput(
              controller: _releaseDateController,
              label: 'Fecha de Lanzamiento',
              icon: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.primaryBlue,
                          onPrimary: Colors.white,
                          surface: AppTheme.surfaceBlack,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  _releaseDateController.text =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                }
              },
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 32),

            // 3. Canciones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionLabel(
                    'CANCIONES (${_selectedSongs.length + _newSongsData.length})'),
                if (_selectedSongs.isNotEmpty || _newSongsData.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedSongs.clear();
                        _newSongsData.clear();
                      });
                    },
                    child: const Text('Limpiar Todo',
                        style:
                            TextStyle(fontSize: 12, color: AppTheme.errorRed)),
                  ),
              ],
            ),

            Row(
              children: [
                Expanded(
                    child: _buildActionButton('Subir Archivos',
                        Icons.upload_file_rounded, _selectNewAudioFiles)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildActionButton(
                        'Biblioteca', Icons.library_music_rounded, _selectSongs,
                        isOutlined: true)),
              ],
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 16),

            if (_selectedSongs.isEmpty && _newSongsData.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.cardBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Text('Agrega canciones para el álbum',
                    style: TextStyle(color: AppTheme.textGrey)),
              )
            else
              Column(
                children: [
                  ..._selectedSongs.asMap().entries.map((e) => _buildSongTile(
                      e.value.name,
                      e.value.durationFormatted,
                      e.value.price,
                      false,
                      e.key)),
                  ..._newSongsData.asMap().entries.map((e) => _buildSongTile(
                      e.value['title'],
                      '${e.value['duration']}s',
                      e.value['price'],
                      true,
                      e.key)),
                ],
              ),

            const SizedBox(height: 32),

            // 4. Precios
            if (_selectedSongs.isNotEmpty || _newSongsData.isNotEmpty) ...[
              _buildSectionLabel('PRECIOS Y DESCUENTOS'),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Precio Base',
                            style: TextStyle(color: AppTheme.textGrey)),
                        Text('\$${_basePrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Descuento Álbum',
                            style: TextStyle(color: Colors.white)),
                        Text('${_discountPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: _discountPercentage,
                      min: 0,
                      max: 50,
                      divisions: 10,
                      activeColor: AppTheme.primaryBlue,
                      inactiveColor: Colors.black26,
                      onChanged: (v) => setState(() => _discountPercentage = v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('PRECIO FINAL',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text('\$${_finalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: AppTheme.successGreen,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),
            ],

            // 5. Botón Crear
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadAlbum,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('PUBLICAR ÁLBUM',
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
            ).animate().fadeIn(delay: 350.ms).scale(),

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
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 10))
              ],
              image: _coverImagePath != null
                  ? DecorationImage(
                      image: FileImage(File(_coverImagePath!)),
                      fit: BoxFit.cover)
                  : null,
              color: AppTheme.cardBlack,
            ),
            child: _coverImagePath == null
                ? const Icon(Icons.album, size: 80, color: AppTheme.textGrey)
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            _titleController.text.isEmpty
                ? 'Sin Título'
                : _titleController.text,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _descriptionController.text.isEmpty
                ? 'Sin descripción'
                : _descriptionController.text,
            style: const TextStyle(color: AppTheme.textGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppTheme.cardBlack,
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildPreviewRow('Canciones',
                    '${_selectedSongs.length + _newSongsData.length}'),
                const Divider(color: Colors.white10),
                _buildPreviewRow(
                    'Precio Final', '\$${_finalPrice.toStringAsFixed(2)}'),
                const Divider(color: Colors.white10),
                _buildPreviewRow(
                    'Lanzamiento',
                    _releaseDateController.text.isEmpty
                        ? 'N/A'
                        : _releaseDateController.text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers UI ---

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        label,
        style: const TextStyle(
            color: AppTheme.textGrey,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildDarkInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textGrey),
        prefixIcon: Icon(icon, color: AppTheme.textGrey, size: 20),
        filled: true,
        fillColor: AppTheme.cardBlack,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryBlue)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed,
      {bool isOutlined = false}) {
    return SizedBox(
      height: 48,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cardBlack,
                foregroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
    );
  }

  Widget _buildSongTile(
      String title, String duration, double price, bool isNew, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(12),
        border: isNew
            ? Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isNew ? AppTheme.primaryBlue : AppTheme.surfaceBlack,
          radius: 16,
          child: isNew
              ? const Icon(Icons.cloud_upload_rounded,
                  size: 16, color: Colors.white)
              : const Icon(Icons.music_note_rounded,
                  size: 16, color: AppTheme.textGrey),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        subtitle: Text('$duration • \$${price.toStringAsFixed(2)}',
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline,
              color: AppTheme.errorRed, size: 20),
          onPressed: () {
            setState(() {
              if (isNew) {
                _newSongsData.removeAt(index);
              } else {
                _selectedSongs.removeAt(index);
              }
            });
          },
        ),
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

// --- Dialogo de Selección (Adaptado a Dark Mode) ---
class _SongSelectionDialog extends StatefulWidget {
  final List<Song> songs;
  final List<Song> alreadySelected;

  const _SongSelectionDialog({
    required this.songs,
    this.alreadySelected = const [],
  });

  @override
  State<_SongSelectionDialog> createState() => _SongSelectionDialogState();
}

class _SongSelectionDialogState extends State<_SongSelectionDialog> {
  late Set<int> _selectedIndices;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIndices = {};
    // Pre-seleccionar
    for (var selectedSong in widget.alreadySelected) {
      final index = widget.songs.indexWhere((s) => s.id == selectedSong.id);
      if (index != -1) _selectedIndices.add(index);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar canciones según búsqueda
    final filteredSongsWithIndex = widget.songs.asMap().entries.where((entry) {
      final song = entry.value;
      return song.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: AppTheme.surfaceBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1. Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AGREGAR CANCIONES',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${_selectedIndices.length} seleccionadas',
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Buscador
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar canción...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon: Icon(Icons.search, color: AppTheme.textGrey),
                filled: true,
                fillColor: AppTheme.cardBlack,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Lista de Canciones
            Expanded(
              child: widget.songs.isEmpty
                  ? _buildEmptyState()
                  : filteredSongsWithIndex.isEmpty
                      ? const Center(
                          child: Text('No se encontraron resultados',
                              style: TextStyle(color: AppTheme.textGrey)))
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredSongsWithIndex.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final originalIndex = filteredSongsWithIndex[i].key;
                            final song = filteredSongsWithIndex[i].value;
                            final isSelected =
                                _selectedIndices.contains(originalIndex);

                            return _buildSongItem(
                                song, isSelected, originalIndex);
                          },
                        ),
            ),

            const SizedBox(height: 24),

            // 4. Botones de Acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textGrey,
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('CANCELAR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.songs.isEmpty
                        ? null
                        : () {
                            final selectedSongs = _selectedIndices
                                .map((index) => widget.songs[index])
                                .toList();
                            Navigator.pop(context, selectedSongs);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CONFIRMAR',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongItem(Song song, bool isSelected, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedIndices.remove(index);
          } else {
            _selectedIndices.add(index);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.15)
              : AppTheme.cardBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icono
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppTheme.primaryBlue : AppTheme.surfaceBlack,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.check : Icons.music_note_rounded,
                color: isSelected ? Colors.white : AppTheme.textGrey,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${song.durationFormatted} • \$${song.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : AppTheme.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_music_outlined,
              size: 48, color: AppTheme.textGrey),
          SizedBox(height: 16),
          Text(
            'No tienes canciones disponibles.',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Sube canciones individuales primero para crear un álbum.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }
}
