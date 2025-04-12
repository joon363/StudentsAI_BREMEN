import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart'; // 웹용 contentType

void main() {
  runApp(MaterialApp(home: PdfUploader()));
}

class PdfUploader extends StatefulWidget {
  @override
  _PdfUploaderState createState() => _PdfUploaderState();
}

class _PdfUploaderState extends State<PdfUploader> {
  String result = "";

  Future<void> pickAndUploadFiles() async {
    print("파일 선택 시도 중...");
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // 중요: Web에서 bytes로 받기
    );

    if (picked == null) {
      print("파일 선택 안됨");
      return;
    }

    var uri = Uri.parse("http://10.10.5.171:8000/upload-pdf"); // 서버 주소 확인!
    var request = http.MultipartRequest('POST', uri);

    for (var file in picked.files) {
      if (file.bytes != null) {
        print("업로드 중: ${file.name}, ${file.bytes!.length} bytes");
        request.files.add(
          http.MultipartFile.fromBytes(
            'file', // <- Flask에서 'file'로 받음
            file.bytes!,
            filename: file.name,
            contentType: MediaType('application', 'pdf'),
          ),
        );
      } else {
        print("file.bytes == null");
      }
    }

    print("요청 전송 중...");
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    setState(() {
      if (response.statusCode == 200) {
        result = const JsonEncoder.withIndent('  ').convert(json.decode(responseBody));
        print("성공! $result");
      } else {
        result = "오류 발생: $responseBody";
        print("오류: $responseBody");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📤 PDF 업로드")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickAndUploadFiles,
              child: Text("PDF 업로드"),
            ),
            SizedBox(height: 20),
            Expanded(child: SingleChildScrollView(child: Text(result))),
          ],
        ),
      ),
    );
  }
}
