import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../api/services/music_service.dart';
import '../api/services/library_service.dart';

enum RepeatMode { off, one, all }

class AudioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MusicService _musicService = MusicService();
  final LibraryService _libraryService = LibraryService();

  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isShuffleEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isDemoMode = false;
  bool _demoFinished = false;
  double _volume = 0.5; // Volume from 0.0 to 1.0
  bool _isSeekingInternally = false;
  int? _currentUserId; // Para verificar si la canción está comprada

  Song? get currentSong => _currentSong;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isShuffleEnabled => _isShuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isDemoMode => _isDemoMode;
  bool get demoFinished => _demoFinished;
  double get volume => _volume;
  double get progress => _totalDuration.inMilliseconds > 0
      ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
      : 0.0;

  AudioProvider() {
    _init();
  }

  void _init() async {
    // Configure audio session
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      debugPrint('✅ Sesión de audio configurada correctamente');
    } catch (e) {
      debugPrint('⚠️ Error configurando la sesión de audio: $e');
    }

    // Initialize volume to 50%
    await _audioPlayer.setVolume(_volume);

    _audioPlayer.positionStream.listen((position) {
      // 1. Ignorar si estamos en un seek manual
      if (_isSeekingInternally) {
        return;
      }

      // 2. MITIGACIÓN CRÍTICA: Ignorar micro-actualizaciones cerca del final (500ms)
      if (!_isDemoMode &&
          _totalDuration > Duration.zero &&
          position.inMilliseconds >= _totalDuration.inMilliseconds - 500) {
        return;
      }

      _currentPosition = position;

      // Lógica de modo Demo
      if (_isDemoMode) {
        debugPrint(
            '🎵 DEMO MODE - Posición: ${position.inSeconds} seg / isDemoMode: $_isDemoMode');
      }

      if (_isDemoMode && position.inSeconds >= 10) {
        debugPrint(
            '⏹️ DEMO Finalizada - Parando reproducción en ${position.inSeconds} seg');
        pause();
        seek(Duration.zero);
        _isDemoMode = false;
        _demoFinished = true;
        notifyListeners();
      }

      notifyListeners();
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration;
        notifyListeners();
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      if (state.processingState == ProcessingState.completed) {
        // CORRECCIÓN CRÍTICA: Forzar el reset síncrono del slider a 0
        _currentPosition = Duration.zero;
        notifyListeners();

        _handleSongCompletion();
      }

      notifyListeners();
    });
  }

  // Método para establecer el usuario actual (llamado desde la app)
  void setCurrentUser(int? userId) {
    _currentUserId = userId;
  }

  Future<void> playSong(Song song,
      {bool? demo, bool? isUserAuthenticated, int? userId}) async {
    _demoFinished = false;
    debugPrint('▶️ Reproduciendo canción - Canción: ${song.name}');
    debugPrint('   demo parameter: $demo');
    debugPrint('   isUserAuthenticated parameter: $isUserAuthenticated');
    debugPrint('   userId parameter: $userId');

    try {
      _currentSong = song;
      final artistResponse = await _musicService.getArtistById(song.artistId);
      if (artistResponse.success && artistResponse.data != null) {
        _currentSong = _currentSong?.copyWith(
            artistName: artistResponse.data!.artistName ??
                artistResponse.data!.username);
        notifyListeners();
      }

      // Usar userId si se proporciona, si no usar el guardado
      final effectiveUserId = userId ?? _currentUserId;

      // IMPORTANTE: Verificar si la canción está comprada para determinar modo demo
      bool isPurchased = false;
      if (effectiveUserId != null && isUserAuthenticated == true) {
        try {
          final response = await _libraryService.checkIfPurchased(
            effectiveUserId,
            'SONG',
            song.id,
          );
          isPurchased = response.data ?? false;
          debugPrint('   ✅ Verificación de compra: isPurchased=$isPurchased');
        } catch (e) {
          debugPrint('   ⚠️ Error verificando compra: $e');
          isPurchased = false;
        }
      }

      // Determinar modo demo:
      // - Si NO está autenticado: DEMO
      // - Si está autenticado pero NO ha comprado la canción: DEMO
      // - Si está autenticado Y ha comprado la canción: COMPLETO
      if (demo != null) {
        _isDemoMode = demo;
        debugPrint('   ✅ Demo mode forzado por parámetro: $_isDemoMode');
      } else if (isUserAuthenticated == false || !isPurchased) {
        _isDemoMode = true;
        debugPrint(
            '   ✅ Demo mode activado: user auth=$isUserAuthenticated, purchased=$isPurchased');
      } else {
        _isDemoMode = false;
        debugPrint(
            '   ✅ Modo completo: usuario autenticado y canción comprada');
      }

      debugPrint('   🎯 FINAL isDemoMode: $_isDemoMode');

      _queue = [song];
      _currentIndex = 0;

      if (song.audioUrl != null && song.audioUrl!.isNotEmpty) {
        debugPrint('   🔊 Configurando audio URL: ${song.audioUrl}');
        try {
          // Stop current playback if any
          await _audioPlayer.stop();

          // Set new audio source
          final duration = await _audioPlayer.setUrl(song.audioUrl!);
          debugPrint('   ✅ Audio cargado correctamente. Duración: $duration');

          // Start playback
          await _audioPlayer.play();
          debugPrint('   ▶️ Reproducción iniciada');

          // CRITICAL FIX: Increment play count for metrics tracking
          // This is fire-and-forget, we don't wait for the response
          debugPrint(
              '   📊 Attempting to increment play count for song ID: ${song.id}');
          _musicService.incrementPlays(song.id).then((response) {
            if (response.success && response.data != null) {
              debugPrint('   ✅ Play count incremented successfully!');
              debugPrint('      Song: ${song.name}');
              debugPrint('      New play count: ${response.data!.plays}');
            } else {
              debugPrint(
                  '   ❌ Failed to increment play count: ${response.error}');
            }
          }).catchError((error) {
            debugPrint('   ⚠️ Error incrementing play count: $error');
            // Don't fail playback if metrics fail
          });
        } catch (e) {
          debugPrint('   ❌ Error cargando/reproduciendo audio: $e');
          rethrow;
        }
      } else {
        debugPrint('   ⚠️ No hay URL de audio para esta canción: ${song.name}');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('   ❌ Error reproduciendo canción: $e');
    }
  }

  Future<void> playAlbum(Album album,
      {int startIndex = 0, bool? isUserAuthenticated, int? userId}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final songsResponse = await _musicService.getSongsByAlbum(album.id);
      if (songsResponse.success && songsResponse.data != null) {
        _queue = songsResponse.data!;
        _queue
            .sort((a, b) => (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0));

        if (_queue.isNotEmpty) {
          _currentIndex = startIndex;
          await playSong(_queue[_currentIndex],
              isUserAuthenticated: isUserAuthenticated, userId: userId);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('Error reproduciendo album: $e');
      notifyListeners();
    }
  }

  Future<void> playQueue(List<Song> songs,
      {int startIndex = 0, bool? isUserAuthenticated, int? userId}) async {
    try {
      if (songs.isEmpty) return;

      _queue = List.from(songs);
      _currentIndex = startIndex;
      await playSong(_queue[_currentIndex],
          isUserAuthenticated: isUserAuthenticated, userId: userId);
    } catch (e) {
      debugPrint('Error reproduciendo la cola: $e');
    }
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;

    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      // Mantener el mismo modo (demo o completo) al pasar a la siguiente canción
      await playSong(_queue[_currentIndex],
          isUserAuthenticated: _currentUserId != null, userId: _currentUserId);
    } else if (_repeatMode == RepeatMode.all) {
      _currentIndex = 0;
      await playSong(_queue[_currentIndex],
          isUserAuthenticated: _currentUserId != null, userId: _currentUserId);
    } else {
      await pause();
      await seek(Duration.zero);
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;

    if (_currentPosition.inSeconds > 3) {
      await seek(Duration.zero);
    } else if (_currentIndex > 0) {
      _currentIndex--;
      await playSong(_queue[_currentIndex],
          isUserAuthenticated: _currentUserId != null, userId: _currentUserId);
    } else if (_repeatMode == RepeatMode.all) {
      _currentIndex = _queue.length - 1;
      await playSong(_queue[_currentIndex],
          isUserAuthenticated: _currentUserId != null, userId: _currentUserId);
    }
  }

  Future<void> seek(Duration position) async {
    try {
      _isSeekingInternally = true;
      notifyListeners();

      await _audioPlayer.seek(position);

      _currentPosition = position;

      await Future.delayed(const Duration(milliseconds: 100));

      _isSeekingInternally = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during internal seek operation: $e');
      _isSeekingInternally = false;
      notifyListeners();
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    if (_isShuffleEnabled && _queue.length > 1) {
      final currentSong = _queue[_currentIndex];
      _queue.shuffle();
      _currentIndex = _queue.indexOf(currentSong);
    }
    notifyListeners();
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  void _handleSongCompletion() {
    switch (_repeatMode) {
      case RepeatMode.one:
        playSong(_queue[_currentIndex],
            isUserAuthenticated: _currentUserId != null,
            userId: _currentUserId);
        break;
      case RepeatMode.all:
        next(); // Ya está manejando la autenticación correctamente
        break;
      case RepeatMode.off:
        // Al terminar una canción en modo off, si hay más en la cola, reproducir siguiente
        if (_currentIndex < _queue.length - 1) {
          next();
        } else {
          // Si era la última, pausar
          pause();
          seek(Duration.zero);
        }
        break;
    }
  }

  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;

    if (index == _currentIndex) {
      next();
    } else if (index < _currentIndex) {
      _currentIndex--;
    }

    _queue.removeAt(index);
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = 0;
    _currentSong = null;
    pause();
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> setUrl(String url) async {
    await _audioPlayer.setUrl(url);
  }

  Future<void> resume() async {
    await play();
  }
}
