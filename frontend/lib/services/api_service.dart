import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "https://rude-papayas-jam.loca.lt/chat";

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

      if (response.statusCode != 200) {
        return "Server Error: ${response.statusCode}";
      }

      final data = jsonDecode(response.body);

      if (data is Map && data["success"] == true) {
        return data["reply"]?.toString() ?? "Lumoon didn't send a reply.";
      }

      return data["error"]?.toString() ?? "Unknown error from Lumoon.";
    } catch (e) {
      return "Connection Error: $e";
    }
  }
}