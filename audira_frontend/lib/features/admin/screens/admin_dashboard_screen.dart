import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.backgroundBlack;
    final textHeader = AppTheme.textGrey;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceBlack,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.textDarkGrey),
                      ),
                      child: const Icon(Icons.admin_panel_settings_outlined,
                          color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SISTEMA ADMINISTRATIVO',
                          style: TextStyle(
                            color: textHeader,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Audira Core',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildWideStatCard(context),
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
            ),
            _buildSectionHeader('ENTIDADES Y COMERCIO'),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildAdminTile(
                    context,
                    title: 'Usuarios',
                    icon: Icons.people_outline,
                    color: AppTheme.primaryBlue,
                    count: 'Active',
                    route: '/admin/users',
                    delay: 200,
                  ),
                  _buildAdminTile(
                    context,
                    title: 'Pedidos',
                    icon: Icons.shopping_bag_outlined,
                    color: AppTheme.accentBlue,
                    count: 'New',
                    route: '/admin/orders',
                    delay: 250,
                  ),
                ],
              ),
            ),
            _buildSectionHeader('BASE DE DATOS MUSICAL'),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
                children: [
                  _buildCompactTile(context, 'Canciones', Icons.music_note,
                      '/admin/songs', 300),
                  _buildCompactTile(context, 'Álbumes', Icons.album_outlined,
                      '/admin/albums', 350),
                  _buildCompactTile(context, 'Géneros', Icons.category_outlined,
                      '/admin/genres', 400),
                ],
              ),
            ),
            _buildSectionHeader('SOPORTE Y SEGURIDAD'),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildListTile(
                          context,
                          'Historial de Moderación',
                          'Revisar reportes y bans',
                          Icons.gavel_outlined,
                          AppTheme.errorRed,
                          '/admin/moderation-history')
                      .animate(delay: 500.ms)
                      .fadeIn(),
                  const SizedBox(height: 10),
                  _buildListTile(
                          context,
                          'Contenido Destacado',
                          'Gestionar banner principal',
                          Icons.star_outline,
                          AppTheme.warningOrange,
                          '/admin/featured-content')
                      .animate(delay: 550.ms)
                      .fadeIn(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _buildCompactTile(context, 'FAQs',
                              Icons.help_outline, '/admin/faqs', 600)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildCompactTile(context, 'Inbox',
                              Icons.mail_outline, '/admin/contacts', 650)),
                    ],
                  )
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textDarkGrey,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildWideStatCard(BuildContext context) {
    return Material(
      color: AppTheme.cardBlack,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/admin/stats'),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "MÉTRICAS DEL SISTEMA",
                    style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Ver Dashboard",
                    style: TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tráfico, Ingresos, Usuarios Activos",
                    style: TextStyle(
                        color: AppTheme.textGrey.withValues(alpha: 0.7),
                        fontSize: 12),
                  ),
                ],
              ),
              const Icon(Icons.bar_chart,
                  color: AppTheme.primaryBlue, size: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String count,
    required String route,
    required int delay,
  }) {
    return Material(
      color: AppTheme.cardBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: Colors.transparent),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        hoverColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 3))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (count.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(count,
                          style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    )
                ],
              ),
              Text(
                title,
                style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    fontFamily: 'Poppins'),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: delay.ms).fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildCompactTile(BuildContext context, String title, IconData icon,
      String route, int delay) {
    return Material(
      color: AppTheme.cardBlack,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.textGrey, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: AppTheme.textWhite, fontSize: 12),
            )
          ],
        ),
      ),
    ).animate(delay: delay.ms).fadeIn().scale();
  }

  Widget _buildListTile(BuildContext context, String title, String subtitle,
      IconData icon, Color color, String route) {
    return Material(
      color: AppTheme.cardBlack,
      borderRadius: BorderRadius.circular(4),
      child: ListTile(
        onTap: () => Navigator.pushNamed(context, route),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins')),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: AppTheme.textDarkGrey, size: 14),
      ),
    );
  }
}
