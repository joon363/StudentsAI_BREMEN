import 'package:flutter/material.dart';
import 'package:students_ai_app/themes.dart';
import 'package:students_ai_app/widgets/spinning_indicator.dart';
import 'package:students_ai_app/pages/pdf_view_page.dart';
import 'package:students_ai_app/models/messages.dart';
import 'package:students_ai_app/connections/config.dart';
import 'package:students_ai_app/connections/api_calls.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:typed_data';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  List<PaperInfo> uploadedFiles = [];
  Map<String, Uint8List?> uploadedPdfFiles = {};
  List<Map<String, String>> uploadedHtmlFiles = [];

  Map<String, dynamic>? extractionResult;
  Map<String, dynamic>? finalResult;

  static const double chatHorPadding = 150.0;

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
          uploadedFiles.add(PaperInfo(title: file.name));
        });
    }
  }

  Future<void> _selectFile() async{
    final userText = _controller.text.trim();
    final copiedFiles = uploadedFiles.map((file) => file).toList();
    if (userText.isEmpty) return;

    setState(() {
        _messages.add(ChatMessage(text: userText, isUser: true, files: copiedFiles));
        _messages.add(ChatMessage(text: '...', isLoading: true, loadingMessage: "Searching for reference papers..."));
        _controller.clear();
        uploadedFiles.clear();
      }
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 50), () {
        _scrollToBottom();
      });
    });

    // 더미 응답 시뮬레이션
    final result = await APIManager.fetchRecommendedPapers(userText);
    setState(() {
        _messages.removeWhere((m) => m.isLoading); // 로딩 메시지 제거
        _messages.add(ChatMessage(
            text: '☑️  Selected ${result.length} Papers to compare with.',
            files: result)
        );
      }
      );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 50), () {
        _scrollToBottom();
      });
    });
  } 

  Future<void> _ieSelectedFile() async{
    setState(() {
        _messages.add(ChatMessage(text: '...', isLoading: true, loadingMessage: "Analyzing Selected papers..."));
        _controller.clear();
        uploadedFiles.clear();
      }
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 50), () {
        _scrollToBottom();
      });
    });
    
    final result2 = await APIManager.executeInformationExtraction(copiedFiles[0].title);

    setState(() {
        _messages.removeWhere((m) => m.isLoading);
        _messages.add(ChatMessage(
            text: '☑️  Extracted Information from Documents.')
        );
      }
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 50), () {
        _scrollToBottom();
      });
    });
  }

  Future<void> _parseUploadedFile() async{
    setState(() {
        _messages.add(ChatMessage(text: '...', isLoading: true, loadingMessage: "Analyzing Uploaded paper..."));
      }
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 50), () {
        _scrollToBottom();
      });
    });

    final result3 = await APIManager.parseUploadedPaper(copiedFiles[0].title);

    setState(() {
        _messages.removeWhere((m) => m.isLoading);
        _messages.add(ChatMessage(text: '☑️  Analyzed Uploaded Paper.'));
        _messages.add(ChatMessage(text: 'Show\nResult', isEnding: true));
      }
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 50), () {
        _scrollToBottom();
      });
    });
    
  }
  
  void _sendMessage() async {
    try{
      await _selectFile();
      await Future.delayed(Duration(seconds: 2));
      await _ieSelectedFile();
      await Future.delayed(Duration(seconds: 2));
      await _parseUploadedFile();
    }
    catch (e){
      setState(() {
          _messages.removeWhere((m) => m.isLoading); // 로딩 메시지 제거
          _messages.add(ChatMessage(
              text: 'Failed. Try again later')
          );
          _scrollToBottom();
        }
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return buildMessage(_messages[index]);
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
                                  Text(item.title ?? "이름 없음"),
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

Widget buildMessage(ChatMessage message) {
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final crossAlignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textColor = isUser ? Colors.black : Colors.black87;

    return Align(
      alignment: alignment,
      child: message.isEnding ?
        Container(
          margin: EdgeInsets.symmetric(vertical:10, horizontal: chatHorPadding),
            child: Material(
              elevation: 0,
              color: Colors.transparent, // 배경색은 Container에서 설정
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfAnnotationViewer(finalResult: finalResult!),
                    ),
                  ); // 원하는 페이지로 이동
                },
                borderRadius:
                BorderRadius.circular(30), // 터치 영역도 둥글게
                child: Container(
                    width:100,
                    height:100,
                    decoration: BoxDecoration(
                      color: primaryColorDark,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white
                          ),
                        )
                      ],
                    )
                ),
              ),
            )
        )
        : message.isLoading ?
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: chatHorPadding),
            child: Row(
              spacing: 10,
              children: [
                SizedBox(width: 10,),
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
                  height: isUser ? 80 : 250,
                  child: ListView.builder(
                    scrollDirection: isUser ? Axis.horizontal : Axis.vertical,
                    reverse: isUser,
                    shrinkWrap: !isUser,
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
                          item.year==0?'${item.title}': '[${item.pub}, ${item.year}] ${item.title}'
                        ),
                      );
                    },
                  ),
                ) : Container()
            ],
          )
    );
  }