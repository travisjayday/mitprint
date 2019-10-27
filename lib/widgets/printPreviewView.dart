import 'package:flutter/material.dart';
import 'package:mit_print/screens/mainScreen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io' as Io;
import 'package:pdf_render/pdf_render.dart';
import 'dart:math';

class PrintPreviewView extends StatefulWidget {
  Function(String) callback;
  final _PrintPreviewViewState state = _PrintPreviewViewState();
  MainScreen mainScreen;
  PrintPreviewView({this.mainScreen, this.callback});

  void pickFile() async {
    state._pickFile();
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
  /// holds the finished CardWidgets
  List<Widget> previewWidgets;

  /// Holds the raw widgets that correspond to different pages
  List<Widget> rawImgs;

  /// List of CardTransform Objects
  ///
  /// Determines different transform properties for any card i at index i
  List<CardTransform> printPreviewImgsTransform;

  /// The icon that is displayed on an empty card
  Widget printPreviewIcon = Icon(Icons.add, color: Colors.grey[400], size: 100);

  /// The number of pages in PDF doc
  int pageCount = 0;

  /// The first (start) index of pages to show
  int topPage = 0;

  /// The last (end) index of pages to show
  int endCount = 0;

  /// Temp var to not double swipe cards
  int currentPan = -1;

  /// The number of pages shown at a time
  int maxPageBuffer = 3;

  /// Temp var to not double pick a file
  bool pickingFile = false;

  /// Load a pdf file and populate data lists in state
  _renderPdfPreview(String filePath) async {
    if (printPreviewImgsTransform == null)
      printPreviewImgsTransform = new List<CardTransform>();
    else
      printPreviewImgsTransform.clear();

    // get PDF data from file
    final PdfDocument doc = await PdfDocument.openFile(filePath);
    pageCount = doc.pageCount;

    // Populate transform and raw preiew lists from back to front
    // E.g. the last page is the first in the list. This makes it so
    // that the last page is at the bottom of the stack in the build method
    for (var i = pageCount - 1; i >= 0; i--) {
      PdfPage page = await doc.getPage(i + 1);
      PdfPageImage pageImage = await page.render();
      rawImgs.add(RawImage(image: pageImage.image));
      printPreviewImgsTransform.add(
        CardTransform(
            scale: 1,
            translate: Offset(0.0, 0.05 - 0.05 / (pow(1.5, i))),
            elevation: 2 * (pageCount - i) / pageCount + 1,
            animScale: AnimationController(
                duration: const Duration(milliseconds: 500), vsync: this)),
      );
    }
    topPage = pageCount - 1;
    /* the top page in the stack has the greatest index
                                 e.g. first page in pdf has index pageCount -1*/
    setState(() {}); // trigger rebuild to display new pdf
    doc.dispose(); // dispose of pdf in memory

  }

  /// Prompts user to pick a file, then starts the rendering process
  void _pickFile() async {
    setState(() {
      printPreviewIcon = SpinKitRing(color: Colors.grey[300], size: 110);
    });
    var path = await FilePicker.getFilePath(type: FileType.ANY);
    print("Selected file: " + path.toString());
    if (path != null) {
      widget.callback(path);
      // initialize or clear data lists
      if (previewWidgets == null)
        previewWidgets = new List<Widget>();
      else
        previewWidgets.clear();

      if (rawImgs == null)
        rawImgs = new List<Widget>();
      else
        rawImgs.clear();

      if (path.endsWith(".pdf")) {
        await _renderPdfPreview(path);
      } else if (path.endsWith(".jpg") ||
          path.endsWith(".png") ||
          path.endsWith(".bmp") ||
          path.endsWith(".jpeg")) {
        setState(() {
          pageCount = 1;
          topPage = 0;
          rawImgs.add(
              Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Image.file(new Io.File(path))),
              );
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

  /// Builds & returns the list of previewWidgets
  _buildPreviewImgs() {
    print("PREVIEW  BUILT");
    if (previewWidgets != null) previewWidgets.clear();
    endCount =
        topPage - maxPageBuffer + 1 > 0 ? topPage - maxPageBuffer + 1 : 0;
    for (int i = endCount; i < pageCount; i++) {
      previewWidgets.add(_createCard(rawImgs[i], i));
    }
    return previewWidgets;
  }

  /// Create a single CardWidget
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
                  // save card that is getting panned right now, to only
                  // swipe that card when onPanUpdate is called
                  onPanStart: (details) {
                    currentPan = pageNum;
                  },
                  onPanEnd: (details) {
                    currentPan = -1;
                  },
                  onPanUpdate: (details) {
                    if (details.delta.dx > 0 &&
                        pageNum == topPage &&
                        currentPan == pageNum &&
                        pageNum > endCount) {
                      // swipe right
                      setState(() {
                        printPreviewImgsTransform[topPage]
                            ?.animScale
                            ?.forward();
                        topPage--;
                      });
                    } else if (details.delta.dx < 0 &&
                        pageNum == topPage &&
                        currentPan == pageNum &&
                        pageNum < pageCount - 1) {
                      // swipe left
                      topPage++;
                      setState(() {
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
                          elevation: Tween<double>(
                                  begin: printPreviewImgsTransform[pageNum]
                                      .elevation,
                                  end: 10.0)
                              .animate(CurvedAnimation(
                                  parent: printPreviewImgsTransform[pageNum]
                                      ?.animScale,
                                  curve: Curves.easeOutCirc,
                                  reverseCurve: Curves.easeInCirc)
                                ..addListener(() {
                                  setState(() {});
                                }))
                              .value,
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

  /// Initialize state
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

  /// Build UI
  Widget build(BuildContext context) {
    return Stack(
        alignment: Alignment.center,
        children: pageCount != 0
            ? _buildPreviewImgs()
            : [_createCard(Container(), 0)]);
  }
}
