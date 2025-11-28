import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. HEADER CINEMÁTICO (Sin huecos negros)
          SliverToBoxAdapter(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // A. Imagen de Fondo
                Container(
                  height: 300, // Altura ajustada
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(user.bannerImageUrl ??
                          user.profileImageUrl ??
                          'https://static.vecteezy.com/system/resources/previews/001/906/862/large_2x/black-texture-background-free-photo.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.4),
                          BlendMode.darken),
                    ),
                  ),
                ),

                // B. Gradiente de Fusión (Para unir con el fondo)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.backgroundBlack.withValues(alpha: 0.0),
                          AppTheme.backgroundBlack,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // C. Contenido del Header (Avatar y Stats)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar Glowing
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryBlue, Colors.cyanAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryBlue.withValues(alpha: 0.6),
                              blurRadius: 30,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.black,
                          backgroundImage: user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                          child: user.profileImageUrl == null
                              ? const Icon(Icons.person,
                                  size: 50, color: Colors.white)
                              : null,
                        ),
                      )
                          .animate()
                          .scale(duration: 500.ms, curve: Curves.easeOutBack),

                      const SizedBox(height: 12),

                      // Nombre y Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          if (user.verifiedArtist == true) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified,
                                color: AppTheme.primaryBlue, size: 20),
                          ],
                        ],
                      ).animate().fadeIn().slideY(begin: 0.2),

                      Text(
                        '@${user.username} • ${user.role}',
                        style: TextStyle(
                          color: AppTheme.textGrey.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Dashboard de Stats (Seguidores)
                      _buildGlassStats(user),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. REDES SOCIALES
          if (_hasSocials(user))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (user.spotifyUrl != null)
                        _buildSocialBtn(Icons.music_note,
                            const Color(0xFF1DB954), user.spotifyUrl!),
                      if (user.instagramUrl != null)
                        _buildSocialBtn(Icons.camera_alt,
                            const Color(0xFFE1306C), user.instagramUrl!),
                      if (user.twitterUrl != null)
                        _buildSocialBtn(Icons.alternate_email,
                            const Color(0xFF1DA1F2), user.twitterUrl!),
                      if (user.youtubeUrl != null)
                        _buildSocialBtn(Icons.play_arrow,
                            const Color(0xFFFF0000), user.youtubeUrl!),
                      if (user.tiktokUrl != null)
                        _buildSocialBtn(Icons.video_library,
                            const Color(0xFFFE2C55), user.tiktokUrl!),
                      if (user.facebookUrl != null)
                        _buildSocialBtn(Icons.facebook, const Color(0xFF1877F2),
                            user.facebookUrl!),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ),
            ),

          // 3. INFORMACIÓN DETALLADA Y MENÚ COMPLETO
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // INFORMACIÓN PERSONAL (Recuperada completa)
                _buildInfoSection(user),
                const SizedBox(height: 24),

                // SECCIÓN 1: ACTIVIDAD Y GESTIÓN
                _buildSectionHeader('MI ACTIVIDAD'),
                _buildActionTile(context, 'Editar Perfil', Icons.edit_outlined,
                    '/profile/edit'),
                _buildActionTile(
                    context, 'Estadísticas', Icons.bar_chart_rounded, '/stats'),
                _buildActionTile(context, 'Historial de Compras',
                    Icons.shopping_bag_outlined, '/profile/purchase-history'),
                _buildActionTile(context, 'Artistas Seguidos',
                    Icons.people_outline, '/profile/followed-artists'),

                const SizedBox(height: 20),

                // SECCIÓN 2: SOPORTE Y SEGURIDAD
                _buildSectionHeader('CUENTA Y SOPORTE'),
                _buildActionTile(context, 'Cambiar Contraseña',
                    Icons.lock_outline, '/profile/change-password'),
                _buildActionTile(context, 'Tickets de Soporte',
                    Icons.confirmation_number_outlined, '/profile/tickets'),
                // El botón de configuración que pediste mantener, con SnackBar
                _buildActionTile(
                    context, 'Configuración', Icons.settings_outlined, null,
                    onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Configuración - Próximamente')),
                  );
                }),

                const SizedBox(height: 32),

                // BOTÓN CERRAR SESIÓN (CORREGIDO AQUÍ)
                _buildLogoutButton(context, authProvider),

                const SizedBox(height: 120), // Espacio final
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  // Panel de Stats Glassmorphism
  Widget _buildGlassStats(dynamic user) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (user.isArtist) ...[
                _buildStatItem('ARTISTA', 'ROL'),
              ],
              Container(width: 1, height: 24, color: Colors.white24),
              _buildStatItem('${user.followerIds.length}', 'SEGUIDORES'),
              Container(width: 1, height: 24, color: Colors.white24),
              _buildStatItem('${user.followingIds.length}', 'SIGUIENDO')
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  // Bloque de Información (Email, Bio, Web, etc.)
  Widget _buildInfoSection(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textDarkGrey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.email_outlined, 'Email', user.email),
          if (user.bio != null) ...[
            const Divider(color: Colors.white10, height: 24),
            _buildInfoRow(Icons.short_text, 'Bio', user.bio!),
          ],
          if (user.location != null) ...[
            const Divider(color: Colors.white10, height: 24),
            _buildInfoRow(
                Icons.location_on_outlined, 'Ubicación', user.location!),
          ],
          if (user.website != null) ...[
            const Divider(color: Colors.white10, height: 24),
            _buildInfoRow(Icons.link, 'Sitio Web', user.website!, isLink: true),
          ],
          // Datos extra de Artista
          if (user.isArtist) ...[
            if (user.artistBio != null) ...[
              const Divider(color: Colors.white10, height: 24),
              _buildInfoRow(Icons.mic_none, 'Bio Artista', user.artistBio!),
            ],
            if (user.recordLabel != null) ...[
              const Divider(color: Colors.white10, height: 24),
              _buildInfoRow(Icons.album_outlined, 'Sello Discográfico',
                  user.recordLabel!),
            ],
          ],
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  // Fila de Información
  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBlue),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              InkWell(
                onTap: isLink ? () => _launchUrl(value) : null,
                child: Text(
                  value,
                  style: TextStyle(
                    color: isLink ? AppTheme.primaryBlue : Colors.white,
                    fontSize: 14,
                    height: 1.3,
                    decoration: isLink ? TextDecoration.underline : null,
                    decorationColor: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins'),
        ),
        Text(
          label,
          style: TextStyle(
              color: AppTheme.textGrey.withValues(alpha: 0.8),
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSocialBtn(IconData icon, Color color, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
              color: AppTheme.cardBlack,
              shape: BoxShape.circle,
              border:
                  Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1)
              ]),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.primaryBlue.withValues(alpha: 0.8),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildActionTile(
      BuildContext context, String title, IconData icon, String? route,
      {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.transparent), // Borde listo para hover si se necesita
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => Navigator.pushNamed(context, route!),
          borderRadius: BorderRadius.circular(12),
          splashColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBlack,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppTheme.textGrey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return InkWell(
      onTap: () async {
        // --- CORRECCIÓN CRÍTICA AQUÍ ---
        await authProvider.logout();
        if (context.mounted) {
          // Usar pushNamedAndRemoveUntil para eliminar todo el historial
          // y evitar que la pantalla de perfil intente reconstruirse sin usuario
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login', // Asegúrate de que esta ruta esté definida en tu main.dart
            (route) => false, // Elimina todas las rutas anteriores
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.errorRed.withValues(alpha: 0.1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppTheme.errorRed, size: 20),
            SizedBox(width: 8),
            Text(
              "CERRAR SESIÓN",
              style: TextStyle(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasSocials(dynamic user) {
    return user.twitterUrl != null ||
        user.instagramUrl != null ||
        user.facebookUrl != null ||
        user.youtubeUrl != null ||
        user.spotifyUrl != null ||
        user.tiktokUrl != null ||
        (user.website != null &&
            user.website!
                .isNotEmpty); // Web también cuenta si quieres mostrarla como botón
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}
