import 'package:flutter/material.dart';
import 'package:audira_frontend/core/models/rating.dart';
import 'package:audira_frontend/features/rating/widgets/rating_stars.dart';
import 'package:audira_frontend/features/rating/widgets/rating_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Widget para mostrar una lista de valoraciones
class RatingList extends StatelessWidget {
  final List<Rating> ratings;
  final int? currentUserId;
  final VoidCallback? onRatingChanged;

  const RatingList({
    super.key,
    required this.ratings,
    this.currentUserId,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No hay valoraciones aún',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ratings.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final rating = ratings[index];
        final isOwnRating = currentUserId != null && rating.userId == currentUserId;

        return RatingCard(
          rating: rating,
          isOwnRating: isOwnRating,
          onEdit: isOwnRating && onRatingChanged != null
              ? () => _editRating(context, rating)
              : null,
        );
      },
    );
  }

  Future<void> _editRating(BuildContext context, Rating rating) async {
    final result = await showRatingDialog(
      context,
      entityType: rating.entityType,
      entityId: rating.entityId,
      existingRating: rating,
    );

    if (result == true && onRatingChanged != null) {
      onRatingChanged!();
    }
  }
}

/// Widget para mostrar una tarjeta de valoración individual
class RatingCard extends StatelessWidget {
  final Rating rating;
  final bool isOwnRating;
  final VoidCallback? onEdit;

  const RatingCard({
    super.key,
    required this.rating,
    this.isOwnRating = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con usuario y estrellas
            Row(
              children: [
                // Avatar del usuario
                CircleAvatar(
                  radius: 20,
                  backgroundImage: rating.userProfileImageUrl != null
                      ? NetworkImage(rating.userProfileImageUrl!)
                      : null,
                  child: rating.userProfileImageUrl == null
                      ? Text(
                          rating.userName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 18),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Nombre y estrellas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            rating.userName ?? 'Usuario',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (isOwnRating) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Tú',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // AQUI: Asegúrate que tu modelo Rating usa 'rating' o 'ratingValue'
                      RatingStars(
                        rating: rating.rating, 
                        size: 16,
                      ),
                    ],
                  ),
                ),

                // Botón editar si es mi valoración
                if (isOwnRating && onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Editar valoración',
                  ),
              ],
            ),

            // Comentario si existe
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                rating.comment!,
                style: const TextStyle(fontSize: 14),
              ),
            ],

            // Indicador si fue editada
            Builder(
              builder: (context) {
                // 1. Calcular si está editado
                // Usamos una tolerancia de 1 segundo por si acaso, o igualdad estricta si confías en el backend
                bool isEdited = false;
                if (rating.updatedAt != null && rating.createdAt != null) {
                  final difference = rating.updatedAt!.difference(rating.createdAt!).inSeconds.abs();
                  isEdited = difference > 5; 
                }

                // 2. Elegir fecha
                final displayDate = isEdited ? rating.updatedAt : rating.createdAt;

                // 3. Retornar SIEMPRE un widget
                return Row(
                  children: [
                    Text(
                      _formatDate(displayDate),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (isEdited) ...[
                      const SizedBox(width: 4),
                      const Text(
                        '(Editado)',
                        style: TextStyle(
                          fontSize: 11, 
                          color: Colors.grey, 
                          fontStyle: FontStyle.italic
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Hace un momento';

    // 1. Convertir a hora local del móvil
    final localDate = date.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDate);

    // Si tiene más de 7 días, mostramos fecha exacta
    if (difference.inDays > 7) {
      return '${localDate.day}/${localDate.month}/${localDate.year}';
    }

    // Si es reciente, usamos timeago
    try {
      return timeago.format(localDate, locale: 'es');
    } catch (e) {
      // Fallback si no hay locale español cargado
      return timeago.format(localDate);
    }
  }
}