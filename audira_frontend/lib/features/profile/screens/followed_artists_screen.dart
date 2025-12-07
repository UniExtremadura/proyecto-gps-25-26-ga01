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

  // --- Colores del Tema Oscuro ---
  final Color darkBg = Colors.black;
  final Color darkCardBg = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  List<User> _artists = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFollowedArtists();
    });
  }

  Future<void> _loadFollowedArtists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      setState(() {
        _error = 'Usuario desconocido.';
        _isLoading = false;
      });
      return;
    }

    final response = await _userService.getFollowedArtists(userId);

    if (response.success && response.data != null) {
      setState(() {
        _artists =
            (response.data as List<dynamic>).map((e) => e as User).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response.error ?? 'Fallo al cargar artistas.';
        _isLoading = false;
      });
    }
  }

  Future<void> _unfollowArtist(User artist) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        title: const Text('Dejar de seguir',
            style: TextStyle(color: Colors.white)),
        content: Text('Seguir ${artist.fullName}?',
            style: TextStyle(color: subText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[900],
              foregroundColor: Colors.white,
            ),
            child: const Text('Dejar de seguir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await _userService.unfollowUser(userId, artist.id);

    if (response.success) {
      setState(() {
        _artists.removeWhere((a) => a.id == artist.id);
      });
      await authProvider.refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Has dejado de seguir a ${artist.fullName}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Fallo al dejar de seguir'),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text('Siguiendo',
            style: TextStyle(
                color: AppTheme.primaryBlue, fontWeight: FontWeight.w800)),
        backgroundColor: darkBg,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.red[900]),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFollowedArtists,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue),
              child: const Text('Reintentar'),
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
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: darkCardBg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[850]!),
              ),
              child: Icon(Icons.person_add_disabled,
                  size: 60, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no sigues a ningún artista',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: lightText),
            ),
            const SizedBox(height: 8),
            Text(
              'Explora a tus artistas favoritos',
              style: TextStyle(color: subText),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms);
    }

    return RefreshIndicator(
      onRefresh: _loadFollowedArtists,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _artists.length,
        separatorBuilder: (c, i) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildArtistCard(_artists[index], index);
        },
      ),
    );
  }

  Widget _buildArtistCard(User artist, int index) {
    return Container(
      decoration: BoxDecoration(
        color: darkCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ArtistDetailScreen(artistId: artist.id)),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          AppTheme.primaryBlue.withValues(alpha: 0.2),
                      backgroundImage: artist.profileImageUrl != null
                          ? NetworkImage(artist.profileImageUrl!)
                          : null,
                      child: artist.profileImageUrl == null
                          ? const Icon(Icons.person,
                              size: 28, color: AppTheme.primaryBlue)
                          : null,
                    ),
                    if (artist.isVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                              color: Colors.black, shape: BoxShape.circle),
                          child: const Icon(Icons.verified,
                              size: 14, color: AppTheme.primaryBlue),
                        ),
                      )
                  ],
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist.fullName,
                        style: TextStyle(
                            color: lightText,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${artist.username}',
                        style: TextStyle(color: subText, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people, size: 12, color: subText),
                          const SizedBox(width: 4),
                          Text(
                            '${artist.followerIds.length} seguidores',
                            style: TextStyle(color: subText, fontSize: 11),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // Action
                OutlinedButton(
                  onPressed: () => _unfollowArtist(artist),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.5)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Dejar de seguir',
                      style: TextStyle(fontSize: 12)),
                )
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}
