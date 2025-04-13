import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'dart:html' as html; // 웹 브라우저에서 새 탭 열기용

class PdfUploader extends StatefulWidget {
  const PdfUploader({super.key});

  @override
  _PdfUploaderState createState() => _PdfUploaderState();
}

class _PdfUploaderState extends State<PdfUploader> {
  // 업로드된 파일 목록 저장 (원본 이름과 서버 저장 파일명)
  List<Map<String, String>> uploadedHtmlFiles = [];

  // PDF 파일을 선택하고 서버로 업로드하는 함수
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

          // ✅ 업로드 성공 후 perplexity 후처리 API 호출
          final perplexityUri = Uri.parse("http://10.10.5.171:8000/run-perplexity/$filenameWithoutExt");
          final perplexityRes = await http.get(perplexityUri);

          if (perplexityRes.statusCode == 200) {
            print("✅ Perplexity 실행 성공");
          } else {
            throw Exception ("❌ Perplexity 실행 실패: ${perplexityRes.body}");
          }

          // 목록에 추가
          setState(() {
            uploadedHtmlFiles.add({
              "original": file.name,
              "html": filename,
            });
          });

          print("✅ HTML 변환 성공: $filename");
        } else {
          throw Exception ("❌ 업로드 실패: $responseBody");
        }
      } catch (e) {
        throw Exception ("❌ 예외 발생: $e");
      }
    }
  }

  // HTML 보기 버튼 클릭 시 새 탭에서 뷰어 열기
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
            // 파일 업로드 버튼
            ElevatedButton(
              onPressed: pickAndUploadFiles,
              child: const Text("PDF 업로드"),
            ),
            const SizedBox(height: 20),

            // 업로드된 파일 리스트 표시
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
