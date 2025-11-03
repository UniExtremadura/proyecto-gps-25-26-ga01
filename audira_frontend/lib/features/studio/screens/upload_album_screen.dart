// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/models/song.dart';

class UploadAlbumScreen extends StatefulWidget {
  const UploadAlbumScreen({super.key});

  @override
  State<UploadAlbumScreen> createState() => _UploadAlbumScreenState();
}

class _UploadAlbumScreenState extends State<UploadAlbumScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '19.99');
  final _releaseDateController = TextEditingController();

  bool _showPreview = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _coverImageFileName;
  List<String> _selectedSongs = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _releaseDateController.dispose();
    super.dispose();
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
          _coverImageFileName = image.name;
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
            const SnackBar(content: Text('No se pudieron cargar las canciones')),
          );
        }
        return;
      }

      final songs = response.data!;
      if (!mounted) return;

      final selectedSongs = await showDialog<List<String>>(
        context: context,
        builder: (context) => _SongSelectionDialog(songs: songs),
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

  Future<void> _uploadAlbum() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one song')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    for (var i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => _uploadProgress = i / 100);
    }

    setState(() => _isUploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Album uploaded successfully!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Album'),
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
      body: _showPreview ? _buildPreview() : _buildForm(),
      bottomNavigationBar: _isUploading
          ? Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Uploading... ${(_uploadProgress * 100).toInt()}%'),
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
            Card(
              child: ListTile(
                leading: const Icon(Icons.image, color: AppTheme.primaryBlue),
                title: Text(_coverImageFileName ?? 'Select Cover Image'),
                trailing: const Icon(Icons.upload_file),
                onTap: _pickCoverImage,
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Album Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.album),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ).animate().fadeIn(delay: 50.ms),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _releaseDateController,
                    decoration: const InputDecoration(
                      labelText: 'Release Date',
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
                            '${date.year}-${date.month}-${date.day}';
                      }
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.music_note, color: AppTheme.primaryBlue),
                title: Text(_selectedSongs.isEmpty
                    ? 'Add Songs'
                    : '${_selectedSongs.length} songs selected'),
                trailing: const Icon(Icons.add),
                onTap: _selectSongs,
              ),
            ).animate().fadeIn(delay: 200.ms),
            if (_selectedSongs.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._selectedSongs.asMap().entries.map((entry) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryBlue,
                        child: Text('${entry.key + 1}'),
                      ),
                      title: Text(entry.value),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() => _selectedSongs.removeAt(entry.key));
                        },
                      ),
                    ),
                  )),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadAlbum,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Upload Album'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                ),
              ),
            ).animate().fadeIn(delay: 250.ms).scale(),
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
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.album,
                  size: 80, color: AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _titleController.text.isEmpty
                ? 'Album Title'
                : _titleController.text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_descriptionController.text,
              style: const TextStyle(color: AppTheme.textGrey)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.attach_money, color: AppTheme.primaryBlue),
              Text('\$${_priceController.text}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Track List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._selectedSongs.asMap().entries.map(
                (entry) => ListTile(
                  leading: Text('${entry.key + 1}'),
                  title: Text(entry.value),
                ),
              ),
        ],
      ),
    );
  }
}

class _SongSelectionDialog extends StatefulWidget {
  final List<Song> songs;

  const _SongSelectionDialog({required this.songs});

  @override
  State<_SongSelectionDialog> createState() => _SongSelectionDialogState();
}

class _SongSelectionDialogState extends State<_SongSelectionDialog> {
  final Set<int> _selectedIndices = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Songs'),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.songs.isEmpty
            ? const Center(
                child: Text('No songs available. Upload songs first.'),
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final selectedSongs = _selectedIndices
                .map((index) => widget.songs[index].name)
                .toList();
            Navigator.pop(context, selectedSongs);
          },
          child: Text('Select (${_selectedIndices.length})'),
        ),
      ],
    );
  }
}
