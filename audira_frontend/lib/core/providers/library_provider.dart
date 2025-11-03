import 'package:flutter/foundation.dart';
import '../api/services/playlist_service.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/playlist.dart';

class LibraryProvider with ChangeNotifier {
  final PlaylistService _playlistService = PlaylistService();

  List<Song> _favoriteSongs = [];
  List<Album> _favoriteAlbums = [];
  bool _isFavoritesLoading = false;

  List<Playlist> _playlists = [];
  bool _isPlaylistsLoading = false;

  List<Song> _purchasedSongs = [];
  List<Album> _purchasedAlbums = [];
  bool _isLibraryLoading = false;

  List<Song> get favoriteSongs => _favoriteSongs;
  List<Album> get favoriteAlbums => _favoriteAlbums;
  List<Playlist> get playlists => _playlists;
  List<Song> get purchasedSongs => _purchasedSongs;
  List<Album> get purchasedAlbums => _purchasedAlbums;
  bool get isFavoritesLoading => _isFavoritesLoading;
  bool get isPlaylistsLoading => _isPlaylistsLoading;
  bool get isLibraryLoading => _isLibraryLoading;

  Future<void> loadFavorites(int userId) async {
    _isFavoritesLoading = true;
    notifyListeners();

    try {
      // Using empty lists for now
      _favoriteSongs = [];
      _favoriteAlbums = [];
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _isFavoritesLoading = false;
      notifyListeners();
    }
  }

  bool isSongFavorite(int songId) {
    return _favoriteSongs.any((song) => song.id == songId);
  }

  bool isAlbumFavorite(int albumId) {
    return _favoriteAlbums.any((album) => album.id == albumId);
  }

  Future<void> toggleSongFavorite(int userId, Song song) async {
    try {
      final isFavorite = isSongFavorite(song.id);

      if (isFavorite) {
        _favoriteSongs.removeWhere((s) => s.id == song.id);
      } else {
        _favoriteSongs.add(song);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling song favorite: $e');
      rethrow;
    }
  }

  Future<void> toggleAlbumFavorite(int userId, Album album) async {
    try {
      final isFavorite = isAlbumFavorite(album.id);

      if (isFavorite) {
        _favoriteAlbums.removeWhere((a) => a.id == album.id);
      } else {
        _favoriteAlbums.add(album);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling album favorite: $e');
      rethrow;
    }
  }

  Future<void> loadPlaylists(int userId) async {
    _isPlaylistsLoading = true;
    notifyListeners();

    try {
      final response = await _playlistService.getUserPlaylists(userId);
      if (response.success && response.data != null) {
        _playlists = response.data!;
      }
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    } finally {
      _isPlaylistsLoading = false;
      notifyListeners();
    }
  }

  Future<Playlist?> createPlaylist({
    required int userId,
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    try {
      final Map<String, dynamic> playlistData = {
        'userId': userId,
        'name': name,
        'description': description,
        'isPublic': isPublic,
      };

      final response = await _playlistService.createPlaylist(playlistData);

      if (response.success && response.data != null) {
        _playlists.add(response.data!);
        notifyListeners();
        return response.data;
      }

      return null;
    } catch (e) {
      debugPrint('Error creating playlist: $e');
      rethrow;
    }
  }

  Future<void> updatePlaylist({
    required int playlistId,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    try {
      final response = await _playlistService.updatePlaylist(
        playlistId: playlistId,
        name: name,
        description: description,
        isPublic: isPublic,
      );

      if (response.success && response.data != null) {
        final index = _playlists.indexWhere((p) => p.id == playlistId);
        if (index != -1) {
          _playlists[index] = response.data!;
          notifyListeners();
        }
      }
      debugPrint(
          "FUNCIONALIDAD 'updatePlaylist' PENDIENTE DE IMPLEMENTAR EN PlaylistService");
      throw UnimplementedError(
          "updatePlaylist no está implementado en PlaylistService");
    } catch (e) {
      debugPrint('Error updating playlist: $e');
      rethrow;
    }
  }

  Future<void> deletePlaylist(int playlistId) async {
    try {
      final response = await _playlistService.deletePlaylist(playlistId);

      if (response.success) {
        _playlists.removeWhere((p) => p.id == playlistId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting playlist: $e');
      rethrow;
    }
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    try {
      final response = await _playlistService.addSongToPlaylist(
        playlistId,
        songId,
      );

      if (response.success) {
        final playlistResponse =
            await _playlistService.getPlaylistById(playlistId);
        if (playlistResponse.success && playlistResponse.data != null) {
          final index = _playlists.indexWhere((p) => p.id == playlistId);
          if (index != -1) {
            _playlists[index] = playlistResponse.data!;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error adding song to playlist: $e');
      rethrow;
    }
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    try {
      final response = await _playlistService.removeSongFromPlaylist(
        playlistId,
        songId,
      );

      if (response.success) {
        final index = _playlists.indexWhere((p) => p.id == playlistId);
        if (index != -1) {
          _playlists[index].songIds.removeWhere((id) => id == songId);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error removing song from playlist: $e');
      rethrow;
    }
  }

  Future<void> loadLibrary(int userId) async {
    _isLibraryLoading = true;
    notifyListeners();

    try {
      // Using empty lists for now
      _purchasedSongs = [];
      _purchasedAlbums = [];
    } catch (e) {
      debugPrint('Error loading library: $e');
    } finally {
      _isLibraryLoading = false;
      notifyListeners();
    }
  }

  void clearLibrary() {
    _favoriteSongs.clear();
    _favoriteAlbums.clear();
    _playlists.clear();
    _purchasedSongs.clear();
    _purchasedAlbums.clear();
    notifyListeners();
  }
}
