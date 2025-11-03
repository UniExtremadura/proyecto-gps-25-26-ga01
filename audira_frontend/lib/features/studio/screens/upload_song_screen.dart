// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';

class UploadSongScreen extends StatefulWidget {
  const UploadSongScreen({super.key});

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _priceController = TextEditingController(text: '9.99');
  final _durationController = TextEditingController();

  bool _showPreview = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _audioFileName;
  String? _imageFileName;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _lyricsController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _audioFileName = result.files.first.name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio seleccionado: ${result.files.first.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar audio: $e')),
      );
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
          _imageFileName = image.name;
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

  Future<void> _uploadSong() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audioFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an audio file')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // Simulate upload progress
    for (var i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => _uploadProgress = i / 100);
    }

    setState(() => _isUploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Song uploaded successfully!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Song'),
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
            // Audio File
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.audiotrack, color: AppTheme.primaryBlue),
                title: Text(_audioFileName ?? 'Select Audio File'),
                subtitle: const Text('MP3, WAV, FLAC'),
                trailing: const Icon(Icons.upload_file),
                onTap: _pickAudioFile,
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 16),

            // Cover Image
            Card(
              child: ListTile(
                leading: const Icon(Icons.image, color: AppTheme.primaryBlue),
                title: Text(_imageFileName ?? 'Select Cover Image'),
                subtitle: const Text('JPG, PNG (Optional)'),
                trailing: const Icon(Icons.upload_file),
                onTap: _pickImageFile,
              ),
            ).animate().fadeIn(delay: 50.ms),
            const SizedBox(height: 24),

            // Song Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Song Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.music_note),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter song name';
                }
                return null;
              },
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 16),

            // Lyrics (Optional)
            TextFormField(
              controller: _lyricsController,
              decoration: const InputDecoration(
                labelText: 'Lyrics (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lyrics),
              ),
              maxLines: 5,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),

            // Price and Duration
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
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
                      labelText: 'Duration (sec) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 24),

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadSong,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Upload Song'),
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
          // Cover Image Preview
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.music_note,
                  size: 80, color: AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(height: 24),

          // Song Details
          Text(
            _nameController.text.isEmpty ? 'Song Name' : _nameController.text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _descriptionController.text.isEmpty
                ? 'Description'
                : _descriptionController.text,
            style: const TextStyle(color: AppTheme.textGrey),
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
          const SizedBox(height: 16),

          // Duration
          if (_durationController.text.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.timer, color: AppTheme.textGrey),
                const SizedBox(width: 8),
                Text('${_durationController.text}s'),
              ],
            ),
          const SizedBox(height: 24),

          // Lyrics
          if (_lyricsController.text.isNotEmpty) ...[
            const Text(
              'Lyrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlack,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _lyricsController.text,
                style:
                    const TextStyle(color: AppTheme.textSecondary, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
