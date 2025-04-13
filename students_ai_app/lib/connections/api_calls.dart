

class APIManager extends StatefulWidget {
  const APIManager({super.key});

  @override
  State<APIManager> createState() => _APIManagerState();
}

class _APIManagerState extends State<APIManager> {
Future<List<PaperInfo>> fetchRecommendedPapers(String prompt) async {
    final url = Uri.parse('http://${SERVER_ADDR}/recommend');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        final List<dynamic> fileNames = responseJson['files'];
        final List<PaperInfo> papers = fileNames.map((file) {
          final Map<String, dynamic> f = file as Map<String, dynamic>;  // 명시적 캐스팅
          return PaperInfo(
            title: f['title'] as String,
            year: double.parse(f['year'].toString()).toInt(),
            pub: f['pub'] as String,
          );
        }).toList();
        return papers;
      } else {
        throw Exception ("에러 발생: ${response.statusCode} ${response.body}");
        return [];
      }
    } catch (e) {
      throw Exception ('요청 중 오류 발생: $e');
      return [];
    }
    return [];
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

      final uri = Uri.parse("http://${SERVER_ADDR}/universal-extraction");
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

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);
        print("✅ Universal Extraction 성공");
      } else {
        throw Exception ("❌ Universal Extraction 오류: $responseBody");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("처리 중 오류가 발생했습니다")),
        );
      }
    } catch (e) {
      throw Exception ("❌ 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류가 발생했습니다: $e")),
      );
    }
  }

  Future<void> parseUploadedPaper(String originalFilename) async {
    final uri = Uri.parse("http://${SERVER_ADDR}/upload-pdf");
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        uploadedPdfFiles[originalFilename]!,
        filename: originalFilename,
        contentType: MediaType('application', 'pdf'),
      ),
    );

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonRes = json.decode(responseBody);
        final filename = jsonRes["html_file"] ?? "";

        // ✅ 업로드 성공 후 perplexity 후처리 API 호출
        final perplexityUri = Uri.parse("http://${SERVER_ADDR}/run-perplexity");//$filenameWithoutExt");
        final perplexityRes = await http.get(perplexityUri);

        if (perplexityRes.statusCode == 200) {
          print("✅ Perplexity 실행 성공");
        } else {
          throw Exception("❌ Perplexity 실행 실패: ${perplexityRes.body}");
        }

        // 목록에 추가
        setState(() {
            uploadedHtmlFiles.add({
              "original": originalFilename,
              "html": filename,
            });
            finalResult = jsonDecode(perplexityRes.body);
          });

        print("✅ HTML 변환 성공: $filename");
      } else {
        throw Exception("❌ 업로드 실패: $responseBody");
      }
    } catch (e) {
      throw Exception("❌ 예외 발생: $e");
    }
  }
}