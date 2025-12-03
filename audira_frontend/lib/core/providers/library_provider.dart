import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../api/services/playlist_service.dart';
import '../api/services/library_service.dart';
import '../api/services/music_service.dart';
import '../api/services/favorite_service.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import '../../../config/constants.dart';

class LibraryProvider with ChangeNotifier {
  final PlaylistService _playlistService = PlaylistService();
  final LibraryService _libraryService = LibraryService();
  final MusicService _musicService = MusicService();
  final FavoriteService _favoriteService = FavoriteService();

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
      final response = await _favoriteService.getUserFavorites(userId);

      if (response.success && response.data != null) {
        final favorites = response.data!;

        // Listas temporales para carga paralela
        List<Song> tempSongs = [];
        List<Album> tempAlbums = [];

        // 1. Cargar Canciones en paralelo
        final songFutures = favorites.songs.map((favItem) async {
          final songRes = await _musicService.getSongById(favItem.itemId);
          if (songRes.success && songRes.data != null) {
            var song = songRes.data!;
            // Cargar Artista
            final artistRes = await _musicService.getArtistById(song.artistId);
            if (artistRes.success && artistRes.data != null) {
              song = song.copyWith(
                  artistName:
                      artistRes.data!.artistName ?? artistRes.data!.username);
            }
            return song;
          }
          return null;
        });

        // 2. Cargar Álbumes en paralelo
        final albumFutures = favorites.albums.map((favItem) async {
          final albumRes = await _musicService.getAlbumById(favItem.itemId);
          if (albumRes.success && albumRes.data != null) {
            var album = albumRes.data!;
            // Cargar Artista
            final artistRes = await _musicService.getArtistById(album.artistId);
            if (artistRes.success && artistRes.data != null) {
              album = album.copyWith(
                  artistName:
                      artistRes.data!.artistName ?? artistRes.data!.username);
            }
            return album;
          }
          return null;
        });

        // Esperar a que todo termine
        final songsResults = await Future.wait(songFutures);
        final albumsResults = await Future.wait(albumFutures);

        // Filtrar nulos y actualizar listas principales
        tempSongs = songsResults.whereType<Song>().toList();
        tempAlbums = albumsResults.whereType<Album>().toList();

        _favoriteSongs = tempSongs;
        _favoriteAlbums = tempAlbums;
      } else {
        debugPrint('Failed to load favorites: ${response.error}');
      }
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
      final response = await _favoriteService.toggleFavorite(
        userId,
        AppConstants.itemTypeSong,
        song.id,
      );

      if (response.success && response.data != null) {
        final isFavorite = response.data!;

        if (isFavorite) {
          // Si no tiene nombre de artista, intentar cargarlo rápido
          if (song.artistName.isEmpty || song.artistName == 'Unknown Artist') {
            final artistResponse =
                await _musicService.getArtistById(song.artistId);
            if (artistResponse.success && artistResponse.data != null) {
              song = song.copyWith(
                  artistName: artistResponse.data!.artistName ??
                      artistResponse.data!.username);
            }
          }
          if (!_favoriteSongs.any((s) => s.id == song.id)) {
            _favoriteSongs.add(song);
          }
        } else {
          _favoriteSongs.removeWhere((s) => s.id == song.id);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling song favorite: $e');
      rethrow;
    }
  }

