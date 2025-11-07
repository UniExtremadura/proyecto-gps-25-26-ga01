import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../api_client.dart';

class ImageUploadService {
  final String baseUrl;

  ImageUploadService(this.baseUrl);

  Future<ApiResponse<String>> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl/api/files/upload/image');
      final request = http.MultipartRequest('POST', uri);

      // Determinar content-type
      String contentType = 'image/jpeg';
      if (imageFile.path.endsWith('.png')) contentType = 'image/png';
      if (imageFile.path.endsWith('.webp')) contentType = 'image/webp';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(contentType),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final fileUrl = jsonResponse['fileUrl'] as String?;
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
      }

      return ApiResponse(
        success: false,
        error: 'Error al subir imagen',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Excepción: $e',
      );
    }
  }
}
