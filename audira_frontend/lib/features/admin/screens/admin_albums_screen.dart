// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/album.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/api/services/moderation_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/moderation_widgets.dart';

/// GA01-162: Pantalla de administración de **Álbumes con moderación**
class AdminAlbumsScreen extends StatefulWidget {
  const AdminAlbumsScreen({super.key});

  @override
  State<AdminAlbumsScreen> createState() => _AdminAlbumsScreenState();
}

class _AdminAlbumsScreenState extends State<AdminAlbumsScreen> {
  final MusicService _musicService = MusicService();
  final ModerationService _moderationService = ModerationService();
  final TextEditingController _searchController = TextEditingController();

  // --- Colores del Tema Oscuro ---
  final Color darkBg = Colors.black;
  final Color darkCardBg = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  List<Album> _albums = [];
  List<Album> _filteredAlbums = [];
  bool _isLoading = false;
  String? _error;

  // GA01-162: Filtro de moderación
  String _moderationFilter = 'all'; // all, pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _musicService.getAllAlbums();
      if (response.success && response.data != null) {
        setState(() {
          _albums = response.data!;
          _filterAlbums(_searchController.text);
        });
      } else {
        setState(
            () => _error = response.error ?? 'Error al cargar los álbumes');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterAlbums(String query) {
    setState(() {
      var filtered = _albums;

      // GA01-162: Filtrar por estado de moderación
      if (_moderationFilter != 'all') {
        filtered = filtered.where((album) {
          return album.moderationStatus?.toLowerCase() ==
              _moderationFilter.toLowerCase();
        }).toList();
      }

      // Filtrar por búsqueda
      if (query.isNotEmpty) {
        filtered = filtered
            .where((album) =>
                album.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }

      _filteredAlbums = filtered;
    });
  }

  // --- LÓGICA DE NEGOCIO (Con wrappers para Feedback visual) ---

  Future<void> _approveAlbum(Album album) async {
    final currentContext = context;
    final authProvider = context.read<AuthProvider>();
    final adminId = authProvider.currentUser?.id;

    if (adminId == null) {
      _showSnack('Error: ID de administrador no disponible', isError: true);
      return;
    }

    // 1. Verificar canciones del álbum
    final shouldProceed = await _showAlbumSongsDialog(album);
    if (shouldProceed != true) return;

    if (!currentContext.mounted) return;

    // 2. Diálogo de confirmación final
    final result = await showApproveDialog(
      context: currentContext,
      itemName: album.name,
      itemType: 'Álbum',
    );

    if (result == true) {
      _executeModerationAction(() async {
        return await _moderationService.approveAlbum(album.id, adminId);
      }, 'Álbum "${album.name}" aprobado exitosamente');
    }
  }

  Future<void> _rejectAlbum(Album album) async {
    final authProvider = context.read<AuthProvider>();
    final adminId = authProvider.currentUser?.id;

    if (adminId == null) {
      _showSnack('Error: ID de administrador no disponible', isError: true);
      return;
    }

    final result = await showRejectDialog(
      context: context,
      itemName: album.name,
      itemType: 'Álbum',
    );

    if (result != null && result['reason'] != null) {
      _executeModerationAction(() async {
        return await _moderationService.rejectAlbum(
          album.id,
          adminId,
          result['reason']!,
          notes: result['notes'],
        );
      }, 'Álbum "${album.name}" rechazado');
    }
  }

  Future<void> _executeModerationAction(
      Future<dynamic> Function() action, String successMessage) async {
    try {
      final response = await action();
      if (response.success) {
        _showSnack(successMessage, color: Colors.green);
        _loadAlbums();
      } else {
        _showSnack(response.error ?? 'La acción falló', isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _deleteAlbum(int albumId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        title: Text('Eliminar Álbum', style: TextStyle(color: lightText)),
        content: Text('¿Estás seguro de que quieres eliminar este álbum?',
            style: TextStyle(color: subText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _musicService.deleteAlbum(albumId);
        if (response.success) {
          _showSnack('Álbum eliminado exitosamente');
          _loadAlbums();
        } else {
          _showSnack(response.error ?? 'Error al eliminar el álbum',
              isError: true);
        }
      } catch (e) {
        _showSnack('Error: $e', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false, Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? (isError ? Colors.red[900] : Colors.green[800]),
    ));
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    // Stats calc
    final int pendingCount =
        _albums.where((a) => a.moderationStatus == 'PENDING').length;

    return Scaffold(
      backgroundColor: darkBg, // FONDO NEGRO
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Administrar Álbumes',
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
              tooltip: 'Añadir nuevo álbum',
              onPressed: () {
                _showAlbumForm(null);
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. STATS & SEARCH HEADER
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            color: darkBg,
            child: Column(
              children: [
                // Stats Row
                Row(
                  children: [
                    Expanded(
                        child: _buildMiniStat(
                            'Total de Álbumes',
                            _albums.length.toString(),
                            Icons.album,
                            Colors.blueGrey)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildMiniStat(
                            'Pendientes de Revisión',
                            pendingCount.toString(),
                            Icons.rate_review,
                            Colors.orange)),
                  ],
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
                      hintText: 'Buscar álbumes...',
                      hintStyle: TextStyle(color: subText),
                      prefixIcon: Icon(Icons.search, color: subText),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: (val) => _filterAlbums(val),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: -0.2, end: 0, duration: 300.ms),

          // 2. FILTROS (CHIPS)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('all', 'Todos los Álbumes'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pendientes'),
                const SizedBox(width: 8),
                _buildFilterChip('approved', 'Aprobados'),
                const SizedBox(width: 8),
                _buildFilterChip('rejected', 'Rechazados'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. LISTA DE ÁLBUMES
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryBlue))
                : _error != null
                    ? _buildErrorState()
                    : _filteredAlbums.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                            itemCount: _filteredAlbums.length,
                            separatorBuilder: (c, i) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildAlbumCard(
                                  _filteredAlbums[index], index);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildMiniStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: darkCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          // 1. Usamos Expanded para restringir el ancho de la columna
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  // 2. Agregamos estas dos propiedades
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: lightText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  // 2. Lo mismo para el label si quieres que también tenga ...
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(color: subText, fontSize: 11),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _moderationFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _moderationFilter = value);
        _filterAlbums(_searchController.text);
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey[800]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : subText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumCard(Album album, int index) {
    final bool isPending = album.moderationStatus == 'PENDING';

    return Container(
      decoration: BoxDecoration(
        color: darkCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono Album (Placeholder)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.album,
                      color: Colors.deepPurpleAccent, size: 28),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        style: TextStyle(
                            color: lightText,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 12, color: subText),
                          const SizedBox(width: 4),
                          Text('ID: ${album.artistId}',
                              style: TextStyle(color: subText, fontSize: 12)),
                          const SizedBox(width: 12),
                          Icon(Icons.attach_money,
                              size: 12, color: Colors.greenAccent),
                          Text(album.price.toStringAsFixed(2),
                              style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge
                _buildStatusBadge(album.moderationStatus!),
              ],
            ),
          ),

          // Rejected Reason
          if (album.rejectionReason != null &&
              album.rejectionReason!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rechazo: ${album.rejectionReason}',
                      style: TextStyle(color: Colors.red[200], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPending) ...[
                  TextButton.icon(
                    icon:
                        const Icon(Icons.check, size: 16, color: Colors.green),
                    label: const Text('Aprobar',
                        style: TextStyle(color: Colors.green)),
                    onPressed: () => _approveAlbum(album),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.close,
                        size: 16, color: Colors.redAccent),
                    label: const Text('Rechazar',
                        style: TextStyle(color: Colors.redAccent)),
                    onPressed: () => _rejectAlbum(album),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 20, color: Colors.grey[800]),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: subText),
                  tooltip: 'Editar Álbum',
                  onPressed: () {
                    _showAlbumForm(album);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: Colors.red[900]),
                  tooltip: 'Eliminar',
                  onPressed: () => _deleteAlbum(album.id),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'APPROVED':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'PENDING':
        color = Colors.orange;
        icon = Icons.access_time_filled;
        break;
      case 'REJECTED':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.album_outlined, size: 64, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text('No se encontraron álbumes',
              style: TextStyle(color: subText, fontSize: 16)),
        ],
      ),
    );
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
            onPressed: _loadAlbums,
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // --- DIALOGS (Styled) ---

  // Mostrar diálogo con las canciones del Album y su estado de moderación
  Future<bool?> _showAlbumSongsDialog(Album album) async {
    final songsResponse = await _musicService.getSongsByAlbum(album.id);

    if (!songsResponse.success || songsResponse.data == null) {
      _showSnack('Error al cargar las canciones: ${songsResponse.error}',
          isError: true);
      return false;
    }

    final songs = songsResponse.data!;
    if (songs.isEmpty) {
      _showSnack('Este álbum no tiene canciones', color: Colors.orange);
      return false;
    }

    final unapprovedSongs =
        songs.where((song) => song.moderationStatus != 'APPROVED').toList();

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        title: Text('Revisar Canciones del Álbum',
            style: TextStyle(color: lightText)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Canciones totales: ${songs.length}',
                style: TextStyle(fontWeight: FontWeight.bold, color: subText),
              ),
              const SizedBox(height: 12),
              if (unapprovedSongs.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Canciones no aprobadas: ${unapprovedSongs.length}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Todas las canciones deben ser aprobadas antes de que el álbum pueda ser aprobado.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orangeAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Divider(color: Colors.grey),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    final isApproved = song.moderationStatus == 'APPROVED';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isApproved ? Icons.check_circle : Icons.pending,
                        color: isApproved ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      title:
                          Text(song.name, style: TextStyle(color: lightText)),
                      subtitle: Text(
                        song.moderationStatus ?? 'PENDIENTE',
                        style: TextStyle(
                          color: isApproved ? Colors.green : Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                      dense: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          if (unapprovedSongs.isEmpty)
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white),
              child: const Text('Continuar a Aprobar'),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, false);
                _showSnack(
                    'No se puede aprobar hasta que todas las canciones estén aprobadas',
                    color: Colors.orange);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white38),
              child: const Text('Cerrar'),
            ),
        ],
      ),
    );
  }

  void _showAlbumForm(Album? album) {
    final isEditing = album != null;
    final titleController = TextEditingController(text: album?.name ?? '');
    final priceController =
        TextEditingController(text: album?.price.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        title: Text(isEditing ? 'Editar Álbum' : 'Añadir Nuevo Álbum',
            style: TextStyle(color: lightText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: TextStyle(color: lightText),
              decoration: InputDecoration(
                labelText: 'Título del Álbum',
                labelStyle: TextStyle(color: subText),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryBlue)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              style: TextStyle(color: lightText),
              decoration: InputDecoration(
                labelText: 'Precio',
                labelStyle: TextStyle(color: subText),
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: lightText),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryBlue)),
              ),
              keyboardType: TextInputType.number,
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
              // ... Lógica de guardado simplificada ...
              Navigator.pop(context);
              _showSnack(isEditing ? 'Álbum actualizado' : 'Álbum creado');
              _loadAlbums();
            },
            child: Text(isEditing ? 'Actualizar' : 'Crear'),
          ),
        ],
      ),
    );
  }
}