  Future<void> toggleAlbumFavorite(int userId, Album album) async {
    try {
      final response = await _favoriteService.toggleFavorite(
        userId,
        AppConstants.itemTypeAlbum,
        album.id,
      );

      if (response.success && response.data != null) {
        final isFavorite = response.data!;

        if (isFavorite) {
          if (album.artistName.isEmpty ||
              album.artistName == 'Unknown Artist') {
            final artistResponse =
                await _musicService.getArtistById(album.artistId);
            if (artistResponse.success && artistResponse.data != null) {
              album = album.copyWith(
                  artistName: artistResponse.data!.artistName ??
                      artistResponse.data!.username);
            }
          }
          if (!_favoriteAlbums.any((a) => a.id == album.id)) {
            _favoriteAlbums.add(album);
          }
        } else {
          _favoriteAlbums.removeWhere((a) => a.id == album.id);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling album favorite: $e');
      rethrow;
    }
  }

  // --- PLAYLIST LOGIC ---

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
    } catch (e) {
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
      rethrow;
    }
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    try {
      final response =
          await _playlistService.addSongToPlaylist(playlistId, songId);
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
      rethrow;
    }
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    try {
      final response =
          await _playlistService.removeSongFromPlaylist(playlistId, songId);
      if (response.success) {
        final index = _playlists.indexWhere((p) => p.id == playlistId);
        if (index != -1) {
          _playlists[index].songIds.removeWhere((id) => id == songId);
          notifyListeners();
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- LIBRARY / PURCHASED CONTENT LOGIC ---

  Future<void> _savePurchasedContentToLocal(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsJson =
          jsonEncode(_purchasedSongs.map((s) => s.toJson()).toList());
      await prefs.setString('purchased_songs_$userId', songsJson);
      final albumsJson =
          jsonEncode(_purchasedAlbums.map((a) => a.toJson()).toList());
      await prefs.setString('purchased_albums_$userId', albumsJson);
    } catch (e) {
      debugPrint('Error saving local content: $e');
    }
  }

  Future<void> _loadPurchasedContentFromLocal(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsJson = prefs.getString('purchased_songs_$userId');
      if (songsJson != null) {
        final songsList = jsonDecode(songsJson) as List;
        _purchasedSongs = songsList.map((s) => Song.fromJson(s)).toList();
      }
      final albumsJson = prefs.getString('purchased_albums_$userId');
      if (albumsJson != null) {
        final albumsList = jsonDecode(albumsJson) as List;
        _purchasedAlbums = albumsList.map((a) => Album.fromJson(a)).toList();
      }
    } catch (e) {
      debugPrint('Error loading local content: $e');
    }
  }

  Future<void> _clearPurchasedContentFromLocal(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('purchased_songs_$userId');
      await prefs.remove('purchased_albums_$userId');
    } catch (e) {
      debugPrint('Error clearing local content: $e');
    }
  }

  Future<void> loadLibrary(int userId) async {
    _isLibraryLoading = true;
    notifyListeners();

    try {
      await _loadPurchasedContentFromLocal(userId);

      final response = await _libraryService.getUserLibrary(userId);
      if (response.success && response.data != null) {
        final library = response.data!;

        // Listas temporales
        List<Song> tempSongs = [];
        List<Album> tempAlbums = [];

        // Carga paralela para Library
        final songFutures = library.songs.map((item) async {
          final sRes = await _musicService.getSongById(item.itemId);
          if (sRes.success && sRes.data != null) {
            var song = sRes.data!;
            final aRes = await _musicService.getArtistById(song.artistId);
            if (aRes.success && aRes.data != null) {
              song = song.copyWith(
                  artistName: aRes.data!.artistName ?? aRes.data!.username);
            }
            return song;
          }
          return null;
        });

        final albumFutures = library.albums.map((item) async {
          final aRes = await _musicService.getAlbumById(item.itemId);
          if (aRes.success && aRes.data != null) {
            var album = aRes.data!;
            final arRes = await _musicService.getArtistById(album.artistId);
            if (arRes.success && arRes.data != null) {
              album = album.copyWith(
                  artistName: arRes.data!.artistName ?? arRes.data!.username);
            }
            return album;
          }
          return null;
        });

        final sResults = await Future.wait(songFutures);
        final aResults = await Future.wait(albumFutures);

        tempSongs = sResults.whereType<Song>().toList();
        tempAlbums = aResults.whereType<Album>().toList();

        _purchasedSongs = tempSongs;
        _purchasedAlbums = tempAlbums;

        await _savePurchasedContentToLocal(userId);
      }
    } catch (e) {
      debugPrint('Error loading library: $e');
    } finally {
      _isLibraryLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPurchasedSong(Song song, {int? userId}) async {
    if (!_purchasedSongs.any((s) => s.id == song.id)) {
      final artistResponse = await _musicService.getArtistById(song.artistId);
      if (artistResponse.success && artistResponse.data != null) {
        song = song.copyWith(
            artistName: artistResponse.data!.artistName ??
                artistResponse.data!.username);
      }
      _purchasedSongs.add(song);
      if (userId != null) await _savePurchasedContentToLocal(userId);
      notifyListeners();
    }
  }

  Future<void> addPurchasedAlbum(Album album, {int? userId}) async {
    if (!_purchasedAlbums.any((a) => a.id == album.id)) {
      final artistResponse = await _musicService.getArtistById(album.artistId);
      if (artistResponse.success && artistResponse.data != null) {
        album = album.copyWith(
            artistName: artistResponse.data!.artistName ??
                artistResponse.data!.username);
      }
      _purchasedAlbums.add(album);
      if (userId != null) await _savePurchasedContentToLocal(userId);
      notifyListeners();
    }
  }

  Future<void> addPurchasedContent(List<Song> songs, List<Album> albums,
      {int? userId}) async {
    bool changed = false;
    for (final song in songs) {
      if (!_purchasedSongs.any((s) => s.id == song.id)) {
        _purchasedSongs.add(song);
        changed = true;
      }
    }
    for (final album in albums) {
      if (!_purchasedAlbums.any((a) => a.id == album.id)) {
        _purchasedAlbums.add(album);
        changed = true;
      }
    }
    if (changed) {
      if (userId != null) await _savePurchasedContentToLocal(userId);
      notifyListeners();
    }
  }

  bool isSongPurchased(int songId) =>
      _purchasedSongs.any((s) => s.id == songId);
  bool isAlbumPurchased(int albumId) =>
      _purchasedAlbums.any((a) => a.id == albumId);

  Future<void> clearLibrary({int? userId}) async {
    _favoriteSongs.clear();
    _favoriteAlbums.clear();
    _playlists.clear();
    _purchasedSongs.clear();
    _purchasedAlbums.clear();
    if (userId != null) await _clearPurchasedContentFromLocal(userId);
    notifyListeners();
  }
}
