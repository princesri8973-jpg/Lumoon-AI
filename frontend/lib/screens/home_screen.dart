import 'package:flutter/material.dart';
import '../services/api_service.dart';
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

  final List<ChatMessage> messages = [];

  bool isLoading = false;
  bool isListening = false;
  bool hasSentVoiceMessage = false;

  String spokenText = "";

  Future<void> sendMessage() async {
    final text = controller.text.trim();

    if (text.isEmpty || isLoading) return;

    await widget.voiceService.stop();
    controller.clear();

    setState(() {
      messages.add(
        ChatMessage(
          text: text,
          isUser: true,
        ),
      );

      isLoading = true;
    });

    final reply = await ApiService.askLumoon(text);

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

    await widget.voiceService.speak(reply);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Microphone access not available"),
        ),
      );
    }
  }

  Future<void> clearChat() async {
    await widget.voiceService.stop();
    await speechService.stopListening();

    setState(() {
      messages.clear();
      isListening = false;
    });
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
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              child: Row(
                children: [
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
                    onPressed: clearChat,
                    tooltip: "Clear chat",
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                6,
                12,
                12,
              ),
              child: ChatInput(
                controller: controller,
                onSend: sendMessage,
                onMic: micPressed,
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