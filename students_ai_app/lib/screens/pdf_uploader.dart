import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'dart:html' as html;

class PdfUploader extends StatefulWidget {
  const PdfUploader({super.key});

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

          //Perplexity 후처리 API 호출
          final perplexityUri =
          Uri.parse("http://10.10.5.171:8000/run-perplexity/$filenameWithoutExt");
          final perplexityRes = await http.get(perplexityUri);

          if (perplexityRes.statusCode == 200) {
            print("✅ Perplexity 실행 성공");
          } else {
            print("❌ Perplexity 실행 실패: ${perplexityRes.body}");
          }

          setState(() {
            uploadedHtmlFiles.add({
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

  void openHtmlInNewTab(String htmlFilename) {
    final basename = htmlFilename.replaceAll('.html', '');
    final url = "http://10.10.5.171:8000/view-html/$basename";
    html.window.open(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📤 PDF 업로드 및 보기")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickAndUploadFiles,
              child: const Text("PDF 업로드"),
            ),
            const SizedBox(height: 20),
            if (uploadedHtmlFiles.isEmpty)
              const Text("업로드된 파일이 없습니다.")
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
                        child: const Text("HTML 보기"),
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
