import '../api_client.dart';
import '../../models/song.dart';

/// GA01-162 y GA01-163: Servicio para moderación de contenido
/// Permite a los administradores aprobar/rechazar contenido
/// y consultar el historial de moderaciones
class ModerationService {
  final ApiClient _apiClient = ApiClient();

  // ============= GA01-162: Aprobar/Rechazar =============

  /// Aprobar una canción
  Future<ApiResponse<Song>> approveSong(int songId, int adminId,
      {String? notes}) async {
    final response = await _apiClient.post(
      '/api/moderation/songs/$songId/approve',
      body: {
        'adminId': adminId,
        'notes': notes,
      },
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: Song.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al parsear canción: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Rechazar una canción
  Future<ApiResponse<Song>> rejectSong(
      int songId, int adminId, String rejectionReason,
      {String? notes}) async {
    final response = await _apiClient.post(
      '/api/moderation/songs/$songId/reject',
      body: {
        'adminId': adminId,
        'rejectionReason': rejectionReason,
        'notes': notes,
      },
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: Song.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al parsear canción: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Aprobar un álbum
  Future<ApiResponse<Map<String, dynamic>>> approveAlbum(int albumId, int adminId,
      {String? notes}) async {
    final response = await _apiClient.post(
      '/api/moderation/albums/$albumId/approve',
      body: {
        'adminId': adminId,
        'notes': notes,
      },
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      return ApiResponse(
          success: true, data: response.data as Map<String, dynamic>);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Rechazar un álbum
  Future<ApiResponse<Map<String, dynamic>>> rejectAlbum(
      int albumId, int adminId, String rejectionReason,
      {String? notes}) async {
    final response = await _apiClient.post(
      '/api/moderation/albums/$albumId/reject',
      body: {
        'adminId': adminId,
        'rejectionReason': rejectionReason,
        'notes': notes,
      },
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      return ApiResponse(
          success: true, data: response.data as Map<String, dynamic>);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Obtener canciones pendientes de moderación
  Future<ApiResponse<List<Song>>> getPendingSongs() async {
    final response = await _apiClient.get(
      '/api/moderation/songs/pending',
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> songsJson = response.data as List<dynamic>;
        final songs = songsJson
            .map((json) => Song.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: songs);
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al parsear canciones: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Obtener álbumes pendientes de moderación
  Future<ApiResponse<List<Map<String, dynamic>>>> getPendingAlbums() async {
    final response = await _apiClient.get(
      '/api/moderation/albums/pending',
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> albumsJson = response.data as List<dynamic>;
        final albums = albumsJson
            .map((json) => json as Map<String, dynamic>)
            .toList();
        return ApiResponse(success: true, data: albums);
      } catch (e) {
        return ApiResponse(
            success: false, error: 'Error al parsear álbumes: $e');
      }
    }
    return ApiResponse(success: false, error: response.error);
  }
}
