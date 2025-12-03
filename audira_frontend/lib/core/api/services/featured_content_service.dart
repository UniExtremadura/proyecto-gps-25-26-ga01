import '../api_client.dart';
import '../../models/featured_content.dart';

/// Service for managing featured content
/// GA01-156: Seleccionar/ordenar contenido destacado
class FeaturedContentService {
  final ApiClient _apiClient = ApiClient();

  /// Get all featured content (admin)
  /// GA01-156: Seleccionar/ordenar contenido destacado
  Future<ApiResponse<List<FeaturedContent>>> getAllFeaturedContent() async {
    final response = await _apiClient.get(
      '/api/featured-content',
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> contentJson = response.data as List<dynamic>;
        final content = contentJson
            .map((json) =>
                FeaturedContent.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: content);
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al parsear contenido destacado: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Create featured content
  /// GA01-156: Seleccionar/ordenar contenido destacado
  Future<ApiResponse<FeaturedContent>> createFeaturedContent(
      Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      '/api/featured-content',
      body: data,
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: FeaturedContent.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al crear contenido destacado: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Update featured content
  /// GA01-156: Seleccionar/ordenar contenido destacado
  /// GA01-157: Programación de destacados
  Future<ApiResponse<FeaturedContent>> updateFeaturedContent(
      int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      '/api/featured-content/$id',
      body: data,
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: FeaturedContent.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al actualizar contenido destacado: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Delete featured content
  /// GA01-156: Seleccionar/ordenar contenido destacado
  Future<ApiResponse<void>> deleteFeaturedContent(int id) async {
    final response = await _apiClient.delete(
      '/api/featured-content/$id',
      requiresAuth: true,
    );

    return ApiResponse(success: response.success, error: response.error);
  }

  /// Reorder featured content
  /// GA01-156: Seleccionar/ordenar contenido destacado
  Future<ApiResponse<List<FeaturedContent>>> reorderFeaturedContent(
      List<Map<String, dynamic>> orderData) async {
    final response = await _apiClient.put(
      '/api/featured-content/reorder',
      body: {'items': orderData},
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> contentJson = response.data as List<dynamic>;
        final content = contentJson
            .map((json) =>
                FeaturedContent.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: content);
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al reordenar contenido destacado: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Toggle active status
  /// GA01-156: Seleccionar/ordenar contenido destacado
  Future<ApiResponse<FeaturedContent>> toggleActive(
      int id, bool isActive) async {
    final response = await _apiClient.patch(
      '/api/featured-content/$id/toggle-active',
      body: {'isActive': isActive},
      requiresAuth: true,
    );

    if (response.success && response.data != null) {
      try {
        return ApiResponse(
          success: true,
          data: FeaturedContent.fromJson(response.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al cambiar estado: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get active featured content (public)
  /// GA01-157: Programación de destacados
  Future<ApiResponse<List<FeaturedContent>>> getActiveFeaturedContent() async {
    final response = await _apiClient.get(
      '/api/featured-content/active',
      requiresAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        final List<dynamic> contentJson = response.data as List<dynamic>;
        final content = contentJson
            .map((json) =>
                FeaturedContent.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse(success: true, data: content);
      } catch (e) {
        return ApiResponse(
          success: false,
          error: 'Error al parsear contenido destacado: $e',
        );
      }
    }
    return ApiResponse(success: false, error: response.error);
  }
}
