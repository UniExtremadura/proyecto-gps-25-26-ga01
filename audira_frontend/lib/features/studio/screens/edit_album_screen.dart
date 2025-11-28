import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/api/services/file_service.dart';
import '../../../core/models/genre.dart';
import '../../../core/models/album.dart';

class EditAlbumScreen extends StatefulWidget {
  final Album album;

  const EditAlbumScreen({super.key, required this.album});

  @override
  State<EditAlbumScreen> createState() => _EditAlbumScreenState();
}

class _EditAlbumScreenState extends State<EditAlbumScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;

  final MusicService _musicService = MusicService();
  final FileService _fileService = FileService();

  bool _isSaving = false;
  bool _isLoadingGenres = true;
  String? _imageFilePath;
  DateTime? _releaseDate;
  List<Genre> _availableGenres = [];
  late List<int> _selectedGenreIds;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.album.name);
    _descriptionController =
        TextEditingController(text: widget.album.description ?? '');
    _priceController =
        TextEditingController(text: widget.album.price.toString());
    _discountController =
        TextEditingController(text: widget.album.discountPercentage.toString());
    _releaseDate = widget.album.releaseDate;
    _selectedGenreIds = List.from(widget.album.genreIds);
    _loadGenres();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  // --- Logic (Intact) ---

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
      }
    } catch (e) {
      setState(() => _isLoadingGenres = false);
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
        setState(() => _imageFilePath = image.path);
        if (mounted) _showSnack('Imagen seleccionada');
      }
    } catch (e) {
      if (mounted) _showSnack('Error al seleccionar imagen: $e', isError: true);
    }
  }

  Future<void> _selectReleaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? DateTime.now(),
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

    if (picked != null) {
      setState(() => _releaseDate = picked);
    }
  }

  Future<void> _saveAlbum() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGenreIds.isEmpty) {
      _showSnack('Selecciona al menos un género', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isAuthenticated) {
        throw Exception('Usuario no autenticado');
      }

      String? coverUrl = widget.album.coverImageUrl;
      if (_imageFilePath != null) {
        final uploadResponse =
            await _fileService.uploadImageFile(_imageFilePath!);
        if (uploadResponse.success && uploadResponse.data != null) {
          coverUrl = uploadResponse.data!.fileUrl;
        }
      }

      final albumData = {
        'title': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'discountPercentage': double.parse(_discountController.text),
        'genreIds': _selectedGenreIds,
        'productType': 'ALBUM',
        if (_releaseDate != null)
          'releaseDate': _releaseDate!.toIso8601String().split('T')[0],
        if (coverUrl != null) 'coverImageUrl': coverUrl,
      };

      final response =
          await _musicService.updateAlbum(widget.album.id, albumData);

      if (response.success) {
        if (mounted) {
          _showSnack('Álbum actualizado exitosamente');
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(response.error ?? 'Error desconocido');
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
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
        centerTitle: true,
        title: const Text(
          'EDITAR ÁLBUM',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
        actions: [
          if (_isSaving)
            const Center(
                child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))))
          else
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _saveAlbum,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: _isLoadingGenres
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Portada
                    _buildCoverSection().animate().scale(),

                    const SizedBox(height: 32),

                    // 2. Info Básica
                    _buildSectionLabel('INFORMACIÓN BÁSICA'),
                    _buildDarkInput(
                      controller: _nameController,
                      label: 'Título',
                      icon: Icons.album_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 16),

                    _buildDarkInput(
                      controller: _descriptionController,
                      label: 'Descripción',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDarkInput(
                            controller: _priceController,
                            label: 'Precio',
                            icon: Icons.attach_money,
                            inputType: TextInputType.number,
                            validator: (v) =>
                                (v == null || double.tryParse(v) == null)
                                    ? 'Inválido'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDarkInput(
                            controller: _discountController,
                            label: 'Descuento %',
                            icon: Icons.percent,
                            inputType: TextInputType.number,
                            validator: (v) =>
                                (v == null || double.tryParse(v) == null)
                                    ? 'Inválido'
                                    : null,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 16),

                    _buildDarkInput(
                      controller:
                          TextEditingController(), // Dummy controller just for display
                      label: 'Fecha de Lanzamiento',
                      hint: _releaseDate != null
                          ? '${_releaseDate!.day}/${_releaseDate!.month}/${_releaseDate!.year}'
                          : 'Seleccionar',
                      icon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: _selectReleaseDate,
                    ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 32),

                    // 3. Géneros
                    _buildSectionLabel('GÉNEROS'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBlack,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: _buildGenreSelection(),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 32),

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveAlbum,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(
                            _isSaving ? 'GUARDANDO...' : 'GUARDAR CAMBIOS',
                            style: const TextStyle(
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
            ),
    );
  }

  Widget _buildCoverSection() {
    return Center(
      child: GestureDetector(
        onTap: _pickImageFile,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: AppTheme.cardBlack,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10)),
            ],
            image: _imageFilePath != null
                ? DecorationImage(
                    image: FileImage(File(_imageFilePath!)), fit: BoxFit.cover)
                : (widget.album.coverImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.album.coverImageUrl!),
                        fit: BoxFit.cover)
                    : null),
          ),
          child: (_imageFilePath == null && widget.album.coverImageUrl == null)
              ? const Center(
                  child: Icon(Icons.add_a_photo_outlined,
                      size: 40, color: AppTheme.textGrey))
              : Container(
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildGenreSelection() {
    if (_availableGenres.isEmpty) {
      return const Text('No hay géneros disponibles',
          style: TextStyle(color: AppTheme.textGrey));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableGenres.map((genre) {
        final isSelected = _selectedGenreIds.contains(genre.id);
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
          backgroundColor: AppTheme.surfaceBlack,
          selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
          checkmarkColor: AppTheme.primaryBlue,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.textGrey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: isSelected ? AppTheme.primaryBlue : Colors.white10),
          ),
          padding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

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
    String? hint,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: inputType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.white
                .withValues(alpha: 0.5)), // Hint visible si value es nulo
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
}
