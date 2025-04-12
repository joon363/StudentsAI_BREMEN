import 'package:flutter/material.dart';
import 'package:students_ai_app/themes.dart';
import 'package:students_ai_app/widgets/spinning_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;
  final String loadingMessage;
  final List<String> files;

  ChatMessage({
    required this.text,
    this.isUser = false,
    this.isLoading = false,
    this.loadingMessage = "",
    this.files = const[],
  });
}
class _ChatbotWidgetState extends State<ChatbotWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = []; // {'role': 'user' | 'bot', 'text': '...'}
  bool _isLoading = false;
  static const double chatHorPadding = 150.0;
  List<String> uploadedFiles = [];
  Map<String, dynamic>? extractionResult;
  Map<String, Uint8List?> uploadedPdfFiles = {};

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
          uploadedPdfFiles[file.name] = file.bytes;
          uploadedFiles.add(file.name);
        });
    }
  }
  void _sendMessage() async {
    final userText = _controller.text.trim();
    final copiedFiles = uploadedFiles.map((file) => file).toList();
    if (userText.isEmpty) return;

    setState(() {
        _messages.add(ChatMessage(text: userText, isUser: true, files: copiedFiles));
        _messages.add(ChatMessage(text: '...', isLoading: true, loadingMessage: "Searching for reference papers..."));
        _controller.clear();
        uploadedFiles.clear();
        _isLoading = true;
      }
    );

    // 더미 응답 시뮬레이션
    final result = await fetchRecommendedPapers(userText);

    setState(() {
        _messages.removeWhere((m) => m.isLoading); // 로딩 메시지 제거
        _messages.add(ChatMessage(
            text: 'We selected ${result.length} Papers to compare with.',
            files: result)
        );
      }
    );
    await Future.delayed(Duration(seconds: 2));

    setState(() {
        _messages.add(ChatMessage(text: '...', isLoading: true, loadingMessage: "Parsing Uploaded paper..."));
        _controller.clear();
        uploadedFiles.clear();
        _isLoading = true;
      }
    );

    // 더미 응답 시뮬레이션
    final result2 = await executeInformationExtraction(copiedFiles[0]);

    setState(() {
        _messages.removeWhere((m) => m.isLoading); // 로딩 메시지 제거
        _messages.add(ChatMessage(
            text: 'Extracted Information from Documents.')
        );
      }
    );
  }

  Future<List<String>> fetchRecommendedPapers(String prompt) async {
    final url = Uri.parse('http://localhost:5000/recommend');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        final List<dynamic> fileNames = responseJson['files'];
        return fileNames.cast<String>();
      } else {
        print("에러 발생: ${response.statusCode} ${response.body}");
        return [];
      }
    } catch (e) {
      print('요청 중 오류 발생: $e');
      return [];
    }
  }

  Future<void> executeInformationExtraction(String originalFilename) async {
    try {
      final pdfBytes = uploadedPdfFiles[originalFilename];
      if (pdfBytes == null) {
        throw Exception("PDF 파일을 찾을 수 없습니다");
      }

      final schema = {
        "name": "academic_paper_analysis_schema",
        "schema": {
          "type": "object",
          "properties": {
            "subsections": {
              "type": "array",
              "items": {"type": "string"},
              "description":
              "Main sentences from each section, providing specific details rather than summaries, and also check if all components of the paper have been covered"
            },
            "figures": {
              "type": "array",
              "items": {"type": "string"},
              "description":
              "The descriptions of the figures included in the paper"
            },
            "equations": {
              "type": "array",
              "items": {"type": "string"},
              "description":
              "The descriptions of the equations included in the paper"
            },
            "methods": {
              "type": "array",
              "items": {"type": "string"},
              "description":
              "The newly proposed methods or techniques in the paper"
            },
            "metrics": {
              "type": "array",
              "items": {"type": "string"},
              "description":
              "The comparison schemes and evaluation metrics used in the paper"
            },
            "words": {
              "type": "array",
              "items": {"type": "string"},
              "description": "The non-academic expressions found in the paper"
            }
          },
          "required": [
            "subsections",
            "figures",
            "equations",
            "methods",
            "metrics",
            "words"
          ]
        }
      };

      final uri = Uri.parse("http://localhost:5000/universal-extraction");
      var request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          pdfBytes,
          filename: originalFilename,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      request.fields['schema'] = json.encode(schema);

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      //print("서버 응답: $responseBody"); // 디버깅용 로그

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);
        print("서버 응답: $jsonResponse"); // 디버깅용 로그

        if (jsonResponse['result'] != null &&
          jsonResponse['result']['result']['choices'] != null &&
          jsonResponse['result']['result']['choices'].isNotEmpty) {
          var contentStr =
            jsonResponse['result']['result']['choices'][0]['message']['content'];
          var content = json.decode(contentStr);

          setState(() {
              extractionResult = content;
            });
          print("✅ Universal Extraction 성공");
        } else {
          print(jsonResponse['result']['result']['choices']);
          throw Exception("잘못된 응답 형식");
        }
      } else {
        print("❌ Universal Extraction 오류: $responseBody");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("처리 중 오류가 발생했습니다")),
        );
      }
    } catch (e) {
      print("❌ 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류가 발생했습니다: $e")),
      );
    }
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
          child: Row(
            spacing: 10,
            children: [
              SpinningImage(
                imagePath: 'assets/icons/loading.png',
              ),
              Text(
                message.loadingMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: textGrayColor
                ),
              )
            ],
          )
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
                width: 800,
                height: isUser ? 80 : 300,
                child: ListView.builder(
                  scrollDirection: isUser ? Axis.horizontal : Axis.vertical,
                  reverse: isUser,
                  itemCount: message.files.length,
                  itemBuilder: (context, index) {
                    final item = message.files[index];
                    return Container(
                      //width: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      margin: const EdgeInsets.only(left: 15, bottom: 15),
                      alignment: isUser ? Alignment.center : Alignment.centerLeft,
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
                        item ?? "이름 없음"),
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
                        width: 800,
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
                                  Text(item ?? "이름 없음"),
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
