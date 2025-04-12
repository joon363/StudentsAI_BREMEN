import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'dart:html' as html; // HTML 웹 브라우저 열기용 (웹 전용)

void main() {
  runApp(MaterialApp(home: PdfUploader()));
}

class PdfUploader extends StatefulWidget {
  @override
  _PdfUploaderState createState() => _PdfUploaderState();
}

class _PdfUploaderState extends State<PdfUploader> {
  List<Map<String, String>> uploadedHtmlFiles = [];

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

      var uri = Uri.parse("http://10.10.5.171:8000/upload-pdf"); // 서버 주소!
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

        print("✅ HTML 변환 성공: $filename");
      } else {
        print("❌ 오류 발생: $responseBody");
      }
    }
  }

  void openHtmlInNewTab(String htmlFilename) {
    final basename = htmlFilename.replaceAll('.html', '');
    final url = "http://10.10.5.171:8000/view-html/$basename";
    html.window.open(url, '_blank');
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
                      trailing: ElevatedButton(
                        onPressed: () => openHtmlInNewTab(item["html"]!),
                        child: Text("HTML 보기"),
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
