import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoredChatMessage {
  final String text;
  final bool isUser;

  StoredChatMessage({
    required this.text,
    required this.isUser,
  });

  Map<String, dynamic> toJson() {
    return {
      "text": text,
      "isUser": isUser,
    };
  }

  factory StoredChatMessage.fromJson(Map<String, dynamic> json) {
    return StoredChatMessage(
      text: json["text"]?.toString() ?? "",
      isUser: json["isUser"] == true,
    );
  }
}

class ChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  List<StoredChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory ChatSession.create() {
    final now = DateTime.now();

    return ChatSession(
      id: now.microsecondsSinceEpoch.toString(),
      title: "New chat",
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "messages": messages.map((message) => message.toJson()).toList(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final rawMessages = json["messages"] as List? ?? [];

    return ChatSession(
      id: json["id"]?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json["title"]?.toString() ?? "New chat",
      createdAt: DateTime.tryParse(
            json["createdAt"]?.toString() ?? "",
          ) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
            json["updatedAt"]?.toString() ?? "",
          ) ??
          DateTime.now(),
      messages: rawMessages
          .whereType<Map>()
          .map(
            (message) => StoredChatMessage.fromJson(
              Map<String, dynamic>.from(message),
            ),
          )
          .toList(),
    );
  }
}

class ChatStorageService {
  static const String _storageKey = "lumoon_chat_sessions";

  Future<List<ChatSession>> loadSessions() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedData = preferences.getString(_storageKey);

      if (savedData == null || savedData.isEmpty) {
        return [];
      }

      final decodedData = jsonDecode(savedData) as List;

      final sessions = decodedData
          .whereType<Map>()
          .map(
            (session) => ChatSession.fromJson(
              Map<String, dynamic>.from(session),
            ),
          )
          .toList();

      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return sessions;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSessions(List<ChatSession> sessions) async {
    final preferences = await SharedPreferences.getInstance();

    final encodedData = jsonEncode(
      sessions.map((session) => session.toJson()).toList(),
    );

    await preferences.setString(_storageKey, encodedData);
  }
}