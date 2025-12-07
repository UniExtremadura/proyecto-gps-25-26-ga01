import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/collaborator.dart';
import '../../../core/api/services/collaboration_service.dart';
import '../../../core/providers/auth_provider.dart';

/// Screen for viewing and responding to collaboration invitations
class CollaborationInvitationsScreen extends StatefulWidget {
  const CollaborationInvitationsScreen({super.key});

  @override
  State<CollaborationInvitationsScreen> createState() =>
      _CollaborationInvitationsScreenState();
}

class _CollaborationInvitationsScreenState
    extends State<CollaborationInvitationsScreen> {
  final CollaborationService _collaborationService = CollaborationService();

  // --- Colores del Tema Oscuro ---
  final Color darkBg = Colors.black;
  final Color darkCardBg = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  List<Collaborator> _invitations = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final artistId = authProvider.currentUser!.id;
      final response =
          await _collaborationService.getPendingInvitations(artistId);

      if (response.success && response.data != null) {
        setState(() {
          _invitations = response.data!;
        });
      } else {
        throw Exception(response.error ?? 'Error desconocido');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIC ---

  Future<void> _acceptInvitation(Collaborator invitation) async {
    final currentContext = context;
    try {
      final response =
          await _collaborationService.acceptInvitation(invitation.id);

      if (response.success) {
        if (!currentContext.mounted) return;
        _showSnack('Invitación aceptada. ¡Ahora eres colaborador!',
            isSuccess: true);
        _loadInvitations();
      } else {
        throw Exception(response.error ?? 'Error desconocido');
      }
    } catch (e) {
      if (!currentContext.mounted) return;
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _rejectInvitation(Collaborator invitation) async {
    final currentContext = context;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 12),
            Text('Rechazar Oferta', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres rechazar esta colaboración?\nEsta acción no se puede deshacer.',
          style: TextStyle(color: Colors.grey),
        ),
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
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response =
            await _collaborationService.rejectInvitation(invitation.id);

        if (response.success) {
          if (!currentContext.mounted) return;
          _showSnack('Invitación rechazada', color: Colors.orange);
          _loadInvitations();
        } else {
          throw Exception(response.error ?? 'Error desconocido');
        }
      } catch (e) {
        if (!currentContext.mounted) return;
        _showSnack('Error: $e', isError: true);
      }
    }
  }

  void _showSnack(String msg,
      {bool isError = false, bool isSuccess = false, Color? color}) {
    Color finalColor = color ?? Colors.grey;
    if (isError) finalColor = Colors.red[900]!;
    if (isSuccess) finalColor = Colors.green[800]!;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: finalColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Peticiones de colaboración',
          style: TextStyle(
              color: AppTheme.primaryBlue, fontWeight: FontWeight.w800),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: AppTheme.primaryBlue),
              onPressed: _loadInvitations,
              tooltip: 'Refrescar',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _error != null
              ? _buildErrorState()
              : _invitations.isEmpty
                  ? _buildEmptyState()
                  : _buildInvitationsList(),
    );
  }

  Widget _buildEmptyState() {
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
            child:
                Icon(Icons.mark_email_read, size: 60, color: Colors.grey[800]),
          ),
          const SizedBox(height: 24),
          Text(
            '¡Estás al día!',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: lightText),
          ),
          const SizedBox(height: 8),
          Text(
            'No tienes peticiones de colaboración.',
            style: TextStyle(color: subText),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInvitations,
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _invitations.length,
      itemBuilder: (context, index) {
        return _buildInvitationCard(_invitations[index], index);
      },
    );
  }

  Widget _buildInvitationCard(Collaborator invitation, int index) {
    // Determinar estilo basado en tipo
    final bool isSong = invitation.isForSong;
    final Color typeColor = isSong ? AppTheme.primaryBlue : Colors.purpleAccent;
    final IconData typeIcon = isSong ? Icons.music_note : Icons.album;
    final String typeLabel = isSong ? 'Song Collab' : 'Album Collab';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: darkCardBg,
        elevation: 4,
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: typeColor, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  border: Border(bottom: BorderSide(color: Colors.grey[850]!)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            typeLabel.toUpperCase(),
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${invitation.entityId}',
                            style: TextStyle(
                              color: lightText,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.access_time_filled,
                              size: 12, color: Colors.orangeAccent),
                          SizedBox(width: 4),
                          Text('Pendiente',
                              style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- BODY CONTENT ---
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person, 'Invited By',
                        'User ID: ${invitation.invitedBy}'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.work, 'Role', invitation.role),
                    const SizedBox(height: 12),
                    _buildRevenueRow(invitation.revenuePercentage),
                  ],
                ),
              ),

              // --- ACTIONS ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectInvitation(invitation),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(
                              color: Colors.redAccent.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Rechazar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acceptInvitation(invitation),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Aceptar y unirse'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: subText),
        const SizedBox(width: 12),
        Text('$label:', style: TextStyle(color: subText, fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                color: lightText, fontWeight: FontWeight.w500, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueRow(double percentage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on,
                  size: 18, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Text('Oferta de participación en los ingresos',
                  style:
                      TextStyle(color: Colors.greenAccent[100], fontSize: 13)),
            ],
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
