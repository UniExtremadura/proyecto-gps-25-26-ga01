import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 60.0, // Un poco más grande por defecto para lucir el diseño
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? AppTheme.primaryBlue;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize:
            MainAxisSize.min, // Ocupar solo lo necesario si está en un diálogo
        children: [
          // SPINNER CON LOGO PULSANTE
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Círculo de fondo sutil
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    value: 1, // Fijo al 100% para hacer el anillo gris
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),

                // 2. El Spinner real girando
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    strokeCap: StrokeCap.round, // Bordes redondeados
                  ),
                ),

                // 3. Icono de marca pulsando en el centro
                Icon(
                  Icons.graphic_eq_rounded,
                  color: primaryColor,
                  size: size * 0.4,
                )
                    .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      duration: 800.ms,
                      curve: Curves.easeInOut,
                    )
                    .fadeIn(duration: 400.ms),
              ],
            ),
          ),

          // MENSAJE CON EFECTO SHIMMER
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ).animate(onPlay: (controller) => controller.repeat()).shimmer(
              duration: 1500.ms,
              color: Colors.white.withValues(alpha: 0.5),
              colors: [
                Colors.white.withValues(alpha: 0.8),
                AppTheme.primaryBlue,
                Colors.white.withValues(alpha: 0.8),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
