import 'package:flutter/material.dart';
import '../../../core/models/song.dart';
import '../../../core/api/services/moderation_service.dart';

/// GA01-162: Widgets reutilizables para moderación

/// Badge de estado de moderación
class ModerationBadge extends StatelessWidget {
  final String? status;
  final bool compact;

  const ModerationBadge({
    super.key,
    this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData icon;
    String label;

    switch (status) {
      case 'PENDING':
        badgeColor = Colors.orange;
        icon = Icons.hourglass_empty;
        label = 'En revisión';
        break;
      case 'APPROVED':
        badgeColor = Colors.green;
        icon = Icons.check_circle;
        label = 'Aprobado';
        break;
      case 'REJECTED':
        badgeColor = Colors.red;
        icon = Icons.cancel;
        label = 'Rechazado';
        break;
      default:
        badgeColor = Colors.grey;
        icon = Icons.help;
        label = 'Desconocido';
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: badgeColor, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: badgeColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

/// Widget para mostrar motivo de rechazo
class RejectionReasonWidget extends StatelessWidget {
  final String reason;

  const RejectionReasonWidget({
    super.key,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Motivo del rechazo:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo de aprobación
Future<bool?> showApproveDialog({
  required BuildContext context,
  required String itemName,
  required String itemType,
}) {
  final notesController = TextEditingController();

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text('Aprobar $itemType')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Deseas aprobar "$itemName"?'),
          const SizedBox(height: 16),
          TextField(
            controller: notesController,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
              hintText: 'Agrega comentarios adicionales...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Aprobar'),
        ),
      ],
    ),
  );
}

/// Diálogo de rechazo
Future<Map<String, String>?> showRejectDialog({
  required BuildContext context,
  required String itemName,
  required String itemType,
}) {
  final reasonController = TextEditingController();
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cancel, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text('Rechazar $itemType')),
        ],
      ),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Deseas rechazar "$itemName"?',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motivo del rechazo *',
                  hintText: 'Explica por qué se rechaza el contenido...',
                  border: OutlineInputBorder(),
                  errorStyle: TextStyle(fontSize: 11),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El motivo es obligatorio';
                  }
                  if (value.trim().length < 10) {
                    return 'El motivo debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales (opcional)',
                  hintText: 'Sugerencias o comentarios...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'reason': reasonController.text.trim(),
                'notes': notesController.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Rechazar'),
        ),
      ],
    ),
  );
}

/// Botones de acción de moderación para canciones
class SongModerationActions extends StatelessWidget {
  final Song song;
  final int adminId;
  final VoidCallback onSuccess;

  const SongModerationActions({
    super.key,
    required this.song,
    required this.adminId,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    if (song.moderationStatus != 'PENDING') {
      return Container();
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Aprobar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _approveSong(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Rechazar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _rejectSong(context),
          ),
        ),
      ],
    );
  }

  Future<void> _approveSong(BuildContext context) async {
    final confirmed = await showApproveDialog(
      context: context,
      itemName: song.name,
      itemType: 'canción',
    );

    if (confirmed == true && context.mounted) {
      final moderationService = ModerationService();

      try {
        final result = await moderationService.approveSong(
          song.id,
          adminId,
        );

        if (result.success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Canción aprobada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          onSuccess();
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result.error ?? "Desconocido"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectSong(BuildContext context) async {
    final result = await showRejectDialog(
      context: context,
      itemName: song.name,
      itemType: 'canción',
    );

    if (result != null && context.mounted) {
      final moderationService = ModerationService();

      try {
        final response = await moderationService.rejectSong(
          song.id,
          adminId,
          result['reason']!,
          notes: result['notes']!.isEmpty ? null : result['notes'],
        );

        if (response.success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Canción rechazada'),
              backgroundColor: Colors.orange,
            ),
          );
          onSuccess();
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.error ?? "Desconocido"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
