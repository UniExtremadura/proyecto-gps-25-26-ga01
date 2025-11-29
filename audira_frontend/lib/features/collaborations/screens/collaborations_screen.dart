import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/collaborator.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/api/services/collaboration_service.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/add_collaborator_dialog.dart';
import '../widgets/revenue_settings_dialog.dart';
import 'collaboration_invitations_screen.dart';

class CollaborationsScreen extends StatefulWidget {
  const CollaborationsScreen({super.key});

  @override
  State<CollaborationsScreen> createState() => _CollaborationsScreenState();
}

class _CollaborationsScreenState extends State<CollaborationsScreen>
    with SingleTickerProviderStateMixin {
  final CollaborationService _collaborationService = CollaborationService();
  final MusicService _musicService = MusicService();
  late TabController _tabController;

  // --- Colores del Tema Oscuro ---
  final Color darkBg = Colors.black;
  final Color darkCardBg = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  List<Collaborator> _myCollaborations = [];
  List<Collaborator> _invitedCollaborations = [];
  List<Song> _mySongs = [];
  List<Album> _myAlbums = [];
  int _pendingInvitationsCount = 0;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final artistId = authProvider.currentUser!.id;

      final collaborationsResponse =
          await _collaborationService.getArtistCollaborations(artistId);
      if (collaborationsResponse.success &&
          collaborationsResponse.data != null) {
        final allCollaborations = collaborationsResponse.data!;

        _myCollaborations = allCollaborations
            .where((c) => c.artistId == artistId && c.isAccepted)
            .toList();
        _invitedCollaborations = allCollaborations
            .where((c) => c.invitedBy == artistId && c.isAccepted)
            .toList();
      }

      final pendingResponse =
          await _collaborationService.getPendingInvitations(artistId);
      if (pendingResponse.success && pendingResponse.data != null) {
        _pendingInvitationsCount = pendingResponse.data!.length;
      }

      final songsResponse = await _musicService.getSongsByArtist(artistId);
      if (songsResponse.success && songsResponse.data != null) {
        _mySongs = songsResponse.data!;
      }

      final albumsResponse = await _musicService.getAlbumsByArtist(artistId);
      if (albumsResponse.success && albumsResponse.data != null) {
        _myAlbums = albumsResponse.data!;
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- ACTIONS ---

  Future<void> _showAddCollaboratorDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddCollaboratorDialog(
        songs: _mySongs,
        albums: _myAlbums,
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _showRevenueSettings(Collaborator collaboration) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RevenueSettingsDialog(
        collaboration: collaboration,
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _removeCollaboration(Collaborator collaboration) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        title: const Text('End Collaboration',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to end this collaboration?\nThis action cannot be undone.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white),
            child: const Text('End'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final currentContext = context;
      try {
        final response =
            await _collaborationService.deleteCollaboration(collaboration.id);
        if (response.success) {
          if (!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(
                content: Text('Collaboration ended'),
                backgroundColor: Colors.green),
          );
          _loadData();
        } else {
          throw Exception(response.error ?? 'Unknown error');
        }
      } catch (e) {
        if (!currentContext.mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        title: const Text('Active Collaborations',
            style: TextStyle(
                color: AppTheme.primaryBlue, fontWeight: FontWeight.w800)),
        backgroundColor: darkBg,
        elevation: 0,
        actions: [
          // Invitations Icon with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.mail_outline, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CollaborationInvitationsScreen(),
                    ),
                  );
                  if (result == true) _loadData();
                },
              ),
              if (_pendingInvitationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_pendingInvitationsCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: subText,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'My Projects'), // Owned by me
            Tab(text: 'Guest Projects'), // Invited to
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInvitedCollaborationsTab(), // Logic seems swapped in original var naming
                    _buildMyCollaborationsTab(), // Swapped to match labels above logic
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCollaboratorDialog,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label:
            const Text('Invite Artist', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // NOTE: Swapped logic based on variable naming assumption:
  // _invitedCollaborations -> I invited them (My Projects)
  // _myCollaborations -> I am a collaborator (Guest Projects)

  Widget _buildInvitedCollaborationsTab() {
    if (_invitedCollaborations.isEmpty) {
      return _buildEmptyState(
          'No active collaborations', 'Invite artists to your songs/albums');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _invitedCollaborations.length,
        itemBuilder: (context, index) {
          final collaboration = _invitedCollaborations[index];
          return _buildCollaborationCard(collaboration,
              isOwner: true, index: index);
        },
      ),
    );
  }

  Widget _buildMyCollaborationsTab() {
    if (_myCollaborations.isEmpty) {
      return _buildEmptyState(
          'No guest collaborations', 'You haven\'t joined any projects yet');
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _myCollaborations.length,
        itemBuilder: (context, index) {
          final collaboration = _myCollaborations[index];
          return _buildCollaborationCard(collaboration,
              isOwner: false, index: index);
        },
      ),
    );
  }

  // --- CARD WIDGET ---

  Widget _buildCollaborationCard(Collaborator collaboration,
      {required bool isOwner, required int index}) {
    final bool isSong = collaboration.isForSong;
    final Color typeColor = isSong ? AppTheme.primaryBlue : Colors.purpleAccent;
    final IconData typeIcon = isSong ? Icons.music_note : Icons.album;
    final String typeLabel = isSong ? 'Song' : 'Album';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: darkCardBg,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: typeColor, width: 4)),
          ),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,

            // --- HEADER ---
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            title: Text(
              '$typeLabel ID: ${collaboration.entityId}', // Ideally fetch name
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Text(
              collaboration.role,
              style: TextStyle(color: subText, fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3))),
              child: Text(
                '${collaboration.revenuePercentage.toStringAsFixed(0)}% Rev',
                style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),

            // --- EXPANDED CONTENT ---
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                        Icons.person,
                        isOwner ? 'Collaborator ID' : 'Owner ID',
                        isOwner
                            ? '${collaboration.artistId}'
                            : '${collaboration.invitedBy}'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        Icons.calendar_today,
                        'Started',
                        collaboration.createdAt != null
                            ? _formatDate(collaboration.createdAt!)
                            : 'Unknown'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isOwner)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showRevenueSettings(collaboration),
                      icon: const Icon(Icons.attach_money, size: 16),
                      label: const Text('Adjust Revenue'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.greenAccent,
                        side: BorderSide(
                            color: Colors.greenAccent.withValues(alpha: 0.5)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _removeCollaboration(collaboration),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('End Contract'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.grey, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            'Only the project owner can manage this contract.',
                            style: TextStyle(
                                color: subText,
                                fontSize: 11,
                                fontStyle: FontStyle.italic))),
                  ],
                )
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: -0.05, end: 0);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: subText),
        const SizedBox(width: 8),
        Text('$label:', style: TextStyle(color: subText, fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  color: lightText, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: subText)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red[900]),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
