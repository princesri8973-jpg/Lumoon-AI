import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/chat_storage_service.dart';
import '../services/speech_service.dart';
import '../services/voice_service.dart';
import '../widgets/chat_input.dart';

class HomeScreen extends StatefulWidget {
  final VoiceService voiceService;

  const HomeScreen({
    super.key,
    required this.voiceService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController controller = TextEditingController();
  final SpeechService speechService = SpeechService();
  final ChatStorageService chatStorageService = ChatStorageService();

  final List<ChatMessage> messages = [];
  List<ChatSession> chatSessions = [];

  late ChatSession currentSession;
  PlatformFile? selectedFile;

  bool isLoading = false;
  bool isListening = false;
  bool hasSentVoiceMessage = false;
  bool isMuted = false;

  String spokenText = "";

  @override
  void initState() {
    super.initState();
    currentSession = ChatSession.create();
    loadChatSessions();
  }

  Future<void> loadChatSessions() async {
    final loadedSessions = await chatStorageService.loadSessions();

    if (!mounted) return;

    setState(() {
      chatSessions = loadedSessions;
    });
  }

  Future<void> saveCurrentChat() async {
    if (messages.isEmpty) return;

    currentSession.messages = messages
        .map(
          (message) => StoredChatMessage(
            text: message.text,
            isUser: message.isUser,
          ),
        )
        .toList();

    currentSession.updatedAt = DateTime.now();

    final firstUserMessage = messages.where((message) => message.isUser).firstOrNull;

    if (firstUserMessage != null) {
      String title = firstUserMessage.text
          .replaceAll("\n", " ")
          .replaceAll("📎", "")
          .trim();

      if (title.length > 28) {
        title = "${title.substring(0, 28)}...";
      }

      if (title.isNotEmpty) {
        currentSession.title = title;
      }
    }

    chatSessions.removeWhere((chat) => chat.id == currentSession.id);
    chatSessions.insert(0, currentSession);

    await chatStorageService.saveSessions(chatSessions);
  }

  Future<void> sendMessage() async {
    final typedText = controller.text.trim();
    final attachedFile = selectedFile;

    if ((typedText.isEmpty && attachedFile == null) || isLoading) {
      return;
    }

    if (attachedFile != null && attachedFile.path == null) {
      showMessage("File read panna mudila. Marubadiyum select pannu macha.");
      return;
    }

    await widget.voiceService.stop();

    final prompt = typedText.isEmpty
        ? "Indha attached file-a simple Tanglish-la explain pannu. Important points-um kudu."
        : typedText;

    final displayText = attachedFile == null
        ? prompt
        : "📎 ${attachedFile.name}\n$prompt";

    controller.clear();

    setState(() {
      messages.add(
        ChatMessage(
          text: displayText,
          isUser: true,
        ),
      );

      selectedFile = null;
      isLoading = true;
    });

    await saveCurrentChat();

    final reply = attachedFile == null
        ? await ApiService.askLumoon(prompt)
        : await ApiService.askLumoonWithFile(
            prompt: prompt,
            filePath: attachedFile.path!,
          );

    if (!mounted) return;

    setState(() {
      messages.add(
        ChatMessage(
          text: reply,
          isUser: false,
        ),
      );

      isLoading = false;
    });

    await saveCurrentChat();

    if (!isMuted) {
      await widget.voiceService.speak(reply);
    }
  }

  Future<void> pickAttachment() async {
    if (isLoading) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        "pdf",
        "doc",
        "docx",
        "xls",
        "xlsx",
        "ppt",
        "pptx",
        "txt",
        "csv",
        "png",
        "jpg",
        "jpeg",
        "webp",
        "mp4",
        "mov",
        "webm",
      ],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    const maxFileSize = 20 * 1024 * 1024;

    if (file.size > maxFileSize) {
      showMessage("20 MB-kulla irukkura file mattum select pannu macha.");
      return;
    }

    setState(() {
      selectedFile = file;
    });
  }

  Future<void> micPressed() async {
    if (isLoading) return;

    if (isListening) {
      await speechService.stopListening();
      return;
    }

    await widget.voiceService.stop();

    spokenText = "";
    hasSentVoiceMessage = false;

    final started = await speechService.startListening(
      onResult: (text) {
        if (!mounted) return;

        setState(() {
          spokenText = text;
          controller.text = text;
        });
      },
      onListeningStopped: () {
        if (!mounted) return;

        setState(() {
          isListening = false;
        });

        if (spokenText.trim().isNotEmpty && !hasSentVoiceMessage) {
          hasSentVoiceMessage = true;
          sendMessage();
        }
      },
    );

    if (!mounted) return;

    setState(() {
      isListening = started;
    });

    if (!started) {
      showMessage("Microphone access available illa macha.");
    }
  }

  Future<void> createNewChat() async {
    await widget.voiceService.stop();
    await speechService.stopListening();

    setState(() {
      messages.clear();
      selectedFile = null;
      currentSession = ChatSession.create();
      isListening = false;
    });
  }

  Future<void> openChat(ChatSession session) async {
    await widget.voiceService.stop();
    await speechService.stopListening();

    setState(() {
      currentSession = session;
      selectedFile = null;
      isListening = false;

      messages
        ..clear()
        ..addAll(
          session.messages.map(
            (message) => ChatMessage(
              text: message.text,
              isUser: message.isUser,
            ),
          ),
        );
    });
  }

  Future<void> deleteChat(ChatSession session) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text(
            "Delete chat?",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "\"${session.title}\" chat delete aagum.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      chatSessions.removeWhere((chat) => chat.id == session.id);

      if (currentSession.id == session.id) {
        messages.clear();
        selectedFile = null;
        currentSession = ChatSession.create();
      }
    });

