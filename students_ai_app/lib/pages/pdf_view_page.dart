import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:students_ai_app/themes.dart';
import 'dart:convert';
import 'dart:io';


class PdfAnnotationViewer extends StatefulWidget
{
  final Map<String, dynamic> finalResult;
  const PdfAnnotationViewer({super.key, required this.finalResult});

  @override
  State<PdfAnnotationViewer> createState() => _PdfAnnotationViewerState();
}

class _PdfAnnotationViewerState extends State<PdfAnnotationViewer>
{
  late PdfViewerController _pdfController;
  List<Annotation>? annotations;

  Future<List<Annotation>> loadAnnotations() async {
    final anno = <Annotation>[];
    widget.finalResult?.forEach((content, data) {
      anno.add(Annotation.fromJson(content, data));
    });
    anno.sort((a, b) => a.page.compareTo(b.page));
    return anno;
  }

  List<BubbleInfo> _bubbles = [];

  @override
  void initState() 
  {
    super.initState();
    _pdfController = PdfViewerController();
    loadAnnotations().then((loadedAnnotations) {
      setState(() {
        annotations = loadedAnnotations;
      });
    });
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text("PDF with Annotations")
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              PdfViewer.asset(
                '/pdf/sample.pdf', // TODO: Replace with selected pdf file.
                controller: _pdfController,
                params: PdfViewerParams(
                  panEnabled: false,
                  pageOverlaysBuilder: (context, pageRect, page) {
                    final pageNumber = page.pageNumber;
                    final pageAnnotations = annotations!.where((a) => a.page == pageNumber);
                    _bubbles = annotations!.map((anno) {
                        return BubbleInfo(
                          content: anno.content,
                          page: anno.page,
                        );
                      }).toList();

                    return pageAnnotations.expand((anno) {
                        final xValues = anno.coordinates.map((o) => o.dx).toList();
                        final yValues = anno.coordinates.map((o) => o.dy).toList();

                        final left = xValues.reduce((a, b) => a < b ? a : b) * pageRect.width;
                        final top = yValues.reduce((a, b) => a < b ? a : b) * pageRect.height;
                        final width = (xValues.reduce((a, b) => a > b ? a : b) -
                          xValues.reduce((a, b) => a < b ? a : b)) * pageRect.width;
                        final height =
                          (yValues.reduce((a, b) => a > b ? a : b) -
                            yValues.reduce((a, b) => a < b ? a : b)) * pageRect.height;

                        return [
                          // Highlight box
                          Positioned(
                            left: left,
                            top: top,
                            width: width,
                            height: height,
                            child: Container(
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.07),
                                border:
                                Border.all(color: primaryColor, width: 2),
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
                      child: SingleChildScrollView(
                        child: Column(
                          spacing: 20,
                          children: _bubbles.map((bubble) {
                            return Material(
                              elevation: 0,
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: () {
                                  _pdfController.goToPage(
                                    pageNumber:
                                    bubble.page
                                  ); 
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 300,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Page ${bubble.page.toString()}',
                                        style:
                                        const TextStyle(fontSize: 20),
                                      ),
                                      Text(
                                        bubble.content,
                                        style:
                                        const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
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

class Annotation
{
  final String content;
  final int page;
  final List<Offset> coordinates;

  Annotation({
    required this.content,
    required this.page,
    required this.coordinates,
  });
  factory Annotation.fromJson(String content, Map<String, dynamic> json) {
    return Annotation(
      content: content,
      page: json['page'],
      coordinates: (json['coordinates'] as List)
          .map((coord) => Offset(
        (coord['x'] as num).toDouble(),
        (coord['y'] as num).toDouble(),
      )).toList(),
    );
  }
}

class BubbleInfo
{
  final String content;
  final int page;

  BubbleInfo({required this.content, required this.page});
}
