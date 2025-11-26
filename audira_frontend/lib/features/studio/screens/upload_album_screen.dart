// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/api/services/file_service.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';

// Clase para manejar los datos de las nuevas canciones
class NewSongData {
  final PlatformFile file;
  String title;
  double price;
  List<int> genreIds;
  String description;

  NewSongData({
    required this.file,
    required this.title,
    this.price = 9.99,
    this.genreIds = const [],
    this.description = '',
  });
}

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
  bool _publishNow = true; // Publicar inmediatamente por defecto
  double _uploadProgress = 0.0;
  double _discountPercentage = 15.0; // Porcentaje de descuento por defecto
  String? _coverImagePath;
  List<Song> _selectedSongs = [];
  final List<NewSongData> _newSongsData = []; // Nuevos archivos con sus datos
  Album? _createdAlbum;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _releaseDateController.dispose();
    super.dispose();
  }

  // Calcular precio base del álbum (suma de todas las canciones)
  double get _basePrice {
    double total = 0.0;
    // Sumar precios de canciones existentes
    for (var song in _selectedSongs) {
      total += song.price;
    }
    // Sumar precios de canciones nuevas
    for (var songData in _newSongsData) {
      total += songData.price;
    }
    return total;
  }

  // Calcular precio final con descuento
  double get _finalPrice {
    return _basePrice * (1 - _discountPercentage / 100);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imagen seleccionada: ${image.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _selectSongs() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    try {
      final musicService = MusicService();
      final response = await musicService.getSongsByArtist(
        authProvider.currentUser!.id,
      );

      if (!response.success || response.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No se pudieron cargar las canciones')),
          );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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

          // Validar extensión
          if (extension == null ||
              !['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg'].contains(extension)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Archivo ${file.name} tiene formato no válido y será ignorado'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            continue;
          }

          // Validar tamaño (máximo 100MB)
          if (file.size > 100 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Archivo ${file.name} es demasiado grande (máx 100MB) y será ignorado'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            continue;
          }

          validFiles.add(file);
        }

        if (validFiles.isNotEmpty) {
          // Mostrar diálogo para cada archivo para configurar sus datos
          final newSongsData = <NewSongData>[];

          for (final file in validFiles) {
            final songData = await _showSongDataDialog(file);
            if (songData != null) {
              newSongsData.add(songData);
            }
          }

          if (newSongsData.isNotEmpty) {
            setState(() {
              _newSongsData.addAll(newSongsData);
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${newSongsData.length} canción(es) configuradas'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivos: $e')),
        );
      }
    }
  }

  Future<NewSongData?> _showSongDataDialog(PlatformFile file) async {
    final titleController = TextEditingController(
      text: file.name.replaceAll(RegExp(r'\.\w+$'), ''), // Nombre sin extensión
    );
    final priceController = TextEditingController(text: '9.99');
    final descriptionController = TextEditingController();

    return showDialog<NewSongData>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Datos de: ${file.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la canción *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.music_note),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              titleController.dispose();
              priceController.dispose();
              descriptionController.dispose();
              Navigator.pop(context, null);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty || priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Título y precio son requeridos')),
                );
                return;
              }

              final songData = NewSongData(
                file: file,
                title: titleController.text,
                price: double.tryParse(priceController.text) ?? 9.99,
                description: descriptionController.text,
              );

              titleController.dispose();
              priceController.dispose();
              descriptionController.dispose();
              Navigator.pop(context, songData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAlbum() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSongs.isEmpty && _newSongsData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor agrega al menos una canción')),
      );
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

      // Paso 1: Subir nuevos archivos de audio como canciones
      if (_newSongsData.isNotEmpty) {
        setState(() => _uploadProgress = 0.1);
        final int totalNewSongs = _newSongsData.length;

        for (int i = 0; i < _newSongsData.length; i++) {
          final songData = _newSongsData[i];
          final audioFile = songData.file;
          final progress = 0.1 + (i / totalNewSongs) * 0.4;

          try {
            // Subir archivo de audio
            final audioUploadResponse = await fileService.uploadAudioFile(
              audioFile.path!,
              onProgress: (sent, total) {
                setState(() {
                  _uploadProgress = progress + (sent / total) * (0.4 / totalNewSongs);
                });
              },
            );

            if (!audioUploadResponse.success) {
              throw Exception('Error al subir ${audioFile.name}: ${audioUploadResponse.error}');
            }

             int duration = 180;

            try {
              final player = AudioPlayer();

              final durationTime = await player.setFilePath(audioFile.path!);

              if (durationTime != null) {
                duration = durationTime.inSeconds;
              }
              await player.dispose();
            } catch (e) {
              debugPrint('Error al extraer duración de ${audioFile.name}: $e');
            }

            // Crear la canción con los datos configurados por el usuario
            final songCreateData = {
              'name': songData.title,
              'artistId': authProvider.currentUser!.id,
              'audioFileUrl': audioUploadResponse.data!.fileUrl,
              'duration': duration,
              'price': songData.price,
              'fileSize': audioFile.size,
              'format': audioFile.extension,
              'genreIds': songData.genreIds,
              'description': songData.description.isNotEmpty ? songData.description : null,
            };

            final songCreateResponse = await musicService.createSong(songCreateData);

            if (!songCreateResponse.success || songCreateResponse.data == null) {
              throw Exception('Error al crear canción ${songData.title}');
            }

            allSongIds.add(songCreateResponse.data!.id);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error con ${audioFile.name}: $e'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }

      // Paso 2: Subir la imagen de portada si existe
      String? coverImageUrl;
      if (_coverImagePath != null) {
        setState(() => _uploadProgress = 0.6);

        final imageUploadResponse = await fileService.uploadImageFile(
          _coverImagePath!,
          onProgress: (sent, total) {
            setState(() {
              _uploadProgress = 0.6 + (sent / total) * 0.2;
            });
          },
        );

        if (!imageUploadResponse.success) {
          throw Exception(
              'Error al subir imagen: ${imageUploadResponse.error}');
        }

        coverImageUrl = imageUploadResponse.data!.fileUrl;
      }

      // Paso 3: Crear el álbum con la URL de la imagen y todas las canciones
      setState(() => _uploadProgress = 0.85);

      final albumData = {
        'title': _titleController.text,
        'artistId': authProvider.currentUser!.id,
        'description': _descriptionController.text,
        // NO enviar precio - se calcula en el backend
        'coverImageUrl': coverImageUrl,
        'genreIds': [],
        'releaseDate': _releaseDateController.text.isNotEmpty
            ? _releaseDateController.text
            : null,
        'discountPercentage': _discountPercentage,
        'songIds': allSongIds,
        'published': _publishNow, // Incluir estado de publicación
      };

      final createResponse = await musicService.createAlbum(albumData);

      if (!createResponse.success || createResponse.data == null) {
        throw Exception('Error al crear el álbum');
      }

      setState(() {
        _createdAlbum = createResponse.data!;
        _uploadProgress = 1.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Álbum creado exitosamente con ${allSongIds.length} canciones!'
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Mostrar diálogo para publicar
        _showPublishDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear álbum: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _showPublishDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Publicar álbum?'),
        content: const Text(
          '¿Deseas publicar el álbum ahora para que esté visible para los usuarios?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Publicar después'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Publicar ahora'),
          ),
        ],
      ),
    );

    if (result == true && _createdAlbum != null) {
      await _publishAlbum(true);
    } else {
      // Volver a la pantalla anterior
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _publishAlbum(bool publish) async {
    if (_createdAlbum == null) return;

    try {
      final musicService = MusicService();
      final response = await musicService.publishAlbum(
        _createdAlbum!.id,
        publish,
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                publish
                    ? '¡Álbum publicado exitosamente!'
                    : 'Álbum despublicado',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Volver a la pantalla anterior después de publicar
          if (publish) {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Álbum'),
        actions: [
          if (_createdAlbum == null)
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
      body: _showPreview ? _buildPreview() : _buildForm(),
      bottomNavigationBar: _isUploading
          ? Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Subiendo... ${(_uploadProgress * 100).toInt()}%'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _uploadProgress),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección: Portada del álbum
            Card(
              child: InkWell(
                onTap: _pickCoverImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBlack,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _coverImagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_coverImagePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 60,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toca para seleccionar portada',
                              style: TextStyle(color: AppTheme.textGrey),
                            ),
                          ],
                        ),
                ),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 24),

            // Información del álbum
            Text(
              'Información del Álbum',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título del Álbum *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.album),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ).animate().fadeIn(delay: 50.ms),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),

            TextFormField(
              controller: _releaseDateController,
              decoration: const InputDecoration(
                labelText: 'Fecha de Lanzamiento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  _releaseDateController.text =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                }
              },
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 24),

            // Sección de Precios
            if (_selectedSongs.isNotEmpty || _newSongsData.isNotEmpty) ...[
              Card(
                color: AppTheme.primaryBlue.withValues(alpha:0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Precios del Álbum',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Precio base:'),
                          Text(
                            '\$${_basePrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Descuento: ${_discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Slider(
                        value: _discountPercentage,
                        min: 0,
                        max: 50,
                        divisions: 50,
                        label: '${_discountPercentage.toStringAsFixed(0)}%',
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (value) {
                          setState(() => _discountPercentage = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Precio final:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${_finalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ahorro: \$${(_basePrice - _finalPrice).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 175.ms),
              const SizedBox(height: 24),
            ],

            // Sección: Canciones
            Text(
              'Canciones del Álbum',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.music_note, color: AppTheme.primaryBlue),
                    title: Text(_selectedSongs.isEmpty
                        ? 'Agregar Canciones Existentes'
                        : '${_selectedSongs.length} canciones seleccionadas'),
                    trailing: const Icon(Icons.add),
                    onTap: _selectSongs,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.upload_file, color: AppTheme.primaryBlue),
                    title: Text(_newSongsData.isEmpty
                        ? 'Subir Nuevas Canciones (Múltiples)'
                        : '${_newSongsData.length} canciones nuevas'),
                    trailing: const Icon(Icons.add),
                    onTap: _selectNewAudioFiles,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            if (_selectedSongs.isNotEmpty || _newSongsData.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._selectedSongs.asMap().entries.map((entry) {
                final index = entry.key;
                final song = entry.value;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(song.name),
                    subtitle: Text('${song.durationFormatted} - \$${song.price.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() => _selectedSongs.removeAt(index));
                      },
                    ),
                  ),
                ).animate().fadeIn(delay: (250 + index * 50).ms);
              }),
              ..._newSongsData.asMap().entries.map((entry) {
                final index = entry.key;
                final songData = entry.value;
                final songIndex = _selectedSongs.length + index + 1;
                return Card(
                  color: AppTheme.primaryBlue.withValues(alpha:0.1),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue,
                      child: Text('$songIndex'),
                    ),
                    title: Text(songData.title),
                    subtitle: Text('Nueva - \$${songData.price.toStringAsFixed(2)} - ${_formatFileSize(songData.file.size)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() => _newSongsData.removeAt(index));
                      },
                    ),
                  ),
                ).animate().fadeIn(delay: (250 + songIndex * 50).ms);
              }),
            ],

            const SizedBox(height: 24),

            // Publicar inmediatamente
            Card(
              child: SwitchListTile(
                title: const Text(
                  '¿Publicar inmediatamente?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _publishNow
                      ? 'El álbum será visible para todos los usuarios'
                      : 'El álbum quedará oculto hasta que lo publiques manualmente',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: _publishNow,
                onChanged: (value) {
                  setState(() {
                    _publishNow = value;
                  });
                },
                activeThumbColor: AppTheme.primaryBlue,
                secondary: Icon(
                  _publishNow ? Icons.visibility : Icons.visibility_off,
                  color: _publishNow ? AppTheme.primaryBlue : Colors.grey,
                ),
              ),
            ).animate().fadeIn(delay: 275.ms),

            const SizedBox(height: 16),

            // Botón de crear álbum
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadAlbum,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Crear Álbum'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portada
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlack,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: _coverImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_coverImagePath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.album,
                      size: 100,
                      color: AppTheme.primaryBlue,
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Información del álbum
          Center(
            child: Text(
              _titleController.text.isEmpty
                  ? 'Título del Álbum'
                  : _titleController.text,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),

          if (_descriptionController.text.isNotEmpty) ...[
            Center(
              child: Text(
                _descriptionController.text,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Precios
          if (_selectedSongs.isNotEmpty || _newSongsData.isNotEmpty) ...[
            Center(
              child: Column(
                children: [
                  Text(
                    'Precio base: \$${_basePrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textGrey,
                      decoration: _discountPercentage > 0
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_discountPercentage > 0) ...[
                    Text(
                      'Descuento: ${_discountPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.attach_money,
                          color: AppTheme.primaryBlue, size: 32),
                      Text(
                        _finalPrice.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (_discountPercentage > 0)
                    Text(
                      'Ahorras: \$${(_basePrice - _finalPrice).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Lista de canciones
          const Divider(),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lista de Canciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_selectedSongs.length + _newSongsData.length} canciones',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_selectedSongs.isEmpty && _newSongsData.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No hay canciones seleccionadas',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              ),
            )
          else ...[
            ..._selectedSongs.asMap().entries.map((entry) {
              final index = entry.key;
              final song = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text('${index + 1}'),
                ),
                title: Text(song.name),
                subtitle: Text('${song.durationFormatted} - \$${song.price.toStringAsFixed(2)}'),
                trailing: Icon(
                  Icons.play_circle_outline,
                  color: AppTheme.primaryBlue,
                ),
              );
            }),
            ..._newSongsData.asMap().entries.map((entry) {
              final index = entry.key;
              final songData = entry.value;
              final songIndex = _selectedSongs.length + index + 1;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text('$songIndex'),
                ),
                title: Text(songData.title),
                subtitle: Text('Nueva - \$${songData.price.toStringAsFixed(2)}'),
                trailing: const Icon(
                  Icons.fiber_new,
                  color: Colors.green,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _selectedIndices = {};

    // Preseleccionar canciones ya seleccionadas
    for (var selectedSong in widget.alreadySelected) {
      final index = widget.songs.indexWhere((s) => s.id == selectedSong.id);
      if (index != -1) {
        _selectedIndices.add(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Canciones'),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.songs.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No tienes canciones disponibles.\nSube canciones primero.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.songs.length,
                itemBuilder: (context, index) {
                  final song = widget.songs[index];
                  final isSelected = _selectedIndices.contains(index);

                  return CheckboxListTile(
                    title: Text(song.name),
                    subtitle: Text(song.durationFormatted),
                    value: isSelected,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIndices.add(index);
                        } else {
                          _selectedIndices.remove(index);
                        }
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
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
          ),
          child: Text('Seleccionar (${_selectedIndices.length})'),
        ),
      ],
    );
  }
}
