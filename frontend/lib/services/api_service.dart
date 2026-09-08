import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "https://lumoon-ai.onrender.com/chat";

  // ============================================================
  // NORMAL CHAT
  // ============================================================

  static Future<String> askLumoon(
    String prompt,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "prompt": prompt,
        }),
      );

      return _readResponse(response);
    } catch (e) {
      return "Connection Error: $e";
    }
  }

  // ============================================================
  // CHAT WITH FILE
  // ============================================================

  static Future<String> askLumoonWithFile({
    required String prompt,
    required String filePath,
  }) async {
    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse(baseUrl),
      );

      request.fields["prompt"] = prompt;

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          filePath,
        ),
      );

      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      return _readResponse(response);
    } catch (e) {
      return "File send panna mudila macha: $e";
    }
  }

  // ============================================================
  // WORD / EXCEL / POWERPOINT / IMAGE
  // ============================================================

  static Future<Map<String, dynamic>> generateFile({
    required String type,
    required String prompt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          "https://lumoon-ai.onrender.com/generate/$type",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "prompt": prompt,
        }),
      );

      final dynamic decoded =
          jsonDecode(response.body);

      if (response.statusCode != 200) {
        if (decoded is Map) {
          return {
            "success": false,
            "error":
                decoded["error"]?.toString() ??
                    "File generation failed.",
          };
        }

        return {
          "success": false,
          "error":
              "File generation failed.",
        };
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }

      return {
        "success": false,
        "error":
            "Invalid response from server.",
      };
    } catch (e) {
      return {
        "success": false,
        "error":
            "Generation connection error: $e",
      };
    }
  }

  // ============================================================
  // RESPONSE READER
  // ============================================================

  static String _readResponse(
    http.Response response,
  ) {
    try {
      final dynamic decoded =
          jsonDecode(response.body);

      if (response.statusCode != 200) {
        if (decoded is Map) {
          return decoded["error"]?.toString() ??
              "Server Error: ${response.statusCode}";
        }

        return "Server Error: ${response.statusCode}";
      }

      if (decoded is Map &&
          decoded["success"] == true) {
        return decoded["reply"]?.toString() ??
            "Lumoon reply anuppala.";
      }

      if (decoded is Map) {
        return decoded["error"]?.toString() ??
            "Unknown error from Lumoon.";
      }

      return "Unknown response from Lumoon.";
    } catch (_) {
      return "Server Error: ${response.statusCode}";
    }
  }
}