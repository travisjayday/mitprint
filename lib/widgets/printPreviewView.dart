import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:mit_print/screens/mainScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io' as Io;
import 'dart:convert';
import 'package:pdf_render/pdf_render.dart';
import 'dart:math';

class PrintPreviewView extends StatefulWidget {
  Function(String) callback;
  final _PrintPreviewViewState state = _PrintPreviewViewState();
  bool grayscale = true;
  MainScreen mainScreen;
  PrintPreviewView({this.mainScreen, this.callback, this.grayscale});

  void pickFile() async {
    state._pickFile();
  }

  void setGrayscale(gray) {
    grayscale = gray;
    state.setState(() {});
  }

  @override
  _PrintPreviewViewState createState() => state;
}

class CardTransform {
  Offset translate;
  double elevation;
  double scale;
  AnimationController animScale;
  CardTransform({this.animScale, this.translate, this.elevation, this.scale});
}

class _PrintPreviewViewState extends State<PrintPreviewView>
    with TickerProviderStateMixin {
  String filePath;
  List<Widget> printPreviewImgs = null;
  List<PdfPageImage> previewImgs = null;
  // scale, translate x, translate y
  List<CardTransform> printPreviewImgsTransform;

  Widget printPreviewIcon = Icon(Icons.add, color: Colors.grey[400], size: 100);
  int pageCount = 0;
  int currentPage = 0;
  PdfDocument pdfPreviewDoc;
  double translate = 0.0;
  int topPage = 0;

  _renderPdfPreview(int pageNum) async {
    final PdfDocument doc = await PdfDocument.openFile(filePath);
    pageCount = doc.pageCount;

    if (printPreviewImgs == null)
      printPreviewImgs = new List<Widget>();
    else
      printPreviewImgs.clear();

    if (previewImgs == null)
      previewImgs = new List<PdfPageImage>();
    else
      previewImgs.clear();
    if (printPreviewImgsTransform != null) printPreviewImgsTransform.clear();
    // there are 5 pages in the real pdf. index 0 - 4
    for (var i = 0; i < doc.pageCount; i++) {
      PdfPage page = await doc.getPage(i + 1);
      PdfPageImage pageImage = await page.render();
      previewImgs.add(pageImage);
      double scale = 1 - i / 20.0;
      printPreviewImgsTransform.add(
        CardTransform(
            scale: 1,
            translate: Offset(0.0, 0.05 - 0.05 / (pow(1.5, i))),
            elevation: 2 * (pageCount - i) / pageCount + 1,
            animScale: AnimationController(
                duration: const Duration(milliseconds: 500), vsync: this)),
      );
    }
    print("paagaeCOUNT: " +
        pageCount.toString() +
        " count: " +
        printPreviewImgsTransform.length.toString());

    setState(() {
      pageCount = doc.pageCount;
      currentPage = pageNum;
    });

    pdfPreviewDoc = doc;
  }

  _buildPreviewImgs() {
    print("PREVIEW  BUILT");
    if (previewImgs == null) return [Container()];
    if (printPreviewImgs != null) printPreviewImgs.clear();
    for (int i = 0; i < pageCount; i++) {
      printPreviewImgs.add(_createCard(
          RawImage(
            image: previewImgs[i].image,
            colorBlendMode: widget.grayscale ? BlendMode.saturation : null,
            color: widget.grayscale ? Colors.grey : null,
          ),
          i));
    }
    return printPreviewImgs;
  }

  void _pickFile() async {
    setState(() {
      printPreviewIcon = SpinKitRing(color: Colors.grey[300], size: 110);
    });
    var path = await FilePicker.getFilePath(type: FileType.ANY);
    print("Selected file: " + path.toString());
    if (path != null) {
      widget.callback(path);
      if (printPreviewImgs == null) {
        printPreviewImgs = List<Widget>();
        printPreviewImgs.add(Container());
      } else
        printPreviewImgs?.clear();
      topPage = 0;
      filePath = path;
      if (path.endsWith(".pdf")) {
        await _renderPdfPreview(0);
      } else if (path.endsWith(".jpg") ||
          path.endsWith(".png") ||
          path.endsWith(".bmp") ||
          path.endsWith(".jpeg")) {
        setState(() {
          printPreviewImgs[0] = _createCard(
              Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Image.file(new Io.File(path))),
              0);
        });
      } else {
        // TODO: Better user feedback
        print("Unsupported FileType!!!");
      }
    } else
      path = "";
    setState(() {
      printPreviewIcon = Icon(Icons.add, color: Colors.grey[400], size: 100);
    });
  }

  /*static Widget
}*/

  // page on top has zero offset
  Widget _createCard(Widget content, int pageNum) {
    return ScaleTransition(
        scale: Tween(begin: printPreviewImgsTransform[pageNum].scale, end: 1.3)
            .animate(printPreviewImgsTransform[pageNum]?.animScale),
        child: SlideTransition(
            position: Tween<Offset>(
                    begin: printPreviewImgsTransform[pageNum].translate,
                    end: Offset(0.9, 0))
                .animate(CurvedAnimation(
                    parent: printPreviewImgsTransform[pageNum]?.animScale,
                    curve: Curves.easeOutCirc,
                    reverseCurve: Curves.easeInCirc)),
            child: FadeTransition(
              opacity: Tween(begin: 1.0, end: 1.0).animate(CurvedAnimation(
                  parent: printPreviewImgsTransform[pageNum]?.animScale,
                  curve: Curves.easeOutCirc,
                  reverseCurve: Curves.linear)),
              child: GestureDetector(
                      onPanUpdate: (details) {
                        if (details.delta.dx > 0) {
                          // swiping in right direction
                          setState(() {
                            print("setting offset for: " + pageNum.toString());
                            if (pageNum == topPage && topPage < pageCount - 1) {
                              printPreviewImgsTransform[topPage]
                                  ?.animScale
                                  ?.forward();
                              topPage++;
                            }
                          });
                          print("swipe right");
                        } else if (details.delta.dx < 0) {
                          setState(() {
                            print("setting offset for: " + pageNum.toString());
                            if (pageNum == topPage && topPage > 0) topPage--;
                            printPreviewImgsTransform[topPage]
                                ?.animScale
                                ?.reverse();
                          });
                        }
                      },
                      child: Container(
                          color: Colors.transparent,
                          width: 450,
                          height: 450,
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(10),
                          child: Material(
                              color: Colors.white,
                              elevation: pageNum - topPage < 5
                                  ? Tween<double>(
                                          begin:
                                              printPreviewImgsTransform[pageNum]
                                                  .elevation,
                                          end: 10.0)
                                      .animate(CurvedAnimation(
                                          parent:
                                              printPreviewImgsTransform[pageNum]
                                                  ?.animScale,
                                          curve: Curves.easeOutCirc,
                                          reverseCurve: Curves.easeInCirc)
                                        ..addListener(() {
                                          setState(() {});
                                        }))
                                      .value
                                  : 0,
                              child: InkWell(
                                  // When the user taps the button, show a snackbar.
                                  onTap: () {
                                    _pickFile();
                                  },
                                  child: AspectRatio(
                                      aspectRatio: 8.5 / 11.0,
                                      child: Stack(children: [
                                        Center(child: printPreviewIcon),
                                        Positioned.fill(child: content)
                                      ]))))))),
            ));
  }

  @override
  initState() {
    super.initState();
    printPreviewImgsTransform = [
      CardTransform(
          translate: Offset(0.0, 0.0),
          elevation: 1.0,
          scale: 1.0,
          animScale: AnimationController(vsync: this))
    ];
  }

  Widget build(BuildContext context) {
    return Stack(
        alignment: Alignment.center,
        children: pageCount != 0
            ? _buildPreviewImgs()?.reversed?.toList()
            : [_createCard(Container(), 0)]);
  }
}
