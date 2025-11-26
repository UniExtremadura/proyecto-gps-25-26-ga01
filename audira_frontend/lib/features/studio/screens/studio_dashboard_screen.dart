import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';

class StudioDashboardScreen extends StatelessWidget {
  const StudioDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final background = AppTheme.backgroundBlack;
    final neonAccent = AppTheme.primaryBlue;

    const textWhite = AppTheme.textWhite;
    const textGrey = AppTheme.textGrey;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.surfaceBlack, AppTheme.backgroundBlack],
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: AppTheme.textDarkGrey.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: neonAccent.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2)
                      ],
                    ),
                    child: Icon(Icons.graphic_eq, size: 40, color: neonAccent),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESTUDIO ACTIVO',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Listo para crear',
                          style: TextStyle(
                            color: textWhite,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
            const SizedBox(height: 32),
            const Text(
              'CREACIÓN',
              style: TextStyle(
                  color: textGrey,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildMainActionButton(
                      context,
                      title: 'NUEVA\nCANCIÓN',
                      icon: Icons.mic_external_on,
                      accentColor: AppTheme.primaryBlue,
                      route: '/studio/upload-song',
                      delay: 300,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMainActionButton(
                      context,
                      title: 'NUEVO\nÁLBUM',
                      icon: Icons.album_rounded,
                      accentColor: AppTheme.accentBlue,
                      route: '/studio/upload-album',
                      delay: 400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'CONTROL DE MANDO',
              style: TextStyle(
                  color: textGrey,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold),
            ).animate(delay: 500.ms).fadeIn(),
            const SizedBox(height: 16),
            _buildControlTile(
              context,
              title: 'Estadísticas y Rendimiento',
              subtitle: 'Visualizar métricas de audiencia',
              icon: Icons.bar_chart_rounded,
              iconColor: AppTheme.successGreen,
              route: '/studio/stats',
              delay: 600,
            ),
            const SizedBox(height: 12),
            _buildControlTile(
              context,
              title: 'Catálogo Musical',
              subtitle: 'Gestionar biblioteca existente',
              icon: Icons.library_music_rounded,
              iconColor: AppTheme.warningOrange,
              route: '/studio/catalog',
              delay: 700,
            ),
            const SizedBox(height: 12),
            _buildControlTile(
              context,
              title: 'Colaboraciones',
              subtitle: 'Contratos y reparto de regalías',
              icon: Icons.handshake_rounded,
              iconColor: AppTheme.lightBlue,
              route: '/studio/collaborations',
              delay: 800,
            ),
            const SizedBox(height: 12),
            _buildControlTile(
              context,
              title: 'Laboratorio de Pruebas',
              subtitle: 'Herramientas de diagnóstico',
              icon: Icons.science,
              iconColor: AppTheme.textDarkGrey,
              route: '/studio/file-demo',
              delay: 900,
              isLessProminent: true,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color accentColor,
    required String route,
    required int delay,
  }) {
    return Material(
      color: AppTheme.cardBlack,
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        splashColor: accentColor.withValues(alpha: 0.2),
        highlightColor: accentColor.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: accentColor, width: 4))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: accentColor),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: delay.ms)
        .fadeIn()
        .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  Widget _buildControlTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String route,
    required int delay,
    bool isLessProminent = false,
  }) {
    final bgColor = isLessProminent ? Colors.transparent : AppTheme.cardBlack;

    final side = isLessProminent
        ? const BorderSide(color: AppTheme.textDarkGrey)
        : BorderSide.none;

    return Material(
      color: bgColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: side,
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        splashColor: iconColor.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textDarkGrey, size: 18),
            ],
          ),
        ),
      ),
    ).animate(delay: delay.ms).fadeIn().slideX(begin: 0.1);
  }
}
