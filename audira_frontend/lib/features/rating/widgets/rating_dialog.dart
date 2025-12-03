import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audira_frontend/config/theme.dart';
import 'package:audira_frontend/core/models/rating.dart';
import 'package:audira_frontend/core/api/services/rating_service.dart';

/// Función helper para mostrar el diálogo remodelado
Future<bool?> showRatingDialog(
  BuildContext context, {
  required String entityType,
  required int entityId,
  Rating? existingRating,
  String? entityName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RatingBottomSheet(
      entityType: entityType,
      entityId: entityId,
      existingRating: existingRating,
      entityName: entityName,
    ),
  );
}

class RatingBottomSheet extends StatefulWidget {
  final String entityType;
  final int entityId;
  final Rating? existingRating;
  final String? entityName;

  const RatingBottomSheet({
    super.key,
    required this.entityType,
    required this.entityId,
    this.existingRating,
    this.entityName,
  });

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  final _commentController = TextEditingController();
  final _ratingService = RatingService();

  int _selectedRating = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRating != null) {
      _selectedRating = widget.existingRating!.rating;
      _commentController.text = widget.existingRating!.comment ?? '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE NEGOCIO ---

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      _showFeedback('Por favor selecciona una valoración', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final comment = _commentController.text.trim();
      final isUpdate = widget.existingRating != null;

      final response = isUpdate
          ? await _ratingService.updateRating(
              ratingId: widget.existingRating!.id,
              rating: _selectedRating,
              comment: comment.isEmpty ? null : comment,
            )
          : await _ratingService.createRating(
              entityType: widget.entityType,
              entityId: widget.entityId,
              rating: _selectedRating,
              comment: comment.isEmpty ? null : comment,
            );

      if (mounted) {
        if (response.success) {
          Navigator.of(context).pop(true);
          _showFeedback(
              isUpdate ? 'Valoración actualizada' : 'Valoración publicada');
        } else {
          _showFeedback(response.error ?? 'Error en la operación',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showFeedback('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRating() async {
    if (widget.existingRating == null) return;

    // Confirmación integrada
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        title: const Text('¿Eliminar reseña?',
            style: TextStyle(color: Colors.white)),
        content: const Text('Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final response =
          await _ratingService.deleteRating(widget.existingRating!.id);
      if (mounted) {
        if (response.success) {
          Navigator.of(context).pop(true);
          _showFeedback('Valoración eliminada');
        } else {
          _showFeedback(response.error ?? 'Error al eliminar', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showFeedback('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    // Calculamos el espacio del teclado para que no tape el botón
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Fondo oscuro premium
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER (Drag Handle & Title)
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.existingRating != null
                          ? 'Editar Reseña'
                          : 'Valorar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.entityName != null)
                      Text(
                        widget.entityName!,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (widget.existingRating != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.errorRed),
                  onPressed: _isLoading ? null : _deleteRating,
                  tooltip: 'Eliminar reseña',
                ),
            ],
          ),

          const SizedBox(height: 24),

          // ESTRELLAS INTERACTIVAS
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final isSelected = starValue <= _selectedRating;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedRating = starValue);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedScale(
                      scale: isSelected ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isSelected ? Colors.amber : Colors.grey[700],
                        size: 40,
                      ).animate(target: isSelected ? 1 : 0).shake(
                          hz: 4,
                          curve: Curves.easeInOutCubic,
                          duration: 200.ms), // Efecto sutil al seleccionar
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingLabel(_selectedRating),
              style: const TextStyle(
                  color: Colors.amber, fontWeight: FontWeight.bold),
            ).animate(key: ValueKey(_selectedRating)).fadeIn(),
          ),

          const SizedBox(height: 24),

          // CAMPO DE COMENTARIO
          TextField(
            controller: _commentController,
            maxLength: 500,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Cuéntanos qué te pareció... (Opcional)',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
              counterStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            ),
            onChanged: (_) =>
                setState(() {}), // Para actualizar contador y validaciones
          ),

          const SizedBox(height: 24),

          // BOTONES DE ACCIÓN
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_selectedRating > 0 && !_isLoading)
                        ? _submitRating
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      disabledBackgroundColor:
                          AppTheme.primaryBlue.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            widget.existingRating != null
                                ? 'Actualizar'
                                : 'Publicar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Malo';
      case 2:
        return 'Regular';
      case 3:
        return 'Bueno';
      case 4:
        return 'Muy bueno';
      case 5:
        return '¡Excelente!';
      default:
        return 'Toca las estrellas para valorar';
    }
  }
}
