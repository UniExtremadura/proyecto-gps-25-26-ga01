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
  bool _isUserAuthenticated =
      false; // Nuevo: para saber si el usuario está autenticado
  double _volume = 0.5; // Volume from 0.0 to 1.0
  bool _isSeekingInternally = false;
  int? _currentUserId; // Para verificar si la canción está comprada
  List<Song> _originalQueue = []; // Cola original antes de shuffle
  final Set<int> _playedSongsInShuffle = {}; // Para evitar repetir en shuffle
  bool _queueIsDownloaded =
      false; // Si la cola actual es de canciones descargadas
  bool _queueIsPurchased =
      false; // Si la cola es de biblioteca (canciones compradas)
  bool _miniPlayerVisible = true; // Controla la visibilidad del miniplayer

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
  bool get isUserAuthenticated => _isUserAuthenticated; // Nuevo getter
  double get volume => _volume;
  bool get miniPlayerVisible => _miniPlayerVisible;
  double get progress => _totalDuration.inMilliseconds > 0
      ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
      : 0.0;

  void toggleMiniPlayerVisibility() {
    _miniPlayerVisible = !_miniPlayerVisible;
    notifyListeners();
  }

  void showMiniPlayer() {
    _miniPlayerVisible = true;
    notifyListeners();
  }

  void hideMiniPlayer() {
    _miniPlayerVisible = false;
    notifyListeners();
  }

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
      // 1. CRÍTICO: Ignorar COMPLETAMENTE si estamos haciendo seek
      if (_isSeekingInternally) {
        return;
      }

      // 2. MITIGACIÓN: Ignorar actualizaciones muy cerca del final (para evitar glitches)
      if (!_isDemoMode &&
          _totalDuration > Duration.zero &&
          position.inMilliseconds >= _totalDuration.inMilliseconds - 500) {
        return;
      }

      // 3. Actualizar posición solo si cambió significativamente (>= 100ms)
      if ((position.inMilliseconds - _currentPosition.inMilliseconds).abs() <
          100) {
        return;
      }

      _currentPosition = position;

      // Lógica de modo Demo
      if (_isDemoMode && position.inSeconds >= 10) {
        debugPrint(
            '⏹️ DEMO Finalizada - Parando reproducción en ${position.inSeconds} seg');
        pause();
        seek(Duration.zero);
        _isDemoMode = false;
        _demoFinished = true;
        notifyListeners();
        return;
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
    _isUserAuthenticated = userId != null;
  }

  Future<void> playSong(Song song,
      {bool? demo,
      bool? isUserAuthenticated,
      int? userId,
      bool isDownloaded = false,
      bool maintainQueue = false}) async {
    _demoFinished = false;
    debugPrint('▶️ Reproduciendo canción - Canción: ${song.name}');
    debugPrint('   demo parameter: $demo');
    debugPrint('   isUserAuthenticated parameter: $isUserAuthenticated');
    debugPrint('   userId parameter: $userId');
    debugPrint('   isDownloaded parameter: $isDownloaded');
    debugPrint('   maintainQueue parameter: $maintainQueue');

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

      // Actualizar estado de autenticación
      if (isUserAuthenticated != null) {
        _isUserAuthenticated = isUserAuthenticated;
      }

      // IMPORTANTE: Verificar si la canción está comprada para determinar modo demo
      bool isPurchased = false;

      // Si está descargada, automáticamente se considera comprada
      if (isDownloaded || _queueIsDownloaded) {
        isPurchased = true;
        debugPrint('   ✅ Canción descargada - considerada como comprada');
      }
      // Si la cola es de biblioteca (canciones compradas), también se considera comprada
      else if (_queueIsPurchased) {
        isPurchased = true;
        debugPrint(
            '   ✅ Cola de biblioteca - canción considerada como comprada');
      }
      // Si no, verificar individualmente
      else if (effectiveUserId != null &&
          (isUserAuthenticated ?? _isUserAuthenticated)) {
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
      // - Si está descargada: COMPLETO
      if (demo != null) {
        _isDemoMode = demo;
        debugPrint('   ✅ Demo mode forzado por parámetro: $_isDemoMode');
      } else if (!(isUserAuthenticated ?? _isUserAuthenticated) ||
          !isPurchased) {
        _isDemoMode = true;
        debugPrint(
            '   ✅ Demo mode activado: user auth=${isUserAuthenticated ?? _isUserAuthenticated}, purchased=$isPurchased');
      } else {
        _isDemoMode = false;
        debugPrint(
            '   ✅ Modo completo: usuario autenticado y canción comprada/descargada');
      }

      debugPrint('   🎯 FINAL isDemoMode: $_isDemoMode');

      // CORRECCIÓN CRÍTICA: Solo crear nueva cola si NO se solicita mantenerla
      if (!maintainQueue) {
        _queue = [song];
        _currentIndex = 0;
        _originalQueue = [song];
        debugPrint('   🔄 Cola reiniciada con una sola canción');
      } else {
        debugPrint(
            '   ✅ Manteniendo cola existente de ${_queue.length} canciones');
      }

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

      debugPrint('🎵 PLAYALBUM: Cargando canciones del álbum ${album.name}');

      final songsResponse = await _musicService.getSongsByAlbum(album.id);
      if (songsResponse.success && songsResponse.data != null) {
        _queue = songsResponse.data!;
        _queue
            .sort((a, b) => (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0));
        _originalQueue = List.from(_queue); // Guardar cola original

        debugPrint('   ✅ ${_queue.length} canciones cargadas');

        if (_queue.isNotEmpty) {
          _currentIndex = startIndex;

          // Si shuffle está activado, mezclar
          if (_isShuffleEnabled) {
            debugPrint('   🔀 Shuffle activado, mezclando cola');
            _applyShuffleToQueue();
          }

          debugPrint('   ▶️ Reproduciendo canción en índice $_currentIndex');
          await playSong(_queue[_currentIndex],
              isUserAuthenticated: isUserAuthenticated,
              userId: userId,
              maintainQueue: true); // CRÍTICO: Mantener la cola del álbum
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
      {int startIndex = 0,
      bool? isUserAuthenticated,
      int? userId,
      bool areDownloaded = false,
      bool arePurchased = false}) async {
    try {
      if (songs.isEmpty) return;

      debugPrint(
          '🎵 PLAYQUEUE: Iniciando cola con ${songs.length} canciones desde índice $startIndex');
      debugPrint(
          '   areDownloaded: $areDownloaded, arePurchased: $arePurchased');

      _queue = List.from(songs);
      _originalQueue = List.from(songs);
      _currentIndex = startIndex;
      _queueIsDownloaded = areDownloaded; // Guardar si es cola de descargas
      _queueIsPurchased =
          arePurchased || areDownloaded; // Si está descargada, está comprada

      // Si shuffle está activado, mezclar desde el índice actual
      if (_isShuffleEnabled) {
        debugPrint('   🔀 Shuffle activado, mezclando cola');
        _applyShuffleToQueue();
      }

      debugPrint(
          '   ▶️ Reproduciendo canción en índice $_currentIndex: ${_queue[_currentIndex].name}');

      await playSong(_queue[_currentIndex],
          isUserAuthenticated: isUserAuthenticated,
          userId: userId,
          isDownloaded: areDownloaded,
          maintainQueue:
              true); // CRÍTICO: Mantener la cola que acabamos de crear
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

    debugPrint(
        '🔄 NEXT: currentIndex=$_currentIndex, queueLength=${_queue.length}');

    // En modo shuffle con repeat all, elegir siguiente canción aleatoria sin repetir la actual
    if (_isShuffleEnabled && _repeatMode == RepeatMode.all) {
      _playNextShuffledSong();
      return;
    }

    // Navegación normal en la cola
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      debugPrint('   ▶️ Avanzando a índice $_currentIndex');
      await playSong(_queue[_currentIndex],
          isUserAuthenticated: _isUserAuthenticated,
          userId: _currentUserId,
          isDownloaded: _queueIsDownloaded,
          maintainQueue: true); // CRÍTICO: Mantener la cola
    } else if (_repeatMode == RepeatMode.all) {
      // Volver al inicio
      _currentIndex = 0;
      debugPrint('   🔁 Volviendo al inicio (repeat all)');
      await playSong(_queue[_currentIndex],
          isUserAuthenticated: _isUserAuthenticated,
          userId: _currentUserId,
          isDownloaded: _queueIsDownloaded,
          maintainQueue: true); // CRÍTICO: Mantener la cola
    } else {
      // No hay más canciones, pausar
      debugPrint('   ⏹️ Fin de la cola, pausando');
      await pause();
      await seek(Duration.zero);
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;

    debugPrint(
        '⏮️ PREVIOUS: currentIndex=$_currentIndex, position=${_currentPosition.inSeconds}s');

    // Si llevamos más de 3 segundos, reiniciar canción actual
    if (_currentPosition.inSeconds > 3) {
      debugPrint('   ⏮️ Reiniciando canción actual (>3s)');
      await seek(Duration.zero);
      return;
    }

    // Ir a canción anterior
    if (_currentIndex > 0) {
      _currentIndex--;
      debugPrint('   ⏮️ Retrocediendo a índice $_currentIndex');
      await playSong(_queue[_currentIndex],
          isUserAuthenticated: _isUserAuthenticated,
          userId: _currentUserId,
          isDownloaded: _queueIsDownloaded,
          maintainQueue: true); // CRÍTICO: Mantener la cola
    } else if (_repeatMode == RepeatMode.all) {
      // Si estamos en el primero y repeat all está activo, ir al último
      _currentIndex = _queue.length - 1;
      debugPrint('   🔁 Yendo al final de la cola (repeat all)');
      await playSong(_queue[_currentIndex],
          isUserAuthenticated: _isUserAuthenticated,
          userId: _currentUserId,
          isDownloaded: _queueIsDownloaded,
          maintainQueue: true); // CRÍTICO: Mantener la cola
    } else {
      // Si estamos en el primero sin repeat, reiniciar la canción
      debugPrint('   ⏮️ Reiniciando primera canción');
      await seek(Duration.zero);
    }
  }

  Future<void> seek(Duration position) async {
    try {
      final targetPosition = Duration(
        milliseconds:
            position.inMilliseconds.clamp(0, _totalDuration.inMilliseconds),
      );

      debugPrint(
          '⏩ SEEK INICIO: ${targetPosition.inSeconds}s (${_isPlaying ? "reproduciendo" : "pausado"})');

      // Marcar que estamos haciendo seek
      _isSeekingInternally = true;

      // Guardar estado ANTES del seek
      final wasPlaying = _isPlaying;

      // Si está reproduciendo, NO pausar - just_audio maneja el seek mientras reproduce
      // Realizar el seek
      await _audioPlayer.seek(targetPosition);

      // Actualizar posición local inmediatamente para feedback visual
      _currentPosition = targetPosition;
      notifyListeners();

      // Esperar mínimamente para que el seek se procese
      await Future.delayed(const Duration(milliseconds: 100));

      // GARANTIZAR que continúe reproduciendo si estaba reproduciendo
      if (wasPlaying) {
        // Obtener estado actual del reproductor
        final playerState = _audioPlayer.playerState;
        final isCurrentlyPlaying = playerState.playing;

        if (!isCurrentlyPlaying) {
          debugPrint('   🔄 FORZANDO reanudación de reproducción');
          try {
            await _audioPlayer.play();
            // Esperar un poco más para confirmar que arrancó
            await Future.delayed(const Duration(milliseconds: 50));
          } catch (e) {
            debugPrint('   ⚠️ Error al reanudar: $e');
          }
        } else {
          debugPrint('   ✅ Reproducción continua confirmada');
        }
      }

      // Desmarcar seeking
      _isSeekingInternally = false;
      notifyListeners();

      debugPrint(
          '   ✅ SEEK COMPLETADO: ${targetPosition.inSeconds}s - Estado final: ${_isPlaying ? "reproduciendo" : "pausado"}');
    } catch (e) {
      debugPrint('❌ ERROR CRÍTICO en seek: $e');
      _isSeekingInternally = false;
      notifyListeners();
      // No hacer rethrow para evitar crashes en la UI
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

    if (_isShuffleEnabled) {
      // Activar shuffle: mezclar cola manteniendo la canción actual como primera
      _applyShuffleToQueue();
    } else {
      // Desactivar shuffle: restaurar orden original
      _restoreOriginalQueue();
    }

    notifyListeners();
  }

  void _applyShuffleToQueue() {
    if (_queue.length <= 1) return;

    // Guardar canción actual
    final currentSong = _queue[_currentIndex];

    // Crear cola mezclada excluyendo la canción actual
    List<Song> remainingSongs = List.from(_queue);
    remainingSongs.removeAt(_currentIndex);
    remainingSongs.shuffle();

    // Reconstruir cola: actual primero + resto mezclado
    _queue = [currentSong, ...remainingSongs];
    _currentIndex = 0; // La actual está ahora en posición 0
    _playedSongsInShuffle.clear();
    _playedSongsInShuffle.add(currentSong.id);
  }

  void _restoreOriginalQueue() {
    if (_originalQueue.isEmpty) return;

    // Encontrar la canción actual en la cola original
    final currentSong = _currentSong;
    if (currentSong != null) {
      _queue = List.from(_originalQueue);
      _currentIndex = _queue.indexWhere((s) => s.id == currentSong.id);
      if (_currentIndex == -1) _currentIndex = 0;
    }
    _playedSongsInShuffle.clear();
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
    debugPrint(
        '🎵 Canción completada - Modo repeat: $_repeatMode, Shuffle: $_isShuffleEnabled');

    switch (_repeatMode) {
      case RepeatMode.one:
        // Repetir la misma canción
        debugPrint('   🔁 Repetir una canción');
        playSong(_queue[_currentIndex],
            isUserAuthenticated: _isUserAuthenticated,
            userId: _currentUserId,
            isDownloaded: _queueIsDownloaded,
            maintainQueue: true); // CRÍTICO: Mantener la cola
        break;
      case RepeatMode.all:
        // Continuar con siguiente (maneja shuffle internamente)
        debugPrint('   🔁 Repeat all - siguiente canción');
        next();
        break;
      case RepeatMode.off:
        // Al terminar una canción en modo off, si hay más en la cola, reproducir siguiente
        if (_currentIndex < _queue.length - 1) {
          debugPrint('   ▶️ Siguiente canción (modo off)');
          next();
        } else {
          // Si era la última, pausar
          debugPrint('   ⏹️ Última canción, pausando');
          pause();
          seek(Duration.zero);
        }
        break;
    }
  }

  // Método helper para reproducir siguiente canción aleatoria en shuffle
  Future<void> _playNextShuffledSong() async {
    if (_queue.length <= 1) {
      // Solo hay una canción, repetirla
      debugPrint('   🔀 Shuffle: Solo 1 canción, repitiendo');
      await playSong(_queue[0],
          isUserAuthenticated: _isUserAuthenticated,
          userId: _currentUserId,
          isDownloaded: _queueIsDownloaded,
          maintainQueue: true); // CRÍTICO: Mantener la cola
      return;
    }

    // Elegir siguiente canción que no sea la actual
    List<int> availableIndices = [];
    for (int i = 0; i < _queue.length; i++) {
      if (i != _currentIndex) {
        availableIndices.add(i);
      }
    }

    if (availableIndices.isEmpty) {
      // Caso extremo: solo reproducir la actual
      debugPrint('   🔀 Shuffle: Sin índices disponibles, repitiendo actual');
      await playSong(_queue[_currentIndex],
          isUserAuthenticated: _isUserAuthenticated,
          userId: _currentUserId,
          isDownloaded: _queueIsDownloaded,
          maintainQueue: true); // CRÍTICO: Mantener la cola
      return;
    }

    // Elegir índice aleatorio de los disponibles
    availableIndices.shuffle();
    _currentIndex = availableIndices.first;
    debugPrint('   🔀 Shuffle: Seleccionando índice aleatorio $_currentIndex');

    await playSong(_queue[_currentIndex],
        isUserAuthenticated: _isUserAuthenticated,
        userId: _currentUserId,
        isDownloaded: _queueIsDownloaded,
        maintainQueue: true); // CRÍTICO: Mantener la cola
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
