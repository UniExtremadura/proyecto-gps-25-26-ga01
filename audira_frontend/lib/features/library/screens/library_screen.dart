import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/download_provider.dart';
import '../../../core/api/services/playlist_service.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/models/genre.dart'; // Clase Genre
import '../../../core/models/playlist.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/models/downloaded_song.dart';
import '../../../config/routes.dart';

// Enums para la ordenación (se mantienen)
enum SortCriterion { name, date }

enum SortOrder { asc, desc }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PlaylistService _playlistService = PlaylistService();
  final MusicService _musicService = MusicService();

  List<Playlist> _playlists = [];
  bool _isLoading = true;
  bool _isLoadingGenres = false;

  // ESTADO DEL FILTRO
  bool _isMenuOpen = false;
  String _searchQuery = '';
  final List<int> _selectedGenreIds = [];
  List<Genre> _availableGenres = [];

  // ESTADO DE LA ORDENACIÓN
  SortCriterion _currentSortCriterion = SortCriterion.name;
  SortOrder _currentSortOrder = SortOrder.asc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlaylists();
      _loadLibrary();
      _loadGenres();
    });
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {
        // Al cambiar de pestaña, cerramos el menú y reseteamos el orden/filtro
        _isMenuOpen = false;
        _searchQuery = '';
        _selectedGenreIds.clear();
        _currentSortCriterion = SortCriterion.name;
        _currentSortOrder = SortOrder.asc;
      });
    }
  }

  Future<void> _loadLibrary() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await libraryProvider.loadLibrary(authProvider.currentUser!.id);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    setState(() => _isLoading = true);

    final response =
        await _playlistService.getUserPlaylists(authProvider.currentUser!.id);
    if (response.success && response.data != null) {
      _playlists = response.data!;
    }

    setState(() => _isLoading = false);
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

  List<Genre> get _filteredGenres {
    if (_searchQuery.isEmpty) {
      return _availableGenres;
    }
    final query = _searchQuery.toLowerCase();
    return _availableGenres
        .where((genre) => genre.name.toLowerCase().contains(query))
        .toList();
  }

  // =========================================================================
  // ** LÓGICA CENTRAL DE FILTRADO Y ORDENACIÓN **
  // (Adaptada para manejar Playlist y DownloadedSong en la ordenación)
  // =========================================================================

  /// Función genérica para aplicar el filtro y la ordenación.
  List<T> _applyFiltersAndSort<T>(
    List<T> items,
    String Function(T) getName,
    String Function(T) getArtist,
    DateTime? Function(T) getDate,
  ) {
    if (items.isEmpty) return [];

    // 1. Filtrar por texto de búsqueda y género
    Iterable<T> filteredItems = items.where((item) {
      final query = _searchQuery.toLowerCase();
      final name = getName(item).toLowerCase();
      final artist = getArtist(item).toLowerCase();

      final matchesQuery =
          query.isEmpty || name.contains(query) || artist.contains(query);

      if (!matchesQuery) return false;

      // Aplicar filtro por género solo a Song y Album (que tienen genreIds)
      if (_selectedGenreIds.isNotEmpty) {
        if (item is Song) {
          return _selectedGenreIds.any((requiredId) {
            return item.genreIds.contains(requiredId);
          });
        }
        if (item is Album) {
          return _selectedGenreIds.any((requiredId) {
            return item.genreIds.contains(requiredId);
          });
        }
        // Para Playlist y DownloadedSong, ignoramos el filtro de género si está activo
        return true;
      }

      return true;
    }).toList();

    // 2. Aplicar ordenación
    if (filteredItems.isNotEmpty) {
      filteredItems = filteredItems.toList()
        ..sort((a, b) {
          int comparison = 0;

          if (_currentSortCriterion == SortCriterion.name) {
            comparison =
                getName(a).toLowerCase().compareTo(getName(b).toLowerCase());
          } else if (_currentSortCriterion == SortCriterion.date) {
            final dateA = getDate(a);
            final dateB = getDate(b);

            // Manejo de fechas nulas (los nulos se van al final en ASC, al principio en DESC)
            if (dateA == null && dateB == null) {
              comparison = 0;
            } else if (dateA == null) {
              comparison = (_currentSortOrder == SortOrder.asc) ? 1 : -1;
            } else if (dateB == null) {
              comparison = (_currentSortOrder == SortOrder.asc) ? -1 : 1;
            } else {
              comparison = dateA.compareTo(dateB);
            }
          }

          // Invertir si es orden descendente
          return (_currentSortOrder == SortOrder.asc)
              ? comparison
              : -comparison;
        });
    }

    return filteredItems.toList();
  }

  // =========================================================================
  // ** FIN LÓGICA CENTRAL DE FILTRADO Y ORDENACIÓN **
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Biblioteca'),
        centerTitle: true,
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, libraryProvider, child) {
          // El diseño principal se mantiene
          return Stack(
            children: [
              Column(
                children: [
                  Material(
                    color: AppTheme.surfaceBlack,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: AppTheme.primaryBlue,
                      labelColor: AppTheme.primaryBlue,
                      unselectedLabelColor: AppTheme.textGrey,
                      tabs: const [
                        Tab(text: 'Canciones'),
                        Tab(text: 'Álbumes'),
                        Tab(text: 'Playlists'),
                        Tab(text: 'Favoritos'),
                        Tab(text: 'Descargas'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSongsTab(libraryProvider),
                        _buildAlbumsTab(libraryProvider),
                        _buildPlaylistsTab(), // Llamada al nuevo método
                        _buildFavoritesTab(libraryProvider),
                        _buildDownloadsTab(context),
                      ],
                    ),
                  ),
                ],
              ),
              // Botón de filtro (MOVIDO A LA IZQUIERDA)
              Positioned(
                bottom: 16,
                left: 16,
                child: _buildFilterToggle(context),
              ),
              // Menú avanzado de filtro (MOVIDO A LA IZQUIERDA)
              if (_isMenuOpen)
                Positioned(
                  bottom: 80, // Colocado justo encima del botón de filtro
                  left: 16,
                  child: _buildAdvancedFilterMenu(),
                ),
            ],
          );
        },
      ),
      // Floating Action Button para Playlists (se mantiene a la derecha)
      floatingActionButton:
          _tabController.index == 2 && authProvider.isAuthenticated
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final result =
                        await Navigator.pushNamed(context, '/playlist/create');
                    if (result == true) {
                      _loadPlaylists();
                    }
                  },
                  backgroundColor: AppTheme.primaryBlue,
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva Playlist'),
                )
              : null,
    );
  }

  // --- WIDGET PARA ABRIR/CERRAR EL MENÚ DE FILTRO (MOVIDO) ---
  Widget _buildFilterToggle(BuildContext context) {
    // Ya no se oculta en ninguna pestaña.

    // El criterio de ordenación ya no se incluye en "Filtros Activos"
    // ya que la ordenación es visible fuera del menú.
    final bool hasActiveFilters =
        _searchQuery.isNotEmpty || _selectedGenreIds.isNotEmpty;

    return FloatingActionButton.extended(
      onPressed: () {
        setState(() {
          _isMenuOpen = !_isMenuOpen;
        });
      },
      backgroundColor:
          hasActiveFilters ? AppTheme.errorRed : AppTheme.primaryBlue,
      icon: Icon(_isMenuOpen ? Icons.close : Icons.filter_list),
      label: Text(_isMenuOpen
          ? 'Cerrar Filtro'
          : hasActiveFilters
              ? 'Filtro Activo'
              : 'Filtros'),
    );
  }

  // --- WIDGET DEL MENÚ AVANZADO DE FILTRO (REDUCIDO) ---
  Widget _buildAdvancedFilterMenu() {
    const double menuWidth = 250;
    const double menuMaxHeight = 350;

    // Solo se permite mostrar géneros si la pestaña actual lo requiere (Canciones, Álbumes, Favoritos, Descargas)
    final int currentTabIndex = _tabController.index;
    final bool showGenres =
        currentTabIndex != 2; // Playlists (index 2) no tienen género

    return Card(
      color: AppTheme.surfaceBlack,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: menuWidth,
        constraints: BoxConstraints(
          maxHeight: showGenres ? menuMaxHeight : 150, // Altura dinámica
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BARRA DE BÚSQUEDA
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar...',
                hintStyle: TextStyle(color: AppTheme.textGrey.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.darkBlue,
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            if (showGenres) ...[
              const SizedBox(height: 12),
              const Divider(color: AppTheme.darkBlue, thickness: 1),
              const SizedBox(height: 12),

              // 2. ENCABEZADO DE GÉNEROS
              const Text(
                'Géneros (Multi-selección)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // 3. LISTA DE GÉNEROS (USANDO CHECKBOXLISTTILE)
              Flexible(
                child: _isLoadingGenres
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryBlue,
                        ),
                      )
                    : _filteredGenres.isEmpty
                        ? Center(
                            child: Text(
                              _availableGenres.isEmpty && _searchQuery.isEmpty
                                  ? 'No hay géneros disponibles.'
                                  : 'No hay resultados para "$_searchQuery"',
                              style: const TextStyle(
                                  color: AppTheme.textGrey, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredGenres.length,
                            itemBuilder: (context, index) {
                              final genre = _filteredGenres[index];
                              final isSelected =
                                  _selectedGenreIds.contains(genre.id);
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  genre.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.primaryBlue
                                        : Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                value: isSelected,
                                checkColor: Colors.white,
                                activeColor: AppTheme.primaryBlue,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedGenreIds.add(genre.id);
                                    } else {
                                      _selectedGenreIds.remove(genre.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  // --- FIN WIDGET DEL MENÚ AVANZADO DE FILTRO ---

  // --- WIDGET PARA CONTROLES DE ORDENACIÓN (MANTENIDO) ---
  Widget _buildSortControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botones de criterio (Nombre/Fecha)
              Row(
                children: [
                  _buildSortButtonCompact(
                    text: 'Nombre',
                    criterion: SortCriterion.name,
                  ),
                  const SizedBox(width: 8),
                  _buildSortButtonCompact(
                    text: 'Fecha',
                    criterion: SortCriterion.date,
                  ),
                ],
              ),
              // Botones de orden (Asc/Desc)
              Row(
                children: [
                  _buildOrderButtonCompact(
                    icon: Icons.arrow_downward,
                    text: 'Desc',
                    order: SortOrder.desc,
                  ),
                  const SizedBox(width: 8),
                  _buildOrderButtonCompact(
                    icon: Icons.arrow_upward,
                    text: 'Asc',
                    order: SortOrder.asc,
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: AppTheme.darkBlue, height: 16),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES DE ORDENACIÓN (MANTENIDOS) ---
  Widget _buildSortButtonCompact({
    required String text,
    required SortCriterion criterion,
  }) {
    final isSelected = _currentSortCriterion == criterion;
    return TextButton(
      onPressed: () {
        setState(() {
          _currentSortCriterion = criterion;
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryBlue : AppTheme.darkBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildOrderButtonCompact({
    required IconData icon,
    required String text,
    required SortOrder order,
  }) {
    final isSelected = _currentSortOrder == order;
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _currentSortOrder = order;
        });
      },
      icon: Icon(icon, size: 16),
      label: Text(text, style: const TextStyle(fontSize: 14)),
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? AppTheme.primaryBlue : AppTheme.textGrey,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.textGrey,
        ),
        backgroundColor: isSelected
            ? AppTheme.primaryBlue.withOpacity(0.2)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
  // --- FIN WIDGETS AUXILIARES DE ORDENACIÓN ---

  // --- MÉTODOS DE CONSTRUCCIÓN DE PESTAÑAS (TODOS CON ORDENACIÓN) ---

  Widget _buildSongsTab(LibraryProvider libraryProvider) {
    final filteredSongs = _applyFiltersAndSort<Song>(
      libraryProvider.purchasedSongs,
      (song) => song.name,
      (song) => song.artistName,
      (song) => song.createdAt, // Usamos createdAt
    );

    if (filteredSongs.isEmpty) {
      return _buildEmptyState('canciones', Icons.music_note);
    }

    return Column(
      children: [
        _buildSortControls(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredSongs.length,
            itemBuilder: (context, index) {
              final song = filteredSongs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note),
                  ),
                  title: Text(song.name),
                  subtitle: Text(
                    '${song.artistName} - ${song.createdAt?.year ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                  ),
                  trailing: Text(
                    '\$${song.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/song',
                      arguments: song.id,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumsTab(LibraryProvider libraryProvider) {
    final filteredAlbums = _applyFiltersAndSort<Album>(
      libraryProvider.purchasedAlbums,
      (album) => album.name,
      (album) => album.artistId.toString(),
      (album) => album.createdAt, // Usamos createdAt o releaseDate
    );

    if (filteredAlbums.isEmpty) {
      return _buildEmptyState('álbumes', Icons.album);
    }

    return Column(
      children: [
        _buildSortControls(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredAlbums.length,
            itemBuilder: (context, index) {
              final album = filteredAlbums[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.album),
                  ),
                  title: Text(album.name),
                  subtitle: Text(
                    'Artista ID: ${album.artistId} - ${album.createdAt?.year ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                  ),
                  trailing: Text(
                    '\$${album.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/album',
                      arguments: album.id,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // NUEVO MÉTODO DE CONSTRUCCIÓN DE PLAYLISTS CON ORDENACIÓN Y FILTRO
  Widget _buildPlaylistsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Aplicar filtro y ordenación a las playlists.
    // ASUMIMOS que Playlist tiene un campo 'createdAt' (fecha de creación).
    final filteredPlaylists = _applyFiltersAndSort<Playlist>(
      _playlists,
      (playlist) => playlist.name,
      (playlist) => '', // No hay "artista" para Playlists
      (playlist) => playlist.createdAt, // Usamos createdAt
    );

    if (filteredPlaylists.isEmpty && _searchQuery.isEmpty) {
      return _buildEmptyPlaylistsState(context);
    }

    if (filteredPlaylists.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptyState('playlists', Icons.playlist_play);
    }

    return Column(
      children: [
        _buildSortControls(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredPlaylists.length,
            itemBuilder: (context, index) {
              final playlist = filteredPlaylists[index];
              return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: AppTheme.surfaceBlack,
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.playlist_play, color: Colors.white),
                    ),
                    title: Text(
                      playlist.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          playlist.isPublic ? Icons.public : Icons.lock,
                          size: 12,
                          color: AppTheme.textGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${playlist.songCount} ${playlist.songCount == 1 ? "canción" : "canciones"}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textGrey,
                                  ),
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.textGrey,
                    ),
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/playlist',
                        arguments: playlist.id,
                      );
                      if (result == true) {
                        _loadPlaylists();
                      }
                    },
                  ));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab(LibraryProvider libraryProvider) {
    // La pestaña de favoritos mezcla Songs y Albums, por lo que la ordenación/filtro
    // se aplica por separado a cada sub-lista.

    final filteredFavoriteSongs = _applyFiltersAndSort<Song>(
      libraryProvider.favoriteSongs,
      (song) => song.name,
      (song) => song.artistName,
      (song) => song.createdAt, // Usamos createdAt
    );

    final filteredFavoriteAlbums = _applyFiltersAndSort<Album>(
      libraryProvider.favoriteAlbums,
      (album) => album.name,
      (album) => album.artistId.toString(),
      (album) => album.createdAt, // Usamos createdAt o releaseDate
    );

    if (filteredFavoriteSongs.isEmpty && filteredFavoriteAlbums.isEmpty) {
      return _buildEmptyState('favoritos', Icons.favorite);
    }

    return Column(
      children: [
        _buildSortControls(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (filteredFavoriteSongs.isNotEmpty) ...[
                Text(
                  'Canciones favoritas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...filteredFavoriteSongs.map((song) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.music_note),
                        ),
                        title: Text(song.name),
                        subtitle: Text(
                          '${song.artistName} - ${song.createdAt?.year ?? ''}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textGrey,
                                  ),
                        ),
                        trailing: const Icon(Icons.favorite,
                            color: AppTheme.errorRed),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/song',
                            arguments: song.id,
                          );
                        },
                      ),
                    )),
                const SizedBox(height: 24),
              ],
              if (filteredFavoriteAlbums.isNotEmpty) ...[
                Text(
                  'Álbumes favoritos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...filteredFavoriteAlbums.map((album) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.album),
                        ),
                        title: Text(album.name),
                        subtitle: Text(
                          'Artista ID: ${album.artistId} - ${album.createdAt?.year ?? ''}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textGrey,
                                  ),
                        ),
                        trailing: const Icon(Icons.favorite,
                            color: AppTheme.errorRed),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/album',
                            arguments: album.id,
                          );
                        },
                      ),
                    )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadsTab(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, child) {
        final filteredDownloads = _applyFiltersAndSort<DownloadedSong>(
          downloadProvider.downloadedSongs,
          (download) => download.songName,
          (download) => download.artistName,
          (download) => download.downloadedAt, // Usamos downloadedAt
        );

        if (filteredDownloads.isEmpty) {
          return _buildEmptyDownloadsState(
              context, _searchQuery.isNotEmpty || _selectedGenreIds.isNotEmpty);
        }

        return Column(
          children: [
            _buildSortControls(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredDownloads.length} canciones descargadas',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 14,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.downloads);
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Ver todas'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredDownloads.length,
                itemBuilder: (context, index) {
                  final download = filteredDownloads[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.download_done,
                            color: AppTheme.primaryBlue),
                      ),
                      title: Text(download.songName),
                      subtitle: Text(
                        download.artistName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textGrey,
                            ),
                      ),
                      trailing: IconButton(
                        icon:
                            const Icon(Icons.delete, color: AppTheme.errorRed),
                        onPressed: () {
                          Provider.of<DownloadProvider>(context, listen: false)
                              .deleteDownload(download.songId);
                        },
                      ),
                      onTap: () {
                        // Lógica para reproducir canción descargada
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- WIDGET DE ESTADO VACÍO PARA PLAYLISTS (Mantenido) ---
  Widget _buildEmptyPlaylistsState(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.playlist_play,
              size: 80,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay playlists',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Crea tu primera playlist y organiza\ntu música favorita',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (authProvider.isAuthenticated)
            ElevatedButton.icon(
              onPressed: () async {
                final result =
                    await Navigator.pushNamed(context, '/playlist/create');
                if (result == true) {
                  _loadPlaylists();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Playlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget genérico para estado vacío (actualizado para incluir limpieza de ordenación)
  Widget _buildEmptyState(String itemType, IconData icon) {
    final bool isFiltered =
        _searchQuery.isNotEmpty || _selectedGenreIds.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTheme.textGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'No hay $itemType que coincidan con el filtro.'
                : 'No tienes $itemType en tu biblioteca.',
            style: const TextStyle(fontSize: 18, color: AppTheme.textGrey),
            textAlign: TextAlign.center,
          ),
          if (isFiltered) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedGenreIds.clear();
                  _currentSortCriterion = SortCriterion.name;
                  _currentSortOrder = SortOrder.asc;
                  _isMenuOpen = false;
                });
              },
              child: const Text('Limpiar Filtros'),
            ),
          ]
        ],
      ),
    );
  }

  // Widget para el estado vacío de descargas (extraído de buildDownloadsTab)
  Widget _buildEmptyDownloadsState(BuildContext context, bool isFiltered) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 80,
            color: AppTheme.textGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'No hay resultados con esos filtros'
                : 'No tienes descargas',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Intenta cambiar tu búsqueda o género'
                : 'Las canciones que descargues aparecerán aquí',
            style: const TextStyle(color: AppTheme.textGrey),
          ),
          const SizedBox(height: 24),
          if (!isFiltered)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.downloads);
              },
              icon: const Icon(Icons.explore),
              label: const Text('Explorar música'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          if (isFiltered)
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedGenreIds.clear();
                  _currentSortCriterion = SortCriterion.name;
                  _currentSortOrder = SortOrder.asc;
                  _isMenuOpen = false;
                });
              },
              child: const Text('Limpiar Filtros'),
            ),
        ],
      ),
    );
  }
}
