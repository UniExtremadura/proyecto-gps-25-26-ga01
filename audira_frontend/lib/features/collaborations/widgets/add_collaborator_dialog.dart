import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/models/user.dart';
import '../../../core/api/services/collaboration_service.dart';
import '../../../core/api/services/user_service.dart';

class AddCollaboratorDialog extends StatefulWidget {
  final List<Song> songs;
  final List<Album> albums;

  const AddCollaboratorDialog({
    super.key,
    required this.songs,
    required this.albums,
  });

  @override
  State<AddCollaboratorDialog> createState() => _AddCollaboratorDialogState();
}

class _AddCollaboratorDialogState extends State<AddCollaboratorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _roleController = TextEditingController();
  final CollaborationService _collaborationService = CollaborationService();
  final UserService _userService = UserService();

  // --- Colores del Tema Oscuro ---
  final Color darkCardBg = const Color(0xFF212121);
  final Color inputBg = Colors.black;
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  String _entityType = 'song'; // 'song' or 'album'
  int? _selectedEntityId;
  User? _selectedArtist;
  bool _isLoading = false;
  bool _isSearching = false;
  List<User> _searchResults = [];
  Timer? _debounceTimer;

  final List<String> _suggestedRoles = [
    'Featured Artist',
    'Producer',
    'Songwriter',
    'Vocalist',
    'Mixing Engineer',
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  // --- LOGIC ---

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchArtists(query);
    });
  }

  Future<void> _searchArtists(String query) async {
    try {
      final response = await _userService.searchArtists(query);
      if (mounted) {
        setState(() {
          _searchResults = response.success ? (response.data ?? []) : [];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _inviteCollaborator() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEntityId == null) {
      _showError('Please select a song or album.');
      return;
    }
    if (_selectedArtist == null) {
      _showError('Please select an artist.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final artistId = _selectedArtist!.id;
      final role = _roleController.text.trim();

      final response = _entityType == 'song'
          ? await _collaborationService.inviteCollaboratorToSong(
              songId: _selectedEntityId!,
              artistId: artistId,
              role: role,
            )
          : await _collaborationService.inviteCollaboratorToAlbum(
              albumId: _selectedEntityId!,
              artistId: artistId,
              role: role,
            );

      if (response.success) {
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invitation sent successfully'),
              backgroundColor: Colors.green),
        );
      } else {
        throw Exception(response.error ?? 'Unknown error');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: darkCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child:
                      const Icon(Icons.person_add, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invite Collaborator',
                          style: TextStyle(
                              color: lightText,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text('Add an artist to your project',
                          style: TextStyle(color: subText, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: subText))
              ],
            ),
            const Divider(color: Colors.grey, height: 32),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Content Type Selector
                      _buildSectionLabel('1. Project Type'),
                      Row(
                        children: [
                          Expanded(
                              child: _buildTypeOption(
                                  'Song', Icons.music_note, 'song')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildTypeOption(
                                  'Album', Icons.album, 'album')),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 2. Entity Dropdown
                      _buildSectionLabel(_entityType == 'song'
                          ? '2. Select Song'
                          : '2. Select Album'),
                      _buildEntityDropdown(),
                      const SizedBox(height: 20),

                      // 3. Artist Search
                      _buildSectionLabel('3. Find Artist'),
                      if (_selectedArtist != null)
                        _buildSelectedArtistCard()
                      else
                        _buildSearchField(),

                      const SizedBox(height: 20),

                      // 4. Role Input
                      _buildSectionLabel('4. Assign Role'),
                      TextFormField(
                        controller: _roleController,
                        style: TextStyle(color: lightText),
                        decoration: _inputDecoration('e.g. Producer, Vocalist',
                            icon: Icons.work_outline),
                        validator: (val) =>
                            val!.trim().isEmpty ? 'Role is required' : null,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _suggestedRoles
                            .map((role) => _buildRoleChip(role))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _inviteCollaborator,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Send Invitation',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: TextStyle(
              color: subText,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildTypeOption(String label, IconData icon, String value) {
    final isSelected = _entityType == value;
    return InkWell(
      onTap: () => setState(() {
        _entityType = value;
        _selectedEntityId = null;
      }),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : Colors.grey[800]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEntityDropdown() {
    final items = _entityType == 'song' ? widget.songs : widget.albums;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text('No ${_entityType}s found.',
                    style: const TextStyle(color: Colors.orange))),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedEntityId,
      dropdownColor: const Color(0xFF303030),
      style: TextStyle(color: lightText),
      decoration: _inputDecoration('Select $_entityType...',
          icon: _entityType == 'song' ? Icons.music_note : Icons.album),
      items: items.map((item) {
        // Handle dynamic typing for Song vs Album
        final id = (item as dynamic).id;
        final name = (item as dynamic).name;
        return DropdownMenuItem<int>(
          value: id,
          child: Text(name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedEntityId = val),
    );
  }

  Widget _buildSearchField() {
    return Column(
      children: [
        TextFormField(
          controller: _searchController,
          style: TextStyle(color: lightText),
          decoration: _inputDecoration('Search artist by name...',
              icon: Icons.search,
              suffix: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : null),
          onChanged: _onSearchChanged,
        ),
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: const Color(0xFF303030),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _searchResults.length,
              separatorBuilder: (c, i) =>
                  const Divider(height: 1, color: Colors.grey),
              itemBuilder: (context, index) {
                final artist = _searchResults[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text(artist.username[0].toUpperCase(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                  title:
                      Text(artist.fullName, style: TextStyle(color: lightText)),
                  subtitle: Text('@${artist.username}',
                      style: TextStyle(color: subText)),
                  onTap: () => setState(() {
                    _selectedArtist = artist;
                    _searchResults = [];
                    _searchController.clear();
                  }),
                );
              },
            ),
          )
      ],
    );
  }

  Widget _buildSelectedArtistCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryBlue,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedArtist!.fullName,
                    style: TextStyle(
                        color: lightText, fontWeight: FontWeight.bold)),
                Text('@${_selectedArtist!.username}',
                    style: TextStyle(color: subText, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedArtist = null),
            icon: const Icon(Icons.close, color: Colors.redAccent),
            tooltip: 'Remove',
          )
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label) {
    return InkWell(
      onTap: () => _roleController.text = label,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Text(label, style: TextStyle(color: subText, fontSize: 12)),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint,
      {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600]),
      prefixIcon:
          icon != null ? Icon(icon, color: Colors.grey[600], size: 20) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[800]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primaryBlue)),
    );
  }
}
