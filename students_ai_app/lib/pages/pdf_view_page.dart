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
        Offset(0.4191, 0.6684),
        Offset(0.9132, 0.6684),
        Offset(0.9132, 0.7332),
        Offset(0.4191, 0.7332),
      ],
    ),
    Annotation(
      content: "Full",
      page: 1,
      coordinates: [
        Offset(0.0, 0.0),
        Offset(0.0, 1.0),
        Offset(1.0, 0.0),
        Offset(1.0, 1.0),
      ],
    ),
    // 필요 시 다른 Annotation 추가 가능
  ];

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

          return Stack(
            children: [
              PdfViewer.asset(
                '/pdfs/1.pdf',
                controller: _pdfController,
                params: PdfViewerParams(
                  scrollByMouseWheel: null,
                  scaleEnabled:false,
                  panEnabled:false,
                ),
              ),
              // Overlay 사각형 표시
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: AnnotationPainter(
                      annotations
                          .where((a) => a.page == _currentPage)
                          .toList(),
                      viewSize,
                    ),
                  ),
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

class AnnotationPainter extends CustomPainter {
  final List<Annotation> annotations;
  final Size canvasSize;

  AnnotationPainter(this.annotations, this.canvasSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (var annotation in annotations) {
      final xMin = annotation.coordinates.map((c) => c.dx).reduce((a, b) => a < b ? a : b);
      final yMin = annotation.coordinates.map((c) => c.dy).reduce((a, b) => a < b ? a : b);
      final xMax = annotation.coordinates.map((c) => c.dx).reduce((a, b) => a > b ? a : b);
      final yMax = annotation.coordinates.map((c) => c.dy).reduce((a, b) => a > b ? a : b);

      final rect = Rect.fromLTWH(
        xMin * canvasSize.width,
        yMin * canvasSize.height,
        (xMax - xMin) * canvasSize.width,
        (yMax - yMin) * canvasSize.height,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
