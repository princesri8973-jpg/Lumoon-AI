import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://lumoon-ai.onrender.com/chat";

  static Future<String> askLumoon(String prompt) async {
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

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _readResponse(response);
    } catch (e) {
      return "File send panna mudila macha: $e";
    }
  }

  static String _readResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return data["error"]?.toString() ??
            "Server Error: ${response.statusCode}";
      }

      if (data is Map && data["success"] == true) {
        return data["reply"]?.toString() ??
            "Lumoon reply anuppala.";
      }

      return data["error"]?.toString() ?? "Unknown error from Lumoon.";
    } catch (_) {
      return "Server Error: ${response.statusCode}";
    }
  }
}