    await chatStorageService.saveSessions(chatSessions);
  }

  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });

    if (isMuted) {
      widget.voiceService.stop();
      showMessage("Lumoon voice muted.");
    } else {
      showMessage("Lumoon voice unmuted.");
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey.shade900,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    speechService.stopListening();
    widget.voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: buildChatDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white24,
                            size: 55,
                          ),
                          SizedBox(height: 15),
                          Text(
                            "Start a conversation with Lumoon",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return ChatBubble(
                          message: messages[index],
                        );
                      },
                    ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Lumoon is thinking...",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isListening)
              const Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(
                        Icons.mic,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Listening...",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (selectedFile != null)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 5),
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.40),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.attach_file,
                      color: Colors.cyanAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedFile!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          selectedFile = null;
                        });
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: ChatInput(
                controller: controller,
                onSend: sendMessage,
                onMic: micPressed,
                onAttach: pickAttachment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      child: Row(
        children: [
          Builder(
            builder: (scaffoldContext) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(scaffoldContext).openDrawer();
                },
                tooltip: "Saved chats",
                icon: const Icon(
                  Icons.menu,
                  color: Colors.white70,
                ),
              );
            },
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyan.withOpacity(0.15),
              border: Border.all(
                color: Colors.cyanAccent,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.cyan,
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.memory,
              color: Colors.cyanAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "LUMOON",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "AI Core Online",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: createNewChat,
            tooltip: "New chat",
            icon: const Icon(
              Icons.edit_square,
              color: Colors.cyanAccent,
            ),
          ),
          IconButton(
            onPressed: toggleMute,
            tooltip: isMuted ? "Unmute voice" : "Mute voice",
            icon: Icon(
              isMuted ? Icons.volume_off : Icons.volume_up,
              color: isMuted ? Colors.white54 : Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChatDrawer() {
    return Drawer(
      backgroundColor: Colors.grey.shade950,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.memory,
                    color: Colors.cyanAccent,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Lumoon Chats",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await createNewChat();
                  },
                  icon: const Icon(Icons.edit_square),
                  label: const Text("New chat"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyanAccent,
                    side: const BorderSide(color: Colors.cyanAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.white12),
            Expanded(
              child: chatSessions.isEmpty
                  ? const Center(
                      child: Text(
                        "Saved chats inga varum.",
                        style: TextStyle(color: Colors.white38),
                      ),
                    )
                  : ListView.builder(
                      itemCount: chatSessions.length,
                      itemBuilder: (context, index) {
                        final chat = chatSessions[index];
                        final isCurrent = chat.id == currentSession.id;

                        return ListTile(
                          selected: isCurrent,
                          selectedTileColor: Colors.cyan.withOpacity(0.12),
                          leading: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.cyanAccent,
                            size: 20,
                          ),
                          title: Text(
                            chat.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: IconButton(
                            onPressed: () => deleteChat(chat),
                            tooltip: "Delete chat",
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            await openChat(chat);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.cyan.withOpacity(0.12)
              : Colors.grey.shade900,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: Border.all(
            color: isUser
                ? Colors.cyanAccent.withOpacity(0.45)
                : Colors.white12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person_outline : Icons.memory,
                  size: 18,
                  color: Colors.cyanAccent,
                ),
                const SizedBox(width: 7),
                Text(
                  isUser ? "You" : "Lumoon",
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;

    if (iterator.moveNext()) {
      return iterator.current;
    }

    return null;
  }
}