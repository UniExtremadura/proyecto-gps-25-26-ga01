import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/user_service.dart';
import '../../../core/models/user.dart';
import '../../music/screens/artist_detail_screen.dart';

class FollowedArtistsScreen extends StatefulWidget {
  const FollowedArtistsScreen({super.key});

  @override
  State<FollowedArtistsScreen> createState() => _FollowedArtistsScreenState();
}

class _FollowedArtistsScreenState extends State<FollowedArtistsScreen> {
  final UserService _userService = UserService();
  List<User> _artists = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Uso de addPostFrameCallback para asegurar que el contexto (Provider) sea accesible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFollowedArtists();
    });
  }

  Future<void> _loadFollowedArtists() async {
    // 1. Establecer estado de carga
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // 2. Obtener el ID del usuario actual de manera segura
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      setState(() {
        _error = 'Usuario no identificado. Por favor, inicia sesión.';
        _isLoading = false;
      });
      return;
    }

    // 3. Llamar a la API
    final response = await _userService.getFollowedArtists(userId);

    // 4. Procesar la respuesta
    if (response.success && response.data != null) {
      setState(() {
        // Mapeamos y casteamos explícitamente a List<User>
        _artists =
            (response.data as List<dynamic>).map((e) => e as User).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error =
            response.error ?? 'Error al cargar artistas. Vuelve a intentarlo.';
        _isLoading = false;
      });
    }
  }

  Future<void> _unfollowArtist(User artist) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    // 1. Mostrar confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dejar de seguir'),
        content: Text('¿Dejar de seguir a ${artist.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Llamada a la API de unfollow
    final response = await _userService.unfollowUser(userId, artist.id);

    if (response.success) {
      // 3. Actualizar la lista VISUAL local (optimista)
      setState(() {
        _artists.removeWhere((a) => a.id == artist.id);
      });

      // 4. Actualizar el ESTADO GLOBAL
      await authProvider.refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Has dejado de seguir a ${artist.fullName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Error al dejar de seguir'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artistas Seguidos'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFollowedArtists,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_artists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.textGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No sigues a ningún artista',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Explora y sigue a tus artistas favoritos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textGrey,
                  ),
            ),
          ],
        ),
      );
    }

    // Lista de artistas
    return RefreshIndicator(
      onRefresh: _loadFollowedArtists,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _artists.length,
        itemBuilder: (context, index) {
          final artist = _artists[index];
          return _buildArtistCard(artist, index);
        },
      ),
    );
  }

  Widget _buildArtistCard(User artist, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArtistDetailScreen(artistId: artist.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Artist Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                backgroundImage: artist.profileImageUrl != null
                    ? NetworkImage(artist.profileImageUrl!)
                    : null,
                child: artist.profileImageUrl == null
                    ? Icon(
                        Icons.person,
                        size: 30,
                        color: AppTheme.primaryBlue,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Artist Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            artist.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (artist.isVerified)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified,
                              size: 20,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${artist.username}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textGrey,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: AppTheme.textGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${artist.followerIds.length} seguidores',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textGrey,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Unfollow Button
              IconButton(
                onPressed: () => _unfollowArtist(artist),
                icon: Icon(
                  Icons.person_remove_outlined,
                  color: AppTheme.errorRed,
                ),
                tooltip: 'Dejar de seguir',
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX();
  }
}
