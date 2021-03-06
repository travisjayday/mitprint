import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io' as Io;
import 'package:pdf_render/pdf_render.dart';
import 'dart:math';

class PrintPreviewView extends StatefulWidget {
  final Function(String) callback;
  final Function(int, int) pageChangeCallback;
  final _PrintPreviewViewState state = _PrintPreviewViewState();
  PrintPreviewView({this.callback, this.pageChangeCallback});

  /// Exposed pickFile method for MainScreen so that big button can call it
  void pickFile() async {
    state._pickFile();
  }

  /// used by MainScreen to set PrintPreviewView to grayscale / color
  void setGrayscale(gray, setState) {
    state.grayscale = gray;
    if (setState)
      state.setState((){});
  }

  /// used by MainScreen to reset view to initial state
  void clearPreview() {
    state.previewWidgets?.clear();
    state.rawImgs?.clear();
    state.initSingleCard();
    state.pageCount = 0;
    state.topPage = 0;
    state.endCount = 0;
    state.setState(() {});
  }

  @override
  _PrintPreviewViewState createState() => state;
}

/// Class that holds positioning / animation information for each card (page)
/// in the preview.
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

  bool grayscale = false;


  /// Initialize state
  @override
  initState() {
    super.initState();
    initSingleCard();
  }

  /// Build UI
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: _buildPreviewImgs());
  }

  /// Builds & returns the list of previewWidgets
  _buildPreviewImgs() {
    if (pageCount == 0) return [_createSimpleCard(Container(), 0)];
    if (previewWidgets != null) previewWidgets.clear();
    endCount =
    topPage - maxPageBuffer + 1 > 0 ? topPage - maxPageBuffer + 1 : 0;
    for (int i = endCount; i < pageCount; i++) {
      previewWidgets.add(_createCard(
          Container(
              foregroundDecoration: BoxDecoration(
                  color: grayscale ? Colors.grey : null,
                  backgroundBlendMode: grayscale ? BlendMode.saturation : null),
              child: rawImgs[i]),
          i));
    }
    return previewWidgets;
  }

  /// Create a single CardWidget
  Widget _createCard(Widget content, int pageNum) {
    return ScaleTransition(
      scale: Tween(begin: printPreviewImgsTransform[pageNum]?.scale, end: 1.3)
          .animate(printPreviewImgsTransform[pageNum]?.animScale),
      child: SlideTransition(
          position: Tween<Offset>(
              begin: printPreviewImgsTransform[pageNum]?.translate,
              end: Offset(0.9, 0))
              .animate(CurvedAnimation(
              parent: printPreviewImgsTransform[pageNum]?.animScale,
              curve: Curves.easeOutCirc,
              reverseCurve: Curves.easeInCirc)),
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
                    printPreviewImgsTransform[topPage]?.animScale?.forward();
                    topPage--;
                  });
                } else if (details.delta.dx < 0 &&
                    pageNum == topPage &&
                    currentPan == pageNum &&
                    pageNum < pageCount - 1) {
                  // swipe left
                  topPage++;
                  setState(() {
                    printPreviewImgsTransform[topPage]?.animScale?.reverse();
                  });
                }
                widget.pageChangeCallback(pageCount - topPage, pageCount);
              },
              child: _createSimpleCard(content, pageNum))),
    );
  }

  Widget _createSimpleCard(Widget content, int pageNum) {
    return Container(
        color: Colors.transparent,
        width: MediaQuery.of(context).size.height * 0.64,
        height: MediaQuery.of(context).size.height * 0.64,
        alignment: Alignment.center,
        padding: EdgeInsets.all(10),
        child: Material(
            color: Colors.white,
            elevation: printPreviewImgsTransform.length > 0
                ? Tween<double>(
                begin: printPreviewImgsTransform[pageNum]?.elevation,
                end: 10.0)
                .animate(CurvedAnimation(
                parent: printPreviewImgsTransform[pageNum]?.animScale,
                curve: Curves.easeOutCirc,
                reverseCurve: Curves.easeInCirc)
              ..addListener(() {
                setState(() {});
              }))
                .value
                : 1.0,
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
                    ])))));
  }

  initSingleCard() {
    printPreviewImgsTransform = [
      CardTransform(
          translate: Offset(0.0, 0.0),
          elevation: 1.0,
          scale: 1.0,
          animScale: AnimationController(vsync: this))
    ];
  }

  /// Prompts user to pick a file, then starts the rendering process
  void _pickFile() async {
    bool unsupported = false;
    if (pickingFile) return;
    pickingFile = true;

    var path = await FilePicker.getFilePath(type: FileType.ANY);
    pickingFile = false;
    print("Selected file: " + path.toString());
    if (path != null) {
      pageCount = 0;
      print("page count: " + pageCount.toString());

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

      if (printPreviewImgsTransform == null)
        printPreviewImgsTransform = new List<CardTransform>();
      else
        printPreviewImgsTransform.clear();

      setState(() {
        printPreviewIcon = SpinKitRing(color: Colors.grey[300], size: 110);
        initSingleCard();
      });

      if (path.endsWith(".pdf")) {
        await _renderPdfPreview(path);
        widget.pageChangeCallback(pageCount - topPage, pageCount);
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
        widget.pageChangeCallback(pageCount - topPage, pageCount);
      } else {
        print("Unsupported FileType!!!");
        unsupported = true;
      }
    } else {
      // selected file is null (user cancelled or didnt select file)
      if (path != "") return;
    }
    setState(() {
      if (!unsupported)
        printPreviewIcon = Icon(Icons.add, color: Colors.grey[400], size: 100);
      else
        printPreviewIcon =
            Text("Filetype not recongized.\n\nPrint at your own risk.");
    });
  }


  /// Load a pdf file and populate data lists in state
  _renderPdfPreview(String filePath) async {
    // get PDF data from file
    final PdfDocument doc = await PdfDocument.openFile(filePath);

    if (printPreviewImgsTransform == null)
      printPreviewImgsTransform = new List<CardTransform>();
    else
      printPreviewImgsTransform.clear();

    // Populate transform and raw preiew lists from back to front
    // E.g. the last page is the first in the list. This makes it so
    // that the last page is at the bottom of the stack in the build method
    for (var i = doc.pageCount - 1; i >= 0; i--) {
      PdfPage page = await doc.getPage(i + 1);
      PdfPageImage pageImage = await page.render();
      rawImgs.add(RawImage(image: pageImage.image));
      printPreviewImgsTransform.add(
        CardTransform(
            scale: 1,
            translate: Offset(0.0, 0.05 - 0.05 / (pow(1.5, i))),
            elevation: 2 * (doc.pageCount - i) / doc.pageCount + 1,
            animScale: AnimationController(
                duration: const Duration(milliseconds: 500), vsync: this)),
      );
    }
    pageCount = doc.pageCount;
    topPage = pageCount - 1;
    /* the top page in the stack has the greatest index
                                 e.g. first page in pdf has index pageCount -1*/
    doc.dispose(); // dispose of pdf in memory
  }
}
