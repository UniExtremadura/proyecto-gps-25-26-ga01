import '../api_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../config/constants.dart';

class AudioService {
  final ApiClient _apiClient = ApiClient();

  /// Sube un archivo de audio al servidor.
  ///
  /// Parámetros:
  /// - [audioFile]: Archivo de audio a subir.
  /// - [songId]: ID opcional de la canción.
  ///
  /// Retorna: `Future<ApiResponse<String>>` con la URL del archivo subido.
  Future<ApiResponse<String>> uploadAudioFile(File audioFile, {int? songId}) async {
    try {
      // 1. Crear URI
      final uri = Uri.parse('${_apiClient.baseUrl}/api/files/upload/audio');

      // 2. Crear MultipartRequest con método POST
      final request = http.MultipartRequest('POST', uri);

      // 3. Determinar content-type según extensión
      final extension = audioFile.path.split('.').last.toLowerCase();
      String? contentType;
      switch (extension) {
        case 'mp3':
          contentType = 'audio/mpeg';
          break;
        case 'wav':
          contentType = 'audio/wav';
          break;
        case 'flac':
          contentType = 'audio/flac';
          break;
        case 'midi':
        case 'mid':
          contentType = 'audio/midi';
          break;
        default:
          return ApiResponse(
            success: false,
            error: 'Formato de audio no soportado: .$extension',
            statusCode: 400,
          );
      }

      // 4. Agregar archivo
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
        contentType: MediaType.parse(contentType),
      );
      request.files.add(multipartFile);

      // 5. Agregar songId si existe
      if (songId != null) {
        request.fields['songId'] = songId.toString();
      }

      // 6. Enviar request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      // 7. Manejar respuesta
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final fileUrl = data['fileUrl'] as String?;
        if (fileUrl != null) {
          return ApiResponse(
            success: true,
            data: fileUrl,
            statusCode: 200,
          );
        } else {
          return ApiResponse(
            success: false,
            error: 'Respuesta inválida del servidor',
            statusCode: 200,
          );
        }
      } else {
        String errorMessage = AppConstants.errorUnknownMessage;
        try {
          final errorData = jsonDecode(responseBody);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (_) {}
        return ApiResponse(
          success: false,
          error: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Excepción al subir archivo: $e',
      );
    }
  }
}
