import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'dart:html' as html;

void main() {
  runApp(MaterialApp(home: PdfUploader()));
}

class PdfUploader extends StatefulWidget {
  @override
  _PdfUploaderState createState() => _PdfUploaderState();
}

class _PdfUploaderState extends State<PdfUploader> {
  List<Map<String, String>> uploadedHtmlFiles = [];
  Map<String, dynamic>? extractionResult;
  Map<String, Uint8List?> pdfFiles = {};

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
      if (file.bytes == null) continue;

      var uri = Uri.parse("http://10.10.5.207:8000/upload-pdf");
      var request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonRes = json.decode(responseBody);
        var filename = jsonRes["html_file"];

        setState(() {
          uploadedHtmlFiles.add({
            "original": file.name,
            "html": filename,
          });
        });

        pdfFiles[file.name] = file.bytes;

        print("✅ HTML 변환 성공: $filename");
      } else {
        print("❌ 오류 발생: $responseBody");
      }
    }
  }

  void openHtmlInNewTab(String htmlFilename) {
    final basename = htmlFilename.replaceAll('.html', '');
    final url = "http://10.10.5.207:8000/view-html/$basename";
    html.window.open(url, '_blank');
  }

  Future<void> sendToUniversalExtraction(String originalFilename) async {
    try {
      final pdfBytes = pdfFiles[originalFilename];
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

      final uri = Uri.parse("http://10.10.5.207:8000/universal-extraction");
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
      print("서버 응답: $responseBody"); // 디버깅용 로그

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);
        print("서버 응답: $jsonResponse"); // 디버깅용 로그

        if (jsonResponse['result'] != null &&
            jsonResponse['result']['choices'] != null &&
            jsonResponse['result']['choices'].isNotEmpty) {
          var contentStr =
              jsonResponse['result']['choices'][0]['message']['content'];
          var content = json.decode(contentStr);

          setState(() {
            extractionResult = content;
          });

          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("분석 결과"),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("섹션 요약:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...content['subsections']
                          .map((s) => Text("• $s"))
                          .toList(),
                      SizedBox(height: 10),
                      Text("그림:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...content['figures'].map((f) => Text("• $f")).toList(),
                      SizedBox(height: 10),
                      Text("수식:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...content['equations'].map((e) => Text("• $e")).toList(),
                      SizedBox(height: 10),
                      Text("방법론:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...content['methods'].map((m) => Text("• $m")).toList(),
                      SizedBox(height: 10),
                      Text("평가 지표:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...content['metrics'].map((m) => Text("• $m")).toList(),
                      SizedBox(height: 10),
                      Text("비학술적 표현:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...content['words'].map((w) => Text("• $w")).toList(),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("닫기"),
                  ),
                ],
              ),
            );
          }

          print("✅ Universal Extraction 성공");
        } else {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📤 PDF 업로드 및 보기")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickAndUploadFiles,
              child: Text("PDF 업로드"),
            ),
            SizedBox(height: 20),
            if (uploadedHtmlFiles.isEmpty)
              Text("업로드된 파일이 없습니다.")
            else
              Expanded(
                child: ListView.builder(
                  itemCount: uploadedHtmlFiles.length,
                  itemBuilder: (context, index) {
                    final item = uploadedHtmlFiles[index];
                    return ListTile(
                      title: Text(item["original"] ?? "이름 없음"),
                      subtitle: Text(item["html"] ?? ""),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () => openHtmlInNewTab(item["html"]!),
                            child: Text("HTML 보기"),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () =>
                                sendToUniversalExtraction(item["original"]!),
                            child: Text("내용 분석"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
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
