import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        centerTitle: true,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(10),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: [
          _buildAdminCard(
            context,
            icon: Icons.music_note,
            title: 'Administrar Canciones',
            subtitle: 'Agregar, editar, eliminar canciones',
            color: AppTheme.primaryBlue,
            route: '/admin/songs',
          ).animate(delay: 0.ms).fadeIn().scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.album,
            title: 'Administrar Álbumes',
            subtitle: 'Agregar, editar, eliminar álbumes',
            color: AppTheme.darkBlue,
            route: '/admin/albums',
          )
              .animate(delay: 100.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.category,
            title: 'Administrar Géneros',
            subtitle: 'Agregar, editar, eliminar géneros',
            color: Colors.green,
            route: '/admin/genres',
          )
              .animate(delay: 200.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.people,
            title: 'Administrar Usuarios',
            subtitle: 'Ver y administrar usuarios',
            color: Colors.orange,
            route: '/admin/users',
          )
              .animate(delay: 300.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.help,
            title: 'Administrar FAQs',
            subtitle: 'Agregar, editar, eliminar preguntas frecuentes',
            color: AppTheme.primaryBlue,
            route: '/admin/faqs',
          )
              .animate(delay: 400.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.email,
            title: 'Ver Contactos',
            subtitle: 'Ver mensajes de contacto',
            color: Colors.pink,
            route: '/admin/contacts',
          )
              .animate(delay: 500.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.shopping_bag,
            title: 'Administrar Pedidos',
            subtitle: 'Ver y administrar pedidos',
            color: Colors.amber,
            route: '/admin/orders',
          )
              .animate(delay: 600.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.bar_chart,
            title: 'Estadísticas',
            subtitle: 'Ver estadísticas globales',
            color: Colors.red,
            route: '/admin/stats',
          )
              .animate(delay: 700.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.star,
            title: 'Contenido Destacado',
            subtitle: 'Administrar contenido destacado del inicio',
            color: AppTheme.darkBlue,
            route: '/admin/featured-content',
          )
              .animate(delay: 800.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
          _buildAdminCard(
            context,
            icon: Icons.admin_panel_settings,
            title: 'Historial de Moderación',
            subtitle: 'Revisar historial de moderación de contenido',
            color: Colors.indigo,
            route: '/admin/moderation-history',
          )
              .animate(delay: 900.ms)
              .fadeIn()
              .scale(begin: const Offset(0.8, 0.8)),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.7),
                color.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
