import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/playlist_service.dart';
import '../../../core/api/services/library_service.dart';

class UserStatsScreen extends StatefulWidget {
  const UserStatsScreen({super.key});

  @override
  State<UserStatsScreen> createState() => _UserStatsScreenState();
}

class _UserStatsScreenState extends State<UserStatsScreen> {
  final PlaylistService _playlistService = PlaylistService();
  // final OrderService _orderService = OrderService(); // Ya no lo necesitamos para esta vista si quitamos la lista de pedidos
  final LibraryService _libraryService = LibraryService(); // <--- RECUPERADO

  // Datos
  int _playlistCount = 0;

  // Variables locales para asegurar que los datos se muestran
  int _ownedSongs = 0;
  int _ownedAlbums = 0;
  double _totalSpent = 0.0;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRealStats();
  }

  Future<void> _loadRealStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        final userId = authProvider.currentUser!.id;

        // 1. Cargar Librería (Fuente de verdad para compras y gasto)
        final libraryResponse = await _libraryService.getUserLibrary(userId);

        if (libraryResponse.success && libraryResponse.data != null) {
          final lib = libraryResponse.data!;

          // A. Conteos
          _ownedSongs = lib.songs.length;
          _ownedAlbums = lib.albums.length;

          // B. CÁLCULO DE GASTO TOTAL (Iterar y sumar precios)
          double calculatedSpent = 0.0;

          // Sumar Canciones
          for (var item in lib.songs) {
            calculatedSpent += (item.price * item.quantity);
          }

          // Sumar Álbumes
          for (var item in lib.albums) {
            calculatedSpent += (item.price * item.quantity);
          }

          // Sumar Merchandise (si lo usas)
          for (var item in lib.merchandise) {
            calculatedSpent += (item.price * item.quantity);
          }

          _totalSpent = calculatedSpent;
        }

        // 2. Cargar Playlists
        final playlistsResponse =
            await _playlistService.getUserPlaylists(userId);
        if (playlistsResponse.success && playlistsResponse.data != null) {
          _playlistCount = playlistsResponse.data!.length;
        }
      }
    } catch (e) {
      _errorMessage = 'Error al cargar estadísticas: $e';
      debugPrint(_errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRealStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text('Hola, ${user?.fullName}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('Tu impacto y nivel como coleccionista.',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),

                      // TARJETA PRINCIPAL: Inversión Total
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.primaryBlue.withValues(alpha: 0.7)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified, color: Colors.white70),
                                SizedBox(width: 8),
                                Text('APOYO TOTAL AL ARTISTA',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        letterSpacing: 1.2,
                                        fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // USAMOS LA VARIABLE CALCULADA _totalSpent
                            Text(
                              currencyFormat.format(_totalSpent),
                              style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 5),
                            const Text('Invertidos en música de calidad',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 14)),
                          ],
                        ),
                      ).animate().scale(delay: 100.ms),

                      const SizedBox(height: 24),

                      // GRID: Estadísticas (Usando los datos corregidos _ownedSongs)
                      const Text('Tu Biblioteca',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.15, // Ajustado para evitar overflow
                        children: [
                          _buildStatCard('Canciones', '$_ownedSongs',
                              Icons.music_note, Colors.purple),
                          _buildStatCard('Álbumes', '$_ownedAlbums',
                              Icons.album, Colors.orange),
                          _buildStatCard('Playlists', '$_playlistCount',
                              Icons.queue_music, Colors.teal),
                          _buildStatCard(
                              'Nivel Actual',
                              _getCurrentLevelName(_ownedSongs),
                              Icons.emoji_events,
                              Colors.amber),
                        ],
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 30),

                      // --- NUEVA SECCIÓN: SENDA DEL COLECCIONISTA ---
                      const Text('Senda del Coleccionista',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                          'Desbloquea niveles ampliando tu colección musical.',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 16),

                      _buildCollectorPath(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      color: const Color(0xFF252525),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Lógica de Niveles y Construcción de la Lista
  Widget _buildCollectorPath() {
    // Definición de Niveles
    final levels = [
      {
        'name': 'Diamante',
        'threshold': 50,
        'color': Colors.cyanAccent,
        'icon': Icons.diamond
      },
      {
        'name': 'Platino',
        'threshold': 25,
        'color': Colors.blueGrey,
        'icon': Icons.verified
      },
      {
        'name': 'Oro',
        'threshold': 10,
        'color': Colors.amber,
        'icon': Icons.star
      },
      {
        'name': 'Plata',
        'threshold': 5,
        'color': Colors.grey.shade300,
        'icon': Icons.shield
      },
      {
        'name': 'Bronce',
        'threshold': 1,
        'color': Colors.brown.shade300,
        'icon': Icons.music_note
      },
      {
        'name': 'Oyente',
        'threshold': 0,
        'color': Colors.blue,
        'icon': Icons.headphones
      },
    ];

    return Column(
      children: levels.map((level) {
        final threshold = level['threshold'] as int;
        final isUnlocked = _ownedSongs >= threshold;
        final isNextGoal = !isUnlocked &&
            (_ownedSongs >=
                (levels[levels.indexOf(level) + 1]['threshold'] as int));

        // Progreso para este nivel específico
        // (Solo visual si es el siguiente objetivo)
        double progress = 0.0;
        if (isNextGoal) {
          final prevThreshold =
              (levels[levels.indexOf(level) + 1]['threshold'] as int);
          progress =
              (_ownedSongs - prevThreshold) / (threshold - prevThreshold);
        } else if (isUnlocked) {
          progress = 1.0;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              // Columna de Línea de Tiempo
              Column(
                children: [
                  Container(
                    width: 2,
                    height: 20,
                    color: isUnlocked
                        ? (level['color'] as Color)
                        : Colors.grey.shade800,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: isUnlocked
                            ? (level['color'] as Color).withValues(alpha: 0.2)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isUnlocked
                                ? (level['color'] as Color)
                                : Colors.grey.shade700,
                            width: 2)),
                    child: Icon(
                      level['icon'] as IconData,
                      size: 20,
                      color:
                          isUnlocked ? (level['color'] as Color) : Colors.grey,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 20,
                    // Si es el último elemento, ocultamos la línea inferior
                    color: level == levels.last
                        ? Colors.transparent
                        : (isUnlocked
                            ? (level['color'] as Color)
                            : Colors.grey.shade800),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Tarjeta de Nivel
              Expanded(
                child: Opacity(
                  opacity: isUnlocked || isNextGoal ? 1.0 : 0.5,
                  child: Card(
                    color: isUnlocked
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isNextGoal
                            ? BorderSide(
                                color: (level['color'] as Color), width: 1)
                            : BorderSide.none),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                level['name'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      isUnlocked ? Colors.white : Colors.grey,
                                ),
                              ),
                              if (isUnlocked)
                                const Icon(Icons.check_circle,
                                    size: 18, color: Colors.green)
                              else
                                Text(
                                  'Req: $threshold canciones',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                )
                            ],
                          ),
                          if (isNextGoal) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey.shade800,
                                color: (level['color'] as Color),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${threshold - _ownedSongs} canciones más para desbloquear',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: (level['color'] as Color)),
                            )
                          ] else if (isUnlocked) ...[
                            const SizedBox(height: 4),
                            const Text("¡Completado!",
                                style:
                                    TextStyle(fontSize: 11, color: Colors.grey))
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().slideX(
            begin: 0.1, end: 0, delay: (levels.indexOf(level) * 100).ms);
      }).toList(),
    );
  }

  String _getCurrentLevelName(int songs) {
    if (songs >= 50) return "Diamante";
    if (songs >= 25) return "Platino";
    if (songs >= 10) return "Oro";
    if (songs >= 5) return "Plata";
    if (songs >= 1) return "Bronce";
    return "Oyente";
  }
}
