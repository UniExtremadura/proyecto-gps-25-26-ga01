// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/models/genre.dart';
import '../../../core/api/services/music_service.dart';

class AdminGenresScreen extends StatefulWidget {
  const AdminGenresScreen({super.key});

  @override
  State<AdminGenresScreen> createState() => _AdminGenresScreenState();
}

class _AdminGenresScreenState extends State<AdminGenresScreen> {
  final MusicService _musicService = MusicService();
  final TextEditingController _searchController = TextEditingController();

  // --- Colores del Tema Oscuro ---
  final Color darkBg = Colors.black;
  final Color darkCardBg = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  List<Genre> _genres = [];
  List<Genre> _filteredGenres = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGenres() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _musicService.getAllGenres();
      if (response.success && response.data != null) {
        setState(() {
          _genres = response.data!;
          _filteredGenres = _genres;
        });
      } else {
        setState(
            () => _error = response.error ?? 'Error al cargar los géneros');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterGenres(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGenres = _genres;
      } else {
        _filteredGenres = _genres
            .where((genre) =>
                genre.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _deleteGenre(int genreId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        title: Text('Eliminar Género', style: TextStyle(color: lightText)),
        content: Text('¿Estás seguro de que quieres eliminar este género?',
            style: TextStyle(color: subText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final currentContext = context;
      try {
        final response = await _musicService.deleteGenre(genreId);
        if (!currentContext.mounted) return;

        if (response.success) {
          _showSnack('Género eliminado exitosamente');
          _loadGenres();
        } else {
          _showSnack(response.error ?? 'Error al eliminar el género',
              isError: true);
        }
      } catch (e) {
        if (!currentContext.mounted) return;
        _showSnack('Error: $e', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[900] : Colors.green[800],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg, // FONDO NEGRO
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Administrar Géneros',
          style: TextStyle(
              color: AppTheme.primaryBlue, fontWeight: FontWeight.w800),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: AppTheme.primaryBlue),
              tooltip: 'Añadir Género',
              onPressed: () => _showGenreForm(null),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. HEADER STATS & SEARCH
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            color: darkBg,
            child: Column(
              children: [
                // Stats Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: darkCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[850]!),
                      image: DecorationImage(
                        image: const NetworkImage(
                            'https://source.unsplash.com/random/800x200/?abstract,music'), // Opcional: Patrón de fondo
                        colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.8),
                            BlendMode.darken),
                        fit: BoxFit.cover,
                      )),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                            shape: BoxShape.circle),
                        child: Icon(Icons.category,
                            color: AppTheme.primaryBlue, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Géneros Totales',
                              style: TextStyle(color: subText, fontSize: 13)),
                          Text(_genres.length.toString(),
                              style: TextStyle(
                                  color: lightText,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: darkCardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: lightText),
                    decoration: InputDecoration(
                      hintText: 'Buscar géneros...',
                      hintStyle: TextStyle(color: subText),
                      prefixIcon: Icon(Icons.search, color: subText),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: _filterGenres,
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: -0.2, end: 0, duration: 300.ms),

          // 2. GRID DE GÉNEROS
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryBlue))
                : _error != null
                    ? _buildErrorState()
                    : _filteredGenres.isEmpty
                        ? const Center(
                            child: Text('No se encontraron géneros',
                                style: TextStyle(color: Colors.grey)))
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio:
                                  1.3, // Tarjetas más rectangulares
                            ),
                            itemCount: _filteredGenres.length,
                            itemBuilder: (context, index) {
                              return _buildGenreCard(
                                  _filteredGenres[index], index);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreCard(Genre genre, int index) {
    // Generar un color pseudo-aleatorio basado en el ID para variedad visual
    final List<Color> cardColors = [
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
    ];
    final Color accentColor = cardColors[genre.id % cardColors.length];

    return InkWell(
      onTap: () => _showGenreForm(genre),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
            color: darkCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[850]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]),
        child: Stack(
          children: [
            // Fondo con icono grande y translúcido (Efecto artístico)
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.music_note,
                size: 100,
                color: accentColor.withValues(alpha: 0.05),
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.graphic_eq,
                            color: accentColor, size: 18),
                      ),
                      // Botón eliminar discreto
                      InkWell(
                        onTap: () => _deleteGenre(genre.id),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close,
                                color: Colors.red[300], size: 16)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        genre.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: lightText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        genre.description != null &&
                                genre.description!.isNotEmpty
                            ? genre.description!
                            : 'Sin descripción',
                        style: TextStyle(
                          fontSize: 12,
                          color: subText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 50).ms)
        .scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[900]),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadGenres,
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _showGenreForm(Genre? genre) {
    final isEditing = genre != null;
    final nameController = TextEditingController(text: genre?.name ?? '');
    final descriptionController =
        TextEditingController(text: genre?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        title: Text(isEditing ? 'Editar Género' : 'Añadir Nuevo Género',
            style: TextStyle(color: lightText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: lightText),
              decoration: InputDecoration(
                labelText: 'Nombre del Género',
                labelStyle: TextStyle(color: subText),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryBlue)),
                prefixIcon: Icon(Icons.label, color: subText),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              style: TextStyle(color: lightText),
              decoration: InputDecoration(
                labelText: 'Descripción',
                labelStyle: TextStyle(color: subText),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryBlue)),
                prefixIcon: Icon(Icons.description, color: subText),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                _showSnack('El nombre del género es obligatorio',
                    isError: true);
                return;
              }
              Navigator.pop(context);
              _showSnack(isEditing
                  ? 'Género actualizado exitosamente'
                  : 'Género creado exitosamente');
              _loadGenres();
            },
            child: Text(isEditing ? 'Actualizar' : 'Crear'),
          ),
        ],
      ),
    );
  }
}
