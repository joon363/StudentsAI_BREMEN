import 'package:flutter/material.dart';
import 'package:students_ai_app/themes.dart';
import 'package:students_ai_app/widgets/spinning_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;
  final List<Map<String, String>> files;

  ChatMessage({
    required this.text,
    this.isUser = false,
    this.isLoading = false,
    this.files = const[],
  });
}
class _ChatbotWidgetState extends State<ChatbotWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = []; // {'role': 'user' | 'bot', 'text': '...'}
  bool _isLoading = false;
  static const double chatHorPadding = 150.0;
  List<Map<String, String>> uploadedFiles = [];

  Future<void> pickAndUploadFiles() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (picked == null) {
      print("파일 선택 안됨");
      return;
    }

    for (var file in picked.files) {
      setState(() {
          uploadedFiles.add({
            "original": file.name,
          });
        });
      //if (file.bytes == null) continue;
      if (true) continue;

      final uri = Uri.parse("http://10.10.5.171:8000/upload-pdf");
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      try {
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final jsonRes = json.decode(responseBody);
          final filename = jsonRes["html_file"] ?? "";
          final filenameWithoutExt = filename.replaceAll('.html', '');

          // ✅ 업로드 성공 후 perplexity 후처리 API 호출
          final perplexityUri = Uri.parse("http://10.10.5.171:8000/run-perplexity/$filenameWithoutExt");
          final perplexityRes = await http.get(perplexityUri);

          if (perplexityRes.statusCode == 200) {
            print("✅ Perplexity 실행 성공");
          } else {
            print("❌ Perplexity 실행 실패: ${perplexityRes.body}");
          }

          // 목록에 추가
          setState(() {
              uploadedFiles.add({
                "original": file.name,
                "html": filename,
              });
            });

          print("✅ HTML 변환 성공: $filename");
        } else {
          print("❌ 업로드 실패: $responseBody");
        }
      } catch (e) {
        print("❌ 예외 발생: $e");
      }
    }
  }
  void _sendMessage() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;

    setState(() {
        final copiedFiles = uploadedFiles.map((file) => Map<String, String>.from(file)).toList();
        _messages.add(ChatMessage(text: userText, isUser: true, files: copiedFiles));
        _messages.add(ChatMessage(text: '...', isLoading: true));
        _controller.clear();
        uploadedFiles.clear();
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
    final crossAlignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textColor = isUser ? Colors.black : Colors.black87;

    return Align(
      alignment: alignment,
      child: message.isLoading ?
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: chatHorPadding),
          child: SpinningImage(
            imagePath: 'assets/icons/loading.png',
          ),
        ) :
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: crossAlignment,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: chatHorPadding),
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
                style: TextStyle(
                  fontSize: 16,
                  color: textColor
                ),
              ),
            ),
            message.files.isNotEmpty ?
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: chatHorPadding),
                width: 500,
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  itemCount: message.files.length,
                  itemBuilder: (context, index) {
                    final item = message.files[index];
                    return Container(
                      //width: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      margin: const EdgeInsets.only(left: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: primaryColor,
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
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        item["original"] ?? "이름 없음"),
                    );
                  },
                ),
              ) : Container()
          ],
        )
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
        _messages.isEmpty ? HelpPrompt() :
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),

        Padding(
          padding: const EdgeInsets.only(left: chatHorPadding, right: chatHorPadding, bottom: 80, top: 10),
          child: Container(
            height: 180,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  //width: 500,
                  child: Row(
                    children: [
                      // 파일 업로드 버튼
                      Container(
                        //width: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                          onPressed: pickAndUploadFiles,
                          child: Container(
                            height: 50,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            child: Image.asset(
                              'assets/icons/plus icon.png',
                              fit: BoxFit.cover,
                            ),
                          )
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 300,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: uploadedFiles.length,
                          itemBuilder: (context, index) {
                            final item = uploadedFiles[index];
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: primaryColor, width: 2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              //width: 100,
                              child: Row(
                                children: [
                                  Text(item["original"] ?? "이름 없음"),
                                ],
                              )
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ],
            )
          )
        )
      ],
    );
  }
}
class HelpPrompt extends StatelessWidget {
  const HelpPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      child: Column(
        children: [
          Text(
            'How can I help you?',
            style: TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.w500,
              color: primaryColorDark,
            ),
          ),
          Text(
            'Upload your PDF (or other format)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: primaryColorDark,
            ),
          ),
        ],
      )
    );
  }
}
