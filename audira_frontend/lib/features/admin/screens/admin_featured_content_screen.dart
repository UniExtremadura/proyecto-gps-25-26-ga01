import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/api/services/featured_content_service.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/models/featured_content.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';

/// Admin screen to manage featured content
/// GA01-156: Seleccionar/ordenar contenido destacado
/// GA01-157: Programación de destacados
class AdminFeaturedContentScreen extends StatefulWidget {
  const AdminFeaturedContentScreen({super.key});

  @override
  State<AdminFeaturedContentScreen> createState() =>
      _AdminFeaturedContentScreenState();
}

class _AdminFeaturedContentScreenState
    extends State<AdminFeaturedContentScreen> {
  final FeaturedContentService _featuredService = FeaturedContentService();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Error al cargar contenido'),
            backgroundColor: Colors.red,
          ),
        );
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

      // Update display orders
      for (int i = 0; i < _featuredContent.length; i++) {
        _featuredContent[i] = _featuredContent[i].copyWith(displayOrder: i);
      }
    });

    // Save new order to backend
    final orderData = _featuredContent
        .map((item) => {'id': item.id, 'displayOrder': item.displayOrder})
        .toList();

    final response = await _featuredService.reorderFeaturedContent(orderData);
    if (!response.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Error al reordenar'),
          backgroundColor: Colors.red,
        ),
      );
      _loadFeaturedContent(); // Reload on error
    }
  }

  Future<void> _toggleActive(FeaturedContent item) async {
    final response =
        await _featuredService.toggleActive(item.id!, !item.isActive);

    if (response.success) {
      _loadFeaturedContent();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                item.isActive ? 'Contenido desactivado' : 'Contenido activado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Error al cambiar estado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(FeaturedContent item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar "${item.contentTitle}" del destacado?'),
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

    if (confirm != true) return;

    final response = await _featuredService.deleteFeaturedContent(item.id!);

    if (response.success) {
      _loadFeaturedContent();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contenido eliminado del destacado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Error al eliminar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _AddFeaturedContentDialog(
        onAdded: _loadFeaturedContent,
      ),
    );
  }

  Future<void> _showEditDialog(FeaturedContent item) async {
    await showDialog(
      context: context,
      builder: (context) => _EditFeaturedContentDialog(
        item: item,
        onEdited: _loadFeaturedContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contenido Destacado'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeaturedContent,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _featuredContent.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_border,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay contenido destacado',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega canciones o álbumes al destacado',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _featuredContent.length,
                  onReorder: _moveItem,
                  itemBuilder: (context, index) {
                    final item = _featuredContent[index];
                    // Note: ReorderableListView requires keys at the top level
                    // Animation removed to maintain proper key positioning
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Destacado'),
      ),
    );
  }
}

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
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Número de orden
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Contenido principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título y badge de estado
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.contentTitle ?? 'Sin título',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(status: item.scheduleStatus),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Tipo y artista
                  Row(
                    children: [
                      Icon(
                        item.contentType == FeaturedContentType.song
                            ? Icons.music_note
                            : Icons.album,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${item.contentType == FeaturedContentType.song ? 'Canción' : 'Álbum'} • ${item.contentArtist ?? 'Desconocido'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Fechas programadas
                  if (item.startDate != null || item.endDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${item.startDate != null ? dateFormat.format(item.startDate!) : 'Sin inicio'} - ${item.endDate != null ? dateFormat.format(item.endDate!) : 'Sin fin'}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Botones de acción compactos
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Toggle visibility
                IconButton(
                  icon: Icon(
                    item.isActive ? Icons.visibility : Icons.visibility_off,
                    color: item.isActive ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  onPressed: onToggleActive,
                  tooltip: item.isActive ? 'Desactivar' : 'Activar',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),

                // Menú de acciones
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: const EdgeInsets.all(8),
                  tooltip: 'Más acciones',
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.blue),
                          SizedBox(width: 12),
                          Text('Editar programación'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),

                // Drag handle
                const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
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
        color = Colors.green;
        break;
      case 'Programado':
        color = Colors.orange;
        break;
      case 'Finalizado':
        color = Colors.grey;
        break;
      case 'Inactivo':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

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
    if (_selectedContentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un contenido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'contentType': _selectedType.toJson(),
      'contentId': _selectedContentId,
      'displayOrder': 999, // Backend should handle this
      if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
      if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
      'isActive': true,
    };

    final response = await _featuredService.createFeaturedContent(data);

    setState(() => _isLoading = false);

    if (response.success) {
      widget.onAdded();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contenido agregado al destacado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Error al agregar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentList = _selectedType == FeaturedContentType.song
        ? _songs.where((s) => s.published).toList()
        : _albums.where((a) => a.published).toList();

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agregar Contenido Destacado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SegmentedButton<FeaturedContentType>(
              segments: const [
                ButtonSegment(
                  value: FeaturedContentType.song,
                  label: Text('Canción'),
                  icon: Icon(Icons.music_note),
                ),
                ButtonSegment(
                  value: FeaturedContentType.album,
                  label: Text('Álbum'),
                  icon: Icon(Icons.album),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<FeaturedContentType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                  _selectedContentId = null;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecciona ${_selectedType == FeaturedContentType.song ? 'una canción' : 'un álbum'}:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RadioGroup<int>(
                          groupValue: _selectedContentId,
                          onChanged: (int? value) {
                            setState(() => _selectedContentId = value);
                          },
                          child: ListView.builder(
                            itemCount: contentList.length,
                            itemBuilder: (context, index) {
                              final item = contentList[index];
                              final id =
                                  item is Song ? item.id : (item as Album).id;
                              final name = item is Song
                                  ? item.name
                                  : (item as Album).name;
                              final artist = item is Song
                                  ? item.artistName
                                  : 'Álbum de artista';

                              return RadioListTile<int>(
                                value: id,
                                title: Text(name),
                                subtitle: Text(artist),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fecha de inicio (opcional):'),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _startDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_startDate != null
                            ? DateFormat('dd/MM/yyyy').format(_startDate!)
                            : 'Seleccionar'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fecha de fin (opcional):'),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _endDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_endDate != null
                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                            : 'Seleccionar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditFeaturedContentDialog extends StatefulWidget {
  final FeaturedContent item;
  final VoidCallback onEdited;

  const _EditFeaturedContentDialog({
    required this.item,
    required this.onEdited,
  });

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

    if (response.success) {
      widget.onEdited();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Programación actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Error al actualizar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Editar Programación',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.item.contentTitle ?? 'Sin título',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fecha de inicio:'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _startDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_startDate != null
                            ? DateFormat('dd/MM/yyyy').format(_startDate!)
                            : 'Sin fecha de inicio'),
                      ),
                    ),
                    if (_startDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _startDate = null),
                        tooltip: 'Quitar fecha',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fecha de fin:'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _endDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_endDate != null
                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                            : 'Sin fecha de fin'),
                      ),
                    ),
                    if (_endDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _endDate = null),
                        tooltip: 'Quitar fecha',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
