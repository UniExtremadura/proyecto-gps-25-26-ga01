import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/api/services/featured_content_service.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/models/featured_content.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';

class AdminFeaturedContentScreen extends StatefulWidget {
  const AdminFeaturedContentScreen({super.key});

  @override
  State<AdminFeaturedContentScreen> createState() =>
      _AdminFeaturedContentScreenState();
}

class _AdminFeaturedContentScreenState
    extends State<AdminFeaturedContentScreen> {
  final FeaturedContentService _featuredService = FeaturedContentService();

  // --- Colores del Tema Oscuro ---
  final Color darkBg = Colors.black;
  final Color darkCardBg = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  List<FeaturedContent> _featuredContent = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedContent();
  }

  Future<void> _loadFeaturedContent() async {
    setState(() => _isLoading = true);

    final response = await _featuredService.getAllFeaturedContent();
    if (response.success && response.data != null) {
      setState(() {
        _featuredContent = response.data!;
        _featuredContent
            .sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      });
    } else {
      if (mounted) {
        _showSnack(response.error ?? 'Error cargando contenido', isError: true);
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _moveItem(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = _featuredContent.removeAt(oldIndex);
      _featuredContent.insert(newIndex, item);

      // Update display orders locally
      for (int i = 0; i < _featuredContent.length; i++) {
        _featuredContent[i] = _featuredContent[i].copyWith(displayOrder: i);
      }
    });

    // Save to backend
    final orderData = _featuredContent
        .map((item) => {'id': item.id, 'displayOrder': item.displayOrder})
        .toList();

    final response = await _featuredService.reorderFeaturedContent(orderData);
    if (!response.success && mounted) {
      _showSnack(response.error ?? 'Error reordenando', isError: true);
      _loadFeaturedContent(); // Revert on error
    }
  }

  Future<void> _toggleActive(FeaturedContent item) async {
    final response =
        await _featuredService.toggleActive(item.id!, !item.isActive);

    if (response.success) {
      _loadFeaturedContent();
      if (mounted) {
        _showSnack(
            item.isActive ? 'Contenido desactivado' : 'Contenido activado');
      }
    } else {
      if (mounted) {
        _showSnack(response.error ?? 'Error cambiando estado', isError: true);
      }
    }
  }

  Future<void> _deleteItem(FeaturedContent item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        title: Text('Confirmar borrado', style: TextStyle(color: lightText)),
        content: Text('¿Borrar "${item.contentTitle}" de destacados?',
            style: TextStyle(color: subText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await _featuredService.deleteFeaturedContent(item.id!);

    if (response.success) {
      _loadFeaturedContent();
      if (mounted) _showSnack('Contenido eliminado de destacados');
    } else {
      if (mounted) {
        _showSnack(response.error ?? 'Error borrando', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[900] : Colors.green[800],
    ));
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text('Contenido destacado',
            style: TextStyle(
                color: AppTheme.primaryBlue, fontWeight: FontWeight.w800)),
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: AppTheme.primaryBlue),
              onPressed: () => _showAddDialog(),
              tooltip: 'Añadir nuevo destacado',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            color: darkBg,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: subText, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Arrastra y suelta para reodenar el carrusel.',
                    style: TextStyle(color: subText, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryBlue))
                : _featuredContent.isEmpty
                    ? _buildEmptyState()
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: _featuredContent.length,
                        onReorder: _moveItem,
                        proxyDecorator: (child, index, animation) {
                          // Estilo cuando se está arrastrando
                          return Material(
                            color: Colors.transparent,
                            elevation: 5,
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final item = _featuredContent[index];
                          return _FeaturedContentCard(
                            key: ValueKey(item.id),
                            item: item,
                            index: index,
                            onToggleActive: () => _toggleActive(item),
                            onEdit: () => _showEditDialog(item),
                            onDelete: () => _deleteItem(item),
                          );
                        },
                      ),
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
          Icon(Icons.star_border, size: 64, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text('Sin contenido destacado',
              style: TextStyle(color: subText, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Añadir nuevo destacado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  // --- DIALOGS (Wrappers) ---
  Future<void> _showAddDialog() async {
    await showDialog(
      context: context,
      builder: (context) =>
          _AddFeaturedContentDialog(onAdded: _loadFeaturedContent),
    );
  }

  Future<void> _showEditDialog(FeaturedContent item) async {
    await showDialog(
      context: context,
      builder: (context) => _EditFeaturedContentDialog(
          item: item, onEdited: _loadFeaturedContent),
    );
  }
}

// --- WIDGETS INTERNOS ---

class _FeaturedContentCard extends StatelessWidget {
  final FeaturedContent item;
  final int index;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FeaturedContentCard({
    super.key,
    required this.item,
    required this.index,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd');
    final isSong = item.contentType == FeaturedContentType.song;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Drag Handle
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_indicator, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSong
                    ? Colors.purple.withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSong ? Icons.music_note : Icons.album,
                color: isSong ? Colors.purpleAccent : Colors.orangeAccent,
              ),
            ),
          ],
        ),
        // Content Info
        title: Text(
          item.contentTitle ?? 'Untitled',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.contentArtist ?? 'Unknown Artist',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _StatusChip(status: item.scheduleStatus),
                if (item.startDate != null || item.endDate != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.calendar_today, size: 10, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  // CAMBIO AQUÍ: Envuelto en Expanded para evitar overflow
                  Expanded(
                    child: Text(
                      '${item.startDate != null ? dateFormat.format(item.startDate!) : 'Now'} - ${item.endDate != null ? dateFormat.format(item.endDate!) : 'Forever'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      overflow: TextOverflow
                          .ellipsis, // Corta con "..." si es muy largo
                      maxLines: 1,
                    ),
                  ),
                ]
              ],
            )
          ],
        ),
        // Actions
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                item.isActive ? Icons.visibility : Icons.visibility_off,
                color: item.isActive ? Colors.greenAccent : Colors.grey,
                size: 20,
              ),
              onPressed: onToggleActive,
              tooltip: 'Toggle Visibility',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              color: const Color(0xFF303030),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                    SizedBox(width: 12),
                    Text('Editar agenda', style: TextStyle(color: Colors.white))
                  ]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete, size: 18, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Text('Eliminar', style: TextStyle(color: Colors.white))
                  ]),
                ),
              ],
              onSelected: (val) {
                if (val == 'edit') onEdit();
                if (val == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(); // Simple fade in, avoid slide due to reorderable
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Activo':
        color = Colors.greenAccent;
        break;
      case 'Programado':
        color = Colors.orangeAccent;
        break;
      case 'Finalizado':
        color = Colors.grey;
        break;
      case 'Inactivo':
        color = Colors.redAccent;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// --- ADD / EDIT DIALOGS (DARK MODE ADAPTED) ---

class _AddFeaturedContentDialog extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddFeaturedContentDialog({required this.onAdded});

  @override
  State<_AddFeaturedContentDialog> createState() =>
      _AddFeaturedContentDialogState();
}

class _AddFeaturedContentDialogState extends State<_AddFeaturedContentDialog> {
  final FeaturedContentService _featuredService = FeaturedContentService();
  final MusicService _musicService = MusicService();

  FeaturedContentType _selectedType = FeaturedContentType.song;
  List<Song> _songs = [];
  List<Album> _albums = [];
  int? _selectedContentId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    final songsResponse = await _musicService.getAllSongs();
    final albumsResponse = await _musicService.getAllAlbums();

    if (songsResponse.success && songsResponse.data != null) {
      _songs = songsResponse.data!;
    }
    if (albumsResponse.success && albumsResponse.data != null) {
      _albums = albumsResponse.data!;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (_selectedContentId == null) return;
    setState(() => _isLoading = true);

    final data = {
      'contentType': _selectedType.toJson(),
      'contentId': _selectedContentId,
      'displayOrder': 999,
      if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
      if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
      'isActive': true,
    };

    final response = await _featuredService.createFeaturedContent(data);
    setState(() => _isLoading = false);

    if (response.success && mounted) {
      widget.onAdded();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentList = _selectedType == FeaturedContentType.song
        ? _songs.where((s) => s.published).toList()
        : _albums.where((a) => a.published).toList();

    return AlertDialog(
      backgroundColor: const Color(0xFF212121),
      title: const Text('Añadir contenido destacado',
          style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 400,
        height: 500, // Fixed height for list
        child: Column(
          children: [
            // Segmented Control (Custom implementation for Dark Mode look)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() {
                      _selectedType = FeaturedContentType.song;
                      _selectedContentId = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedType == FeaturedContentType.song
                            ? AppTheme.primaryBlue
                            : Colors.black,
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(8)),
                      ),
                      alignment: Alignment.center,
                      child: Text('Canción',
                          style: TextStyle(
                              color: _selectedType == FeaturedContentType.song
                                  ? Colors.white
                                  : Colors.grey)),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() {
                      _selectedType = FeaturedContentType.album;
                      _selectedContentId = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedType == FeaturedContentType.album
                            ? AppTheme.primaryBlue
                            : Colors.black,
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(8)),
                      ),
                      alignment: Alignment.center,
                      child: Text('Álbum',
                          style: TextStyle(
                              color: _selectedType == FeaturedContentType.album
                                  ? Colors.white
                                  : Colors.grey)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // List Selection
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[800]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        itemCount: contentList.length,
                        separatorBuilder: (c, i) =>
                            Divider(height: 1, color: Colors.grey[850]),
                        itemBuilder: (context, index) {
                          final item = contentList[index];
                          final id =
                              item is Song ? item.id : (item as Album).id;
                          final name =
                              item is Song ? item.name : (item as Album).name;
                          final artist =
                              item is Song ? item.artistName : 'Artist Album';
                          final isSelected = _selectedContentId == id;

                          return ListTile(
                            tileColor: isSelected
                                ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                                : null,
                            title: Text(name,
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(artist,
                                style: TextStyle(color: Colors.grey[500])),
                            trailing: isSelected
                                ? const Icon(Icons.check,
                                    color: AppTheme.primaryBlue)
                                : null,
                            onTap: () =>
                                setState(() => _selectedContentId = id),
                          );
                        },
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Date Pickers
            Row(
              children: [
                Expanded(
                    child: _buildDateButton('Start', _startDate,
                        (d) => setState(() => _startDate = d))),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildDateButton(
                        'End', _endDate, (d) => setState(() => _endDate = d))),
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancelar')),
        ElevatedButton(
          onPressed: _selectedContentId != null && !_isLoading ? _save : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white),
          child: const Text('Añadir'),
        )
      ],
    );
  }

  Widget _buildDateButton(
      String label, DateTime? date, Function(DateTime?) onSelect) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (context, child) {
              return Theme(data: ThemeData.dark(), child: child!);
            });
        if (d != null) onSelect(d);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date != null ? DateFormat('MM/dd').format(date) : '-',
                    style: const TextStyle(color: Colors.white)),
                if (date != null)
                  InkWell(
                      onTap: () => onSelect(null),
                      child:
                          const Icon(Icons.close, size: 14, color: Colors.grey))
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _EditFeaturedContentDialog extends StatefulWidget {
  final FeaturedContent item;
  final VoidCallback onEdited;
  const _EditFeaturedContentDialog(
      {required this.item, required this.onEdited});

  @override
  State<_EditFeaturedContentDialog> createState() =>
      _EditFeaturedContentDialogState();
}

class _EditFeaturedContentDialogState
    extends State<_EditFeaturedContentDialog> {
  final FeaturedContentService _featuredService = FeaturedContentService();
  late DateTime? _startDate;
  late DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.item.startDate;
    _endDate = widget.item.endDate;
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final data = {
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
    };
    final response =
        await _featuredService.updateFeaturedContent(widget.item.id!, data);
    setState(() => _isLoading = false);

    if (response.success && mounted) {
      widget.onEdited();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF212121),
      title:
          const Text('Cambiar agenda', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.item.contentTitle ?? '',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildDateButton('Start Date', _startDate,
                      (d) => setState(() => _startDate = d))),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildDateButton('End Date', _endDate,
                      (d) => setState(() => _endDate = d))),
            ],
          )
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: !_isLoading ? _save : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white),
          child: const Text('Guardar'),
        )
      ],
    );
  }

  Widget _buildDateButton(
      String label, DateTime? date, Function(DateTime?) onSelect) {
    // Reused logic for brevity, ideally extract to widget file
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (context, child) =>
                Theme(data: ThemeData.dark(), child: child!));
        if (d != null) onSelect(d);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    date != null
                        ? DateFormat('MM/dd/yyyy').format(date)
                        : 'None',
                    style: const TextStyle(color: Colors.white)),
                if (date != null)
                  InkWell(
                      onTap: () => onSelect(null),
                      child:
                          const Icon(Icons.close, size: 14, color: Colors.grey))
              ],
            )
          ],
        ),
      ),
    );
  }
}
