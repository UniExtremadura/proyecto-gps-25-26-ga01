import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Imports de tu proyecto
import 'package:audira_frontend/config/theme.dart';
import 'package:audira_frontend/core/providers/auth_provider.dart';
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
    if (!user.isArtist) return;

    setState(() => _isLoadingContent = true);

    try {
      final songsResponse = await _musicService.getSongsByArtist(user.id);
      if (songsResponse.success && songsResponse.data != null) {
        setState(() => _artistSongs = songsResponse.data!);
      }

      final albumsResponse = await _musicService.getAlbumsByArtist(user.id);
      if (albumsResponse.success && albumsResponse.data != null) {
        setState(() => _artistAlbums = albumsResponse.data!);
      }
    } catch (e) {
      debugPrint('Error loading artist content: $e');
    } finally {
      setState(() => _isLoadingContent = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showSnackBar('Debes iniciar sesión para enviar un mensaje',
          isError: true);
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

      if (mounted) {
        if (response.success) {
          _showSuccessDialog();
          _subjectController.clear();
          _messageController.clear();
          setState(() {
            _selectedSongId = null;
            _selectedAlbumId = null;
          });
        } else {
          _showSnackBar(response.error ?? 'Error al enviar mensaje',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Icon(Icons.check_circle_outline,
            color: AppTheme.successGreen, size: 60),
        content: const Text(
          '¡Mensaje enviado con éxito!\nNuestro equipo te responderá pronto.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido',
                style: TextStyle(color: AppTheme.primaryBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Contáctanos',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundBlack,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.support_agent_rounded,
              size: 48, color: AppTheme.primaryBlue),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        const Text(
          '¿Cómo podemos ayudarte?',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        const SizedBox(height: 8),
        Text(
          'Envíanos tus dudas, sugerencias o reportes.\nTe responderemos a la brevedad.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildForm() {
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;
    final isArtist = authProvider.currentUser?.isArtist ?? false;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isAuthenticated)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Debes iniciar sesión para enviar un mensaje.',
                      style: TextStyle(color: Colors.orangeAccent),
                    ),
                  ),
                ],
              ),
            ),
          TextFormField(
            controller: _subjectController,
            enabled: isAuthenticated,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Asunto',
              hintText: 'Ej: Problema con reproducción',
              prefixIcon: const Icon(Icons.subject),
              filled: true,
              fillColor: AppTheme.surfaceBlack,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              labelStyle: const TextStyle(color: Colors.grey),
              hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
            ),
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'Mínimo 3 caracteres'
                : null,
          ),
          const SizedBox(height: 16),
          if (isAuthenticated && isArtist) ...[
            _buildArtistContentSelector(),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _messageController,
            enabled: isAuthenticated,
            maxLines: 6,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Mensaje',
              hintText: 'Describe tu consulta detalladamente...',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 100), // Alinea icono arriba
                child: Icon(Icons.message_outlined),
              ),
              filled: true,
              fillColor: AppTheme.surfaceBlack,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              labelStyle: const TextStyle(color: Colors.grey),
              hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
            ),
            validator: (v) => (v == null || v.trim().length < 10)
                ? 'Mínimo 10 caracteres'
                : null,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (!isAuthenticated || _isLoading) ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Enviar Mensaje',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildArtistContentSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.link, color: AppTheme.primaryBlue, size: 20),
              SizedBox(width: 8),
              Text('Relacionar contenido (Opcional)',
                  style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingContent)
            const Center(child: CircularProgressIndicator())
          else ...[
            DropdownButtonFormField<int>(
              initialValue: _selectedSongId,
              dropdownColor: const Color(0xFF2C2C2C),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Canción',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<int>(
                    value: null,
                    child:
                        Text('Ninguna', style: TextStyle(color: Colors.grey))),
                ..._artistSongs.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (val) => setState(() {
                _selectedSongId = val;
                if (val != null) _selectedAlbumId = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _selectedAlbumId,
              dropdownColor: const Color(0xFF2C2C2C),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Álbum',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<int>(
                    value: null,
                    child:
                        Text('Ninguno', style: TextStyle(color: Colors.grey))),
                ..._artistAlbums.map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (val) => setState(() {
                _selectedAlbumId = val;
                if (val != null) _selectedSongId = null;
              }),
            ),
          ],
        ],
      ),
    );
  }
}
