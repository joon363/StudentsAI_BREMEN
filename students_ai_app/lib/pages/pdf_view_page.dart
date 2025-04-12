import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  runApp(const MaterialApp(home: PdfAnnotationViewer()));
}

class PdfAnnotationViewer extends StatefulWidget {
  const PdfAnnotationViewer({Key? key}) : super(key: key);

  @override
  State<PdfAnnotationViewer> createState() => _PdfAnnotationViewerState();
}

class _PdfAnnotationViewerState extends State<PdfAnnotationViewer> {
  late PdfViewerController _pdfController;
  int _currentPage = 1;


  final List<Annotation> annotations = [
    Annotation(
      content: "Recommanded improvements",
      page: 1,
      coordinates: [
        Offset(0.07, 0.28),
        Offset(0.48, 0.28),
        Offset(0.3, 0.65),
        Offset(0.07, 0.65),
      ],
    ),
    Annotation(
      content: "Full",
      page: 2,
      coordinates: [
        Offset(0.0, 0.0),
        Offset(0.0, 1.0),
        Offset(1.0, 0.0),
        Offset(1.0, 1.0),
      ],
    ),
    // 필요 시 다른 Annotation 추가 가능
  ];


  List<BubbleInfo> _bubbles = [];

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _pdfController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    setState(() {
      _currentPage = _pdfController.pageNumber!;
    });
  }

  @override
  void dispose() {
    _pdfController.removeListener(_onPageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF with Annotations")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final Size viewSize = constraints.biggest;
          PdfDestCommand command = PdfDestCommand.unknown;

          return Stack(
            children: [
              PdfViewer.asset(
                '/pdfs/1.pdf',
                controller: _pdfController,
                params: PdfViewerParams(
                  panEnabled: false,
                  pageOverlaysBuilder: (context, pageRect, page) {
                    final pageNumber = page.pageNumber;
                    final pageAnnotations = annotations.where((a) => a.page == pageNumber);
                    final newBubbles = annotations.map((anno) {
                      final xValues = anno.coordinates.map((o) => o.dx).toList();
                      final yValues = anno.coordinates.map((o) => o.dy).toList();

                      final left = xValues.reduce((a, b) => a < b ? a : b) * pageRect.width;
                      final top = yValues.reduce((a, b) => a < b ? a : b) * pageRect.height;
                      final width = (xValues.reduce((a, b) => a > b ? a : b) - xValues.reduce((a, b) => a < b ? a : b)) * pageRect.width;
                      final height = (yValues.reduce((a, b) => a > b ? a : b) - yValues.reduce((a, b) => a < b ? a : b)) * pageRect.height;

                      final centerX = (left + width / 2);
                      final isLeftSide = centerX < pageRect.width / 2;

                      final Offset position = Offset(
                        pageRect.left + (isLeftSide ? left - 150 : left + width + 10),
                        pageRect.top + top,
                      );

                      return BubbleInfo(
                        //position: position,
                        content: anno.content,
                        page: anno.page,
                      );
                    }).toList();
                    _bubbles = newBubbles.map((b) => BubbleInfo(
                      //position: Offset(b.position.dx, b.position.dy),
                      content: b.content,
                      page: b.page,
                    )).toList();
                    return pageAnnotations.expand((anno) {
                      final xValues = anno.coordinates.map((o) => o.dx).toList();
                      final yValues = anno.coordinates.map((o) => o.dy).toList();

                      final left = xValues.reduce((a, b) => a < b ? a : b) * pageRect.width;
                      final top = yValues.reduce((a, b) => a < b ? a : b) * pageRect.height;
                      final width = (xValues.reduce((a, b) => a > b ? a : b) - xValues.reduce((a, b) => a < b ? a : b)) * pageRect.width;
                      final height = (yValues.reduce((a, b) => a > b ? a : b) - yValues.reduce((a, b) => a < b ? a : b)) * pageRect.height;

                      final centerX = (left + width / 2);
                      final isLeftSide = centerX < pageRect.width / 2;

                      final double bubbleWidth = 140;
                      final double bubbleHeight = 60;

                      return [
                        // Highlight box
                        Positioned(
                          left: left,
                          top: top,
                          width: width,
                          height: height,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.yellow.withOpacity(0.3),
                              border: Border.all(color: Colors.orange, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ];
                    }).toList();
                  },
                  viewerOverlayBuilder: (context, size, handleLinkTap) => [
                    Container(
                      alignment: Alignment.topRight,
                      margin: EdgeInsets.all(30),
                      child: Column(
                        spacing: 20,
                        children: _bubbles.map((bubble) {
                          return Material(
                            elevation: 0,
                            color: Colors.white, // 배경색은 Container에서 설정
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () {
                                _pdfController.goToPage(pageNumber:bubble.page); // 원하는 페이지로 이동
                              },
                              borderRadius: BorderRadius.circular(10), // 터치 영역도 둥글게
                              child: Container(
                                width: 300,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  //color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Page ${bubble.page.toString()}',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    Text(
                                      bubble.content,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          ;
                        }).toList(),
                      ),
                    )
                  ]
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class Annotation {
  final String content;
  final int page;
  final List<Offset> coordinates;

  Annotation({
    required this.content,
    required this.page,
    required this.coordinates,
  });
}

class BubbleInfo {
  //final Offset position;
  final String content;
  final int page;

  BubbleInfo({ required this.content, required this.page});
}
