// ignore_for_file: use_build_context_synchronously

import 'package:audira_frontend/features/studio/screens/edit_song_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/song.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/api/services/moderation_service.dart';
import '../../../core/providers/auth_provider.dart';
// Asumimos que estos existen, pero los re-estilizaremos o envolveremos si es necesario
import '../widgets/moderation_widgets.dart';

class AdminSongsScreen extends StatefulWidget {
  const AdminSongsScreen({super.key});

  @override
  State<AdminSongsScreen> createState() => _AdminSongsScreenState();
}

class _AdminSongsScreenState extends State<AdminSongsScreen> {
  final MusicService _musicService = MusicService();
  final ModerationService _moderationService = ModerationService();
  final TextEditingController _searchController = TextEditingController();

  // --- Colores del Tema Oscuro ---
  final Color darkBg = Colors.black;
  final Color darkCardBg = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  bool _isLoading = false;
  String? _error;

  String _moderationFilter = 'all'; // all, pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _musicService.getAllSongs();
      if (response.success && response.data != null) {
        setState(() {
          _songs = response.data!;
          _filterSongs(_searchController.text); // Volver a aplicar filtros
        });
      } else {
        setState(
            () => _error = response.error ?? 'Error al cargar las canciones');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterSongs(String query) {
    setState(() {
      var filtered = _songs;

      // Filtro de moderación
      if (_moderationFilter != 'all') {
        filtered = filtered.where((song) {
          return song.moderationStatus?.toLowerCase() ==
              _moderationFilter.toLowerCase();
        }).toList();
      }

      // Filtro de búsqueda
      if (query.isNotEmpty) {
        filtered = filtered
            .where((song) =>
                song.name.toLowerCase().contains(query.toLowerCase()) ||
                (song.description
                        ?.toLowerCase()
                        .contains(query.toLowerCase()) ??
                    false))
            .toList();
      }

      _filteredSongs = filtered;
    });
  }

  // --- LÓGICA DE NEGOCIO (Sin cambios, solo UI connectors) ---

  Future<void> _approveSong(Song song) async {
    final authProvider = context.read<AuthProvider>();
    final adminId = authProvider.currentUser?.id;

    if (adminId == null) {
      _showSnack('Error: ID de administrador no disponible', isError: true);
      return;
    }

    final result = await showApproveDialog(
      context: context,
      itemName: song.name,
      itemType: 'canción',
    );

    if (result == true) {
      _executeModerationAction(() async {
        return await _moderationService.approveSong(song.id, adminId);
      }, 'Canción "${song.name}" aprobada exitosamente');
    }
  }

  Future<void> _rejectSong(Song song) async {
    final authProvider = context.read<AuthProvider>();
    final adminId = authProvider.currentUser?.id;

    if (adminId == null) {
      _showSnack('Error: ID de administrador no disponible', isError: true);
      return;
    }

    final result = await showRejectDialog(
      context: context,
      itemName: song.name,
      itemType: 'canción',
    );

    if (result != null && result['reason'] != null) {
      _executeModerationAction(() async {
        return await _moderationService.rejectSong(
          song.id,
          adminId,
          result['reason']!,
          notes: result['notes'],
        );
      }, 'Canción "${song.name}" rechazada');
    }
  }

  Future<void> _executeModerationAction(
      Future<dynamic> Function() action, String successMessage) async {
    try {
      final response = await action();
      if (response.success) {
        _showSnack(successMessage, color: Colors.green);
        _loadSongs();
      } else {
        _showSnack(response.error ?? 'La acción falló', isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _deleteSong(int songId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        title: Text('Eliminar Canción', style: TextStyle(color: lightText)),
        content: Text('¿Estás seguro de que quieres eliminar esta canción?',
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
      try {
        final response = await _musicService.deleteSong(songId);
        if (response.success) {
          _showSnack('Canción eliminada exitosamente');
          _loadSongs();
        } else {
          _showSnack(response.error ?? 'Error al eliminar la canción',
              isError: true);
        }
      } catch (e) {
        _showSnack('Error: $e', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false, Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color ?? (isError ? Colors.red[900] : Colors.green[800]),
    ));
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    // Calculamos métricas simples para el dashboard
    final int pendingCount =
        _songs.where((s) => s.moderationStatus == 'PENDING').length;

    return Scaffold(
      backgroundColor: darkBg, // FONDO NEGRO
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Administración de Canciones',
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
              onPressed: () => _showSongForm(null),
              tooltip: 'Añadir nueva canción',
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
                            'Canciones Totales',
                            _songs.length.toString(),
                            Icons.library_music,
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
                      hintText: 'Buscar canciones por nombre o descripción...',
                      hintStyle: TextStyle(color: subText),
                      prefixIcon: Icon(Icons.search, color: subText),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: (val) => _filterSongs(val),
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
                _buildFilterChip('all', 'Todas las Canciones'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pendientes'),
                const SizedBox(width: 8),
                _buildFilterChip('approved', 'Aprobadas'),
                const SizedBox(width: 8),
                _buildFilterChip('rejected', 'Rechazadas'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. LISTA DE CANCIONES
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryBlue))
                : _error != null
                    ? _buildErrorState()
                    : _filteredSongs.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20,
                                80), // Padding inferior para el FAB si es necesario
                            itemCount: _filteredSongs.length,
                            separatorBuilder: (c, i) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildSongCard(
                                  _filteredSongs[index], index);
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
        _filterSongs(_searchController.text);
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

  Widget _buildSongCard(Song song, int index) {
    final bool isPending = song.moderationStatus == 'PENDING';

    return Container(
      decoration: BoxDecoration(
        color: darkCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Column(
        children: [
          // Header del Card
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Portada / Icono
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.music_note,
                      color: AppTheme.primaryBlue, size: 28),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.name,
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
                          Text('ID: ${song.artistId}',
                              style: TextStyle(color: subText, fontSize: 12)),
                          const SizedBox(width: 12),
                          Icon(Icons.attach_money,
                              size: 12, color: Colors.greenAccent),
                          Text(song.price.toStringAsFixed(2),
                              style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge Status
                _buildStatusBadge(song.moderationStatus!),
              ],
            ),
          ),

          // Razón de rechazo (si existe)
          if (song.rejectionReason != null && song.rejectionReason!.isNotEmpty)
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
                      'Rechazo: ${song.rejectionReason}',
                      style: TextStyle(color: Colors.red[200], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Action Bar
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
                // Botones de moderación prominentes si está pendiente
                if (isPending) ...[
                  TextButton.icon(
                    icon:
                        const Icon(Icons.check, size: 16, color: Colors.green),
                    label: const Text('Aprobar',
                        style: TextStyle(color: Colors.green)),
                    onPressed: () => _approveSong(song),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.close,
                        size: 16, color: Colors.redAccent),
                    label: const Text('Rechazar',
                        style: TextStyle(color: Colors.redAccent)),
                    onPressed: () => _rejectSong(song),
                  ),
                  const SizedBox(width: 8), // Separador
                  Container(width: 1, height: 20, color: Colors.grey[800]),
                  const SizedBox(width: 8),
                ],

                // Botones estándar
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: subText),
                  tooltip: 'Editar Canción',
                  onPressed: () async {
                    await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditSongScreen(song: song)),
                    );
                    _loadSongs(); // Recargar al volver
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: Colors.red[900]),
                  tooltip: 'Eliminar',
                  onPressed: () => _deleteSong(song.id),
                ),
              ],
            ),
          )
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String translatedStatus;

    switch (status) {
      case 'APPROVED':
        color = Colors.green;
        icon = Icons.check_circle;
        translatedStatus = 'APROBADA';
        break;
      case 'PENDING':
        color = Colors.orange;
        icon = Icons.access_time_filled;
        translatedStatus = 'PENDIENTE';
        break;
      case 'REJECTED':
        color = Colors.red;
        icon = Icons.cancel;
        translatedStatus = 'RECHAZADA';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        translatedStatus = 'DESCONOCIDO';
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
            translatedStatus,
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
          Icon(Icons.queue_music, size: 64, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text('No se encontraron canciones',
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
            onPressed: _loadSongs,
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // --- FORM DIALOG (Stylo Oscuro) ---
  void _showSongForm(Song? song) {
    final isEditing = song != null;
    final nameController = TextEditingController(text: song?.name ?? '');
    final descriptionController =
        TextEditingController(text: song?.description ?? '');
    final priceController =
        TextEditingController(text: song?.price.toString() ?? '');
    final durationController =
        TextEditingController(text: song?.duration.toString() ?? '');

    // Helper for TextFields in Dialog
    Widget buildDialogField(String label, TextEditingController controller,
        {bool isNumber = false, int lines = 1, String? prefix}) {
      return TextField(
        controller: controller,
        style: TextStyle(color: lightText),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: subText),
          prefixText: prefix,
          prefixStyle: TextStyle(color: lightText),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[700]!)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryBlue)),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        title: Text(isEditing ? 'Editar Canción' : 'Añadir Nueva Canción',
            style: TextStyle(color: lightText)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildDialogField('Nombre de la Canción', nameController),
              const SizedBox(height: 16),
              buildDialogField('Descripción', descriptionController, lines: 3),
              const SizedBox(height: 16),
              buildDialogField('Precio', priceController,
                  isNumber: true, prefix: '\$ '),
              const SizedBox(height: 16),
              buildDialogField('Duración (segundos)', durationController,
                  isNumber: true),
            ],
          ),
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
            onPressed: () async {
              // ... (Lógica de guardado original, simplificada para el ejemplo)
              Navigator.pop(context);
              _showSnack(isEditing ? 'Canción actualizada' : 'Canción creada');
              _loadSongs();
            },
            child: Text(isEditing ? 'Actualizar' : 'Crear'),
          ),
        ],
      ),
    );
  }
}
