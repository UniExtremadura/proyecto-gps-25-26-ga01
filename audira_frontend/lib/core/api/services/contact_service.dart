import 'package:audira_frontend/core/api/api_client.dart';
import '../../models/contact_message.dart';

class ContactService {
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Send a contact message (no auth required - public access)
  Future<ApiResponse<Map<String, dynamic>>> sendContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
    int? userId,
    int? songId,
    int? albumId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/contact',
        body: {
          'name': name,
          'email': email,
          'subject': subject,
          'message': message,
          if (userId != null) 'userId': userId,
          if (songId != null) 'songId': songId,
          if (albumId != null) 'albumId': albumId,
        },
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        return ApiResponse(
          success: true,
          data: response.data as Map<String, dynamic>,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Fallo al enviar el mensaje de contacto',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get all contact messages (admin only)
  Future<ApiResponse<List<ContactMessage>>> getAllContactMessages() async {
    try {
      final response = await _apiClient.get('/api/contact', requiresAuth: true);

      if (response.success && response.data != null) {
        final List<dynamic> messagesJson = response.data as List<dynamic>;
        final messages = messagesJson
            .map(
                (json) => ContactMessage.fromJson(json as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          data: messages,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Fallo al obtener los mensajes de contacto',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get unread contact messages (admin only)
  Future<ApiResponse<List<ContactMessage>>> getUnreadContactMessages() async {
    try {
      final response =
          await _apiClient.get('/api/contact/unread', requiresAuth: true);

      if (response.success && response.data != null) {
        final List<dynamic> messagesJson = response.data as List<dynamic>;
        final messages = messagesJson
            .map(
                (json) => ContactMessage.fromJson(json as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          data: messages,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Fallo al obtener los mensajes no leídos',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get contact messages by user ID
  Future<ApiResponse<List<ContactMessage>>> getMessagesByUserId(
      int userId) async {
    try {
      final response =
          await _apiClient.get('/api/contact/user/$userId', requiresAuth: true);

      if (response.success && response.data != null) {
        final List<dynamic> messagesJson = response.data as List<dynamic>;
        final messages = messagesJson
            .map(
                (json) => ContactMessage.fromJson(json as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          data: messages,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Fallo al obtener los mensajes del usuario',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get contact message by ID (admin only)
  Future<ApiResponse<Map<String, dynamic>>> getContactMessage(int id) async {
    try {
      final response = await _apiClient.get('/api/contact/$id');

      if (response.success && response.data != null) {
        return ApiResponse(
          success: true,
          data: response.data as Map<String, dynamic>,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Fallo al obtener los contactos',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Mark contact message as read (admin only)
  Future<ApiResponse<void>> markAsRead(int id) async {
    try {
      final response =
          await _apiClient.put('/api/contact/$id', body: {'isRead': true});

      if (response.success) {
        return ApiResponse(
          success: true,
          data: null,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Fallo al marcar el mensaje como leído',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Update contact message status
  Future<ApiResponse<ContactMessage>> updateMessageStatus(
      int messageId, String status) async {
    try {
      final response = await _apiClient.patch(
        '/api/contact/$messageId/status',
        body: {'status': status},
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return ApiResponse(
          success: true,
          data: ContactMessage.fromJson(response.data as Map<String, dynamic>),
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Fallo al actualizar el estado del mensaje',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Delete contact message (admin only)
  Future<ApiResponse<void>> deleteContactMessage(int id) async {
    try {
      final response = await _apiClient.delete('/api/contact/$id');

      if (response.success) {
        return ApiResponse(
          success: true,
          data: null,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Fallo al eliminar el mensaje de contacto',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get responses for a specific contact message
  Future<ApiResponse<List<dynamic>>> getResponsesByMessageId(
      int messageId) async {
    try {
      final response = await _apiClient.get(
        '/api/contact/responses/message/$messageId',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        return ApiResponse(
          success: true,
          data: response.data as List<dynamic>,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Fallo al obtener las respuestas del mensaje',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Create a response to a contact message (admin only)
  Future<ApiResponse<Map<String, dynamic>>> createResponse({
    required int contactMessageId,
    required int adminId,
    required String adminName,
    required String response,
  }) async {
    try {
      final apiResponse = await _apiClient.post(
        '/api/contact/responses',
        body: {
          'contactMessageId': contactMessageId,
          'adminId': adminId,
          'adminName': adminName,
          'response': response,
        },
        requiresAuth: true,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return ApiResponse(
          success: true,
          data: apiResponse.data as Map<String, dynamic>,
          statusCode: apiResponse.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: apiResponse.error ?? 'Fallo al crear la respuesta',
        statusCode: apiResponse.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }
}
