import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Imports de tu proyecto
import '../../../config/theme.dart';
import '../../../core/models/genre.dart';

class GenreChip extends StatelessWidget {
  final Genre genre;
  final VoidCallback?
      onTap; // Opcional: Para sobreescribir la navegación si es necesario

  const GenreChip({
    super.key,
    required this.genre,
    this.onTap,
  });

  // Helper para convertir hex string (#RRGGBB) a Color
  Color _getGenreColor() {
    if (genre.color == null) return AppTheme.primaryBlue;
    try {
      return Color(int.parse(genre.color!.replaceFirst('#', '0xff')));
    } catch (e) {
      return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _getGenreColor();

    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        // Fondo sutil con el color del género
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap ??
              () {
                Navigator.pushNamed(context, '/genre', arguments: genre.id);
              },
          splashColor: baseColor.withValues(alpha: 0.2),
          highlightColor: baseColor.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono o Emoji del género
                if (genre.icon != null) ...[
                  Text(
                    genre.icon!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  Icon(
                    Icons.music_note_rounded,
                    size: 16,
                    color: baseColor,
                  ),
                  const SizedBox(width: 8),
                ],

                // Nombre del género
                Text(
                  genre.name,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().scale(
          begin: const Offset(0.9, 0.9),
          curve: Curves.easeOutBack,
          duration: 300.ms,
        );
  }
}
