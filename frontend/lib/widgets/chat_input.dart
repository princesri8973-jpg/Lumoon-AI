import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMic;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onMic,
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
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Ask Lumoon...",
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
            ),
          ),

          IconButton(
            onPressed: onMic,
            icon: const Icon(
              Icons.mic,
              color: Colors.cyanAccent,
            ),
          ),

          IconButton(
            onPressed: onSend,
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
