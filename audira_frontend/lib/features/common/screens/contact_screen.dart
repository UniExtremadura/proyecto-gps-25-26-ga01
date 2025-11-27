import 'package:audira_frontend/config/theme.dart';
import 'package:audira_frontend/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/api/services/contact_service.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final ContactService _contactService = ContactService();
  final MusicService _musicService = MusicService();

  bool _isLoading = false;
  bool _isLoadingContent = false;

  // Para artistas: selección de canción/álbum
  int? _selectedSongId;
  int? _selectedAlbumId;
  List<Song> _artistSongs = [];
  List<Album> _artistAlbums = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArtistContent();
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadArtistContent() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    final user = authProvider.currentUser!;

    // Verificar si el usuario es artista
    if (!user.isArtist) return;

    setState(() => _isLoadingContent = true);

    try {
      // Cargar canciones del artista
      final songsResponse = await _musicService.getSongsByArtist(user.id);
      if (songsResponse.success && songsResponse.data != null) {
        setState(() => _artistSongs = songsResponse.data!);
      }

      // Cargar álbumes del artista
      final albumsResponse = await _musicService.getAlbumsByArtist(user.id);
      if (albumsResponse.success && albumsResponse.data != null) {
        setState(() => _artistAlbums = albumsResponse.data!);
      }
    } catch (e) {
      // Error al cargar contenido, pero no es crítico
      debugPrint('Error loading artist content: $e');
    } finally {
      setState(() => _isLoadingContent = false);
    }
  }

  Future<void> _submitForm() async {
    final currentContext = context;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    // Verificar que el usuario esté autenticado
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para enviar un mensaje'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = authProvider.currentUser!;

      final response = await _contactService.sendContactMessage(
        name: user.fullName,
        email: user.email,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        userId: user.id,
        songId: _selectedSongId,
        albumId: _selectedAlbumId,
      );

      if(!currentContext.mounted) return;
      if (response.success) {
        if(!currentContext.mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text(
                '¡Mensaje enviado con éxito! Los administradores lo revisarán pronto.'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _subjectController.clear();
        _messageController.clear();
        _selectedSongId = null;
        _selectedAlbumId = null;
      } else {
        if(!currentContext.mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Error al enviar el mensaje'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if(!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cont\u00e1ctanos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactInfo().animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            _buildContactForm().animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contáctanos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Tienes alguna pregunta o necesitas soporte? Envíanos un mensaje y nuestro equipo de administradores te responderá pronto.',
              style: TextStyle(fontSize: 16),
            ),
            if (user != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha:0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enviando como: ${user.fullName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            user.email,
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (user == null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha:0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Debes iniciar sesión para enviar un mensaje',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactForm() {
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Envíanos un Mensaje',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                enabled: isAuthenticated,
                decoration: const InputDecoration(
                  labelText: 'Asunto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                  hintText: 'Ej: Problema con mi cuenta',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa un asunto';
                  }
                  if (value.trim().length < 3) {
                    return 'El asunto debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Solo para artistas: seleccionar canción o álbum
              if (isAuthenticated && authProvider.currentUser?.isArtist == true) ...[
                _buildArtistContentSelector(),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _messageController,
                enabled: isAuthenticated,
                decoration: const InputDecoration(
                  labelText: 'Mensaje',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                  alignLabelWithHint: true,
                  hintText: 'Describe tu consulta o problema...',
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa tu mensaje';
                  }
                  if (value.trim().length < 10) {
                    return 'El mensaje debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (!isAuthenticated || _isLoading) ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isAuthenticated
                            ? 'Enviar Mensaje a Administradores'
                            : 'Inicia sesión para enviar un mensaje',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistContentSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: const Text(
                  'Relacionar con tu contenido (opcional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Si tu consulta está relacionada con una canción o álbum específico, puedes seleccionarlo aquí:',
            style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 12),
          if (_isLoadingContent)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            DropdownButtonFormField<int>(
              initialValue: _selectedSongId,
              decoration: const InputDecoration(
                labelText: 'Selecciona canción',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.music_note),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Ninguna'),
                ),
                ..._artistSongs.map((song) {
                  return DropdownMenuItem<int>(
                    value: song.id,
                    child: Text(
                      song.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSongId = value;
                  if (value != null) _selectedAlbumId = null;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _selectedAlbumId,
              decoration: const InputDecoration(
                labelText: 'Selecciona álbum',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.album),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Ninguno'),
                ),
                ..._artistAlbums.map((album) {
                  return DropdownMenuItem<int>(
                    value: album.id,
                    child: Text(
                      album.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAlbumId = value;
                  if (value != null) _selectedSongId = null;
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}
