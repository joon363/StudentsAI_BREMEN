import 'package:flutter/material.dart';
import 'package:students_ai_app/widgets/prompt_help.dart';
import 'package:students_ai_app/widgets/spinning_indicator.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;

  ChatMessage({required this.text, this.isUser = false, this.isLoading = false});
}
class _ChatbotWidgetState extends State<ChatbotWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = []; // {'role': 'user' | 'bot', 'text': '...'}
  bool _isLoading = false;

  void _sendMessage() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true));
      _messages.add(ChatMessage(text: '...', isLoading: true));
      _controller.clear();
      _isLoading = true;
    });

    // 더미 응답 시뮬레이션
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _messages.removeWhere((m) => m.isLoading); // 로딩 메시지 제거
      _messages.add(ChatMessage(text: 'This is a dummy response for: "$userText"'));
    });
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? Colors.blueAccent : Colors.grey.shade300;
    final textColor = isUser ? Colors.black : Colors.black87;

    return Align(
      alignment: alignment,
      child: message.isLoading?
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        child: SpinningImage(
          imagePath: 'assets/icons/loading.png',
        ),
      ):
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message.text ?? '',
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/icons/upstage-text-light.png',
              height: 40,
              fit: BoxFit.cover,
            ),
            Image.asset(
              'assets/icons/upstage-logo-color.png',
              height: 40,
              fit: BoxFit.cover,
            ),
          ],
        ),
        _messages.isEmpty? HelpPrompt():
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return _buildMessage(_messages[index]);
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left:130, right:130, bottom:80, top:10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 130,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: '"What areas should I strengthen or expand in my paper?"',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,         // 밑줄 제거!
                      focusedBorder: InputBorder.none,  // 포커스됐을 때도 밑줄 제거
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                color: Colors.blue,
                onPressed: _sendMessage,
              )
            ],
          ),
        )
      ],
    );
  }
}
