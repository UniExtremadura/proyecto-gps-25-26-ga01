import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  // Definimos colores base para el modo oscuro para mantener la consistencia
  final Color darkCardBg =
      const Color(0xFF212121); // Gris muy oscuro para tarjetas
  final Color darkBg = Colors.black; // Fondo negro puro
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg, // FONDO NEGRO
      appBar: AppBar(
        backgroundColor: darkBg, // AppBar negra para fundirse con el fondo
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Global Statistics',
          style: TextStyle(
              color: AppTheme.primaryBlue, fontWeight: FontWeight.w800),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
                // Usamos un gris oscuro para el botón en vez del azul claro anterior
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!)),
            child: IconButton(
              icon: Icon(Icons.refresh, color: AppTheme.primaryBlue),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Statistics refreshed')),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. GRID DE RESUMEN
            _buildSectionTitle('Overview'),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildModernStatCard('Total Users', '1,234', Icons.people,
                    AppTheme.primaryBlue, '+12%'),
                _buildModernStatCard('Total Songs', '5,678', Icons.music_note,
                    Colors.purple, '+5%'),
                _buildModernStatCard(
                    'Total Albums', '432', Icons.album, Colors.orange, '+2%'),
                _buildModernStatCard('Revenue', '\$12k', Icons.attach_money,
                    Colors.green, '+18%'),
              ],
            ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn(),

            const SizedBox(height: 30),

            // 2. SECCIÓN DE REVENUE DESTACADA
            // Esta sección mantiene el azul porque resalta increíblemente bien sobre negro
            _buildSectionTitle('Revenue Performance'),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppTheme
                      .primaryBlue, // Mantenemos el azul como acento fuerte
                  borderRadius: BorderRadius.circular(24),
                  // Eliminamos la sombra difuminada, no se ve bien en negro puro.
                  // Añadimos un borde sutil para definirlo.
                  border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                      width: 1)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Sales',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          const Text('\$12,345.00',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.trending_up,
                            color: Colors.white, size: 28),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRevenueSubStat(
                          'This Month', '\$2,345', Colors.white),
                      _buildRevenueSubStat('Last Month', '\$2,100',
                          Colors.white.withValues(alpha: 0.7)),
                      _buildRevenueSubStat(
                          'Avg. Order', '\$15.67', Colors.white),
                    ],
                  )
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 30),

            // 3. ESTADÍSTICAS CON BARRAS VISUALES
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('User Growth'),
                      _buildGraphCard([
                        _buildBarStat('Active', 987, 1200, Colors.green,
                            Icons.check_circle),
                        _buildBarStat('New', 123, 200, AppTheme.primaryBlue,
                            Icons.person_add),
                        _buildBarStat(
                            'Artists', 45, 100, Colors.purple, Icons.mic),
                        _buildBarStat(
                            'Admins', 5, 10, Colors.red, Icons.security),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Content'),
                      _buildGraphCard([
                        _buildBarStat('Plays', 85, 100, AppTheme.primaryBlue,
                            Icons.play_arrow),
                        _buildBarStat(
                            'Downloads', 40, 100, Colors.green, Icons.download),
                        _buildBarStat('Playlists', 60, 100, Colors.orange,
                            Icons.queue_music),
                        _buildBarStat(
                            'Likes', 75, 100, Colors.amber, Icons.thumb_up),
                      ]),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 30),

            // 4. TOP CONTENT
            _buildSectionTitle('Top Performing Content'),
            Card(
              elevation: 0,
              color: darkCardBg, // Color de tarjeta oscura
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey[800]!) // Borde sutil
                  ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    _buildMagazineRow('01', 'Midnight Dreams', '1,234 plays',
                        Icons.music_note, AppTheme.primaryBlue),
                    _buildMagazineRow('02', 'Electric Love', '1,123 plays',
                        Icons.music_note, Colors.purple),
                    _buildMagazineRow('03', 'Summer Vibes', '987 plays',
                        Icons.album, Colors.orange),
                    _buildMagazineRow('04', 'Jazz Collection', '876 plays',
                        Icons.album, Colors.blueGrey),
                    _buildMagazineRow('05', 'Blue Notes', '765 plays',
                        Icons.music_note, AppTheme.primaryBlue),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ADAPTADOS A DARK MODE ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: lightText, // Título blanco
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildModernStatCard(
      String title, String value, IconData icon, Color color, String growth) {
    return Container(
      decoration: BoxDecoration(
        color: darkCardBg, // Fondo de tarjeta oscuro
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.grey[800]!), // Borde fino para separación
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // El color con opacidad baja funciona bien sobre fondo oscuro
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  growth,
                  // Usamos un verde un poco más claro para que se lea mejor en oscuro
                  style: TextStyle(
                      color: Colors.greenAccent[400],
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: lightText), // Valor blanco
                ),
                Text(
                  title,
                  style:
                      TextStyle(fontSize: 13, color: subText), // Subtítulo gris
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSubStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _buildGraphCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: darkCardBg, // Tarjeta oscura
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!), // Borde oscuro
      ),
      padding: const EdgeInsets.all(16),
      child: Column(children: children),
    );
  }

  Widget _buildBarStat(
      String label, int value, int total, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: subText),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: lightText.withValues(alpha: 0.9))),
              const Spacer(),
              Text(value.toString(),
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / total,
              // Fondo de la barra más oscuro
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagazineRow(
      String rank, String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            rank,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700]), // Número de ranking más oscuro
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: lightText)), // Título blanco
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: subText)), // Subtítulo gris
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[700]),
        ],
      ),
    );
  }
}
