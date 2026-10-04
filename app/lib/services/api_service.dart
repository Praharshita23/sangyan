import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================

  // Flutter Web / Chrome running on the same PC:
  static const String baseUrl = 'https://sangyan-bc16.onrender.com';

  // Android Emulator:
  // static const String baseUrl = 'http://10.0.2.2:8000';

  // Physical Android phone:
  // static const String baseUrl = 'http://YOUR_PC_IP:8000';


  // ============================================================
  // TEXT SCAN
  // ============================================================

  static Future<Map<String, dynamic>> scanMessage(
    String message,
  ) async {
    final trimmedMessage = message.trim();

    if (trimmedMessage.isEmpty) {
      throw Exception('Message cannot be empty.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/scan'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'message': trimmedMessage,
            }),
          )
          .timeout(
            const Duration(seconds: 60),
          );

      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Sangyan server.',
      );
    }
  }


  // ============================================================
  // IMAGE SCAN
  // ============================================================

  static Future<Map<String, dynamic>> scanImage(
    Uint8List imageBytes,
    String fileName,
  ) async {
    if (imageBytes.isEmpty) {
      throw Exception('Image is empty.');
    }

    final mimeType = _getMimeType(fileName);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/scan-image'),
      );

      request.headers['Accept'] = 'application/json';

      // IMPORTANT:
      // Explicitly tell FastAPI that this is an image.
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
          contentType: mimeType,
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
      );

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to upload image to Sangyan server.',
      );
    }
  }


  // ============================================================
  // LINK SCAN
  // ============================================================

  static Future<Map<String, dynamic>> scanLink(
    String url,
  ) async {
    final trimmedUrl = url.trim();

    if (trimmedUrl.isEmpty) {
      throw Exception('URL cannot be empty.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/scan-link'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'url': trimmedUrl,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Sangyan server.',
      );
    }
  }


  // ============================================================
  // MIME TYPE
  // ============================================================

  static MediaType _getMimeType(
    String fileName,
  ) {
    final lowerName = fileName.toLowerCase();

    if (lowerName.endsWith('.png')) {
      return MediaType(
        'image',
        'png',
      );
    }

    if (lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg')) {
      return MediaType(
        'image',
        'jpeg',
      );
    }

    if (lowerName.endsWith('.webp')) {
      return MediaType(
        'image',
        'webp',
      );
    }

    if (lowerName.endsWith('.gif')) {
      return MediaType(
        'image',
        'gif',
      );
    }

    if (lowerName.endsWith('.bmp')) {
      return MediaType(
        'image',
        'bmp',
      );
    }

    // Default to JPEG.
    return MediaType(
      'image',
      'jpeg',
    );
  }


  // ============================================================
  // RESPONSE HANDLER
  // ============================================================

  static Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    final statusCode = response.statusCode;

    Map<String, dynamic>? decoded;

    // ----------------------------------------------------------
    // Try to decode JSON
    // ----------------------------------------------------------

    if (response.body.isNotEmpty) {
      try {
        final json = jsonDecode(
          response.body,
        );

        if (json is Map<String, dynamic>) {
          decoded = json;
        }
      } catch (_) {
        decoded = null;
      }
    }

    // ----------------------------------------------------------
    // Successful response
    // ----------------------------------------------------------

    if (statusCode >= 200 && statusCode < 300) {
      if (decoded != null) {
        return decoded;
      }

      throw Exception(
        'Server returned an invalid response.',
      );
    }

    // ----------------------------------------------------------
    // Error message from FastAPI
    // ----------------------------------------------------------

    String errorMessage;

    if (decoded != null &&
        decoded['detail'] != null) {
      errorMessage = decoded['detail'].toString();
    } else if (decoded != null &&
        decoded['message'] != null) {
      errorMessage = decoded['message'].toString();
    } else {
      errorMessage =
          'Server error: $statusCode';
    }

    // ----------------------------------------------------------
    // Specific status codes
    // ----------------------------------------------------------

    switch (statusCode) {
      case 400:
        throw Exception(
          'Bad request: $errorMessage',
        );

      case 401:
        throw Exception(
          'Authentication error: $errorMessage',
        );

      case 403:
        throw Exception(
          'Access denied: $errorMessage',
        );

      case 404:
        throw Exception(
          'Sangyan API endpoint not found.',
        );

      case 422:
        throw Exception(
          'Invalid request data: $errorMessage',
        );

      case 429:
        throw Exception(
          'Too many requests. Please try again shortly.',
        );

      case 500:
        throw Exception(
          'Sangyan server error: $errorMessage',
        );

      case 502:
      case 503:
      case 504:
        throw Exception(
          'Sangyan server is temporarily unavailable. '
          'Please try again.',
        );

      default:
        throw Exception(
          errorMessage,
        );
    }
  }
}