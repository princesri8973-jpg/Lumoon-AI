import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMic;
  final VoidCallback onAttach;
  final VoidCallback onGenerate;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onMic,
    required this.onAttach,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          // ATTACH FILE
          IconButton(
            onPressed: onAttach,
            tooltip: "Attach file",
            icon: const Icon(
              Icons.attach_file,
              color: Colors.cyanAccent,
            ),
          ),

          // CREATE
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.auto_awesome,
              color: Colors.cyanAccent,
            ),
            tooltip: "Create with Lumoon",
            onSelected: (value) {
              if (value == "create") {
                onGenerate();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "create",
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome),
                    SizedBox(width: 10),
                    Text("Create file"),
                  ],
                ),
              ),
            ],
          ),

          // TEXT FIELD
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: Colors.white,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                onSend();
              },
              decoration: const InputDecoration(
                hintText: "Ask Lumoon...",
                hintStyle: TextStyle(
                  color: Colors.white54,
                ),
                border: InputBorder.none,
              ),
            ),
          ),

          // MICROPHONE
          IconButton(
            onPressed: onMic,
            tooltip: "Voice input",
            icon: const Icon(
              Icons.mic,
              color: Colors.cyanAccent,
            ),
          ),

          // SEND
          IconButton(
            onPressed: onSend,
            tooltip: "Send",
            icon: const Icon(
              Icons.send_rounded,
              color: Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }
}