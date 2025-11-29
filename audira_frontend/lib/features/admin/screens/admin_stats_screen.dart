import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas Globales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Estadísticas actualizadas')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Stats
            const Text(
              'Resumen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Total de Usuarios', '1,234', Icons.people,
                    AppTheme.primaryBlue),
                _buildStatCard('Total de Canciones', '5,678', Icons.music_note,
                    Colors.purple),
                _buildStatCard(
                    'Total de Álbumes', '432', Icons.album, Colors.orange),
                _buildStatCard('Ingresos Totales', '\$12,345',
                    Icons.attach_money, Colors.green),
              ],
            ).animate().fadeIn(),
            const SizedBox(height: 24),

            // User Statistics
            const Text(
              'Estadísticas de Usuario',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow('Usuarios Activos', '987', Colors.green),
                    const Divider(),
                    _buildStatRow('Nuevos Usuarios (Este Mes)', '123',
                        AppTheme.primaryBlue),
                    const Divider(),
                    _buildStatRow('Artistas', '45', Colors.purple),
                    const Divider(),
                    _buildStatRow('Administradores', '5', Colors.red),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 24),

            // Content Statistics
            const Text(
              'Estadísticas de Contenido',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow('Total de Reproducciones', '45,678',
                        AppTheme.primaryBlue),
                    const Divider(),
                    _buildStatRow('Total de Descargas', '12,345', Colors.green),
                    const Divider(),
                    _buildStatRow(
                        'Listas de Reproducción Creadas', '890', Colors.orange),
                    const Divider(),
                    _buildStatRow('Comentarios', '3,456', Colors.purple),
                    const Divider(),
                    _buildStatRow('Calificaciones', '5,678', Colors.amber),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),

            // Revenue Statistics
            const Text(
              'Estadísticas de Ingresos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow('Ventas Totales', '\$12,345', Colors.green),
                    const Divider(),
                    _buildStatRow('Este Mes', '\$2,345', AppTheme.primaryBlue),
                    const Divider(),
                    _buildStatRow('Mes Pasado', '\$2,100', AppTheme.textGrey),
                    const Divider(),
                    _buildStatRow('Pedido Promedio', '\$15.67', Colors.orange),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),

            // Top Content
            const Text(
              'Contenido Destacado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildTopItem('1', 'Midnight Dreams', '1.234 reproducciones',
                      Icons.music_note),
                  const Divider(height: 1),
                  _buildTopItem('2', 'Electric Love', '1.123 reproducciones',
                      Icons.music_note),
                  const Divider(height: 1),
                  _buildTopItem(
                      '3', 'Summer Vibes', '987 reproducciones', Icons.album),
                  const Divider(height: 1),
                  _buildTopItem('4', 'Jazz Collection', '876 reproducciones',
                      Icons.album),
                  const Divider(height: 1),
                  _buildTopItem('5', 'Blue Notes', '765 reproducciones',
                      Icons.music_note),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItem(
      String rank, String title, String subtitle, IconData icon) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryBlue,
        child: Text(rank, style: const TextStyle(color: Colors.white)),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(icon, color: AppTheme.textGrey),
    );
  }
}
