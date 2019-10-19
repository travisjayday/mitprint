import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io' as Io;
import 'dart:convert';
import 'package:pdf_render/pdf_render.dart';

class PrintPreviewView extends StatefulWidget {
  Function(String) callback;
  final _PrintPreviewViewState state = _PrintPreviewViewState();

  PrintPreviewView({this.callback});

  void pickFile() async {
    state._pickFile();
  }

  @override
  _PrintPreviewViewState createState() => state;
}

class _PrintPreviewViewState extends State<PrintPreviewView> {
  String filePath;
  List<Widget> printPreviewImgs = null;
  Widget printPreviewIcon = Icon(Icons.add, color: Colors.grey[400], size: 100);
  int pageCount = 1;
  int currentPage = 1;
  PdfDocument pdfPreviewDoc;

  _renderPdfPreview(int pageNum) async {
    final PdfDocument doc = await PdfDocument.openFile(filePath);

    if (printPreviewImgs == null)
      printPreviewImgs = new List<Widget>();
    else
      printPreviewImgs.clear();

    pageCount = doc.pageCount;
    for (var i = 0; i < doc.pageCount; i++) {
      PdfPage page = await doc.getPage(i + 1);
      PdfPageImage pageImage = await page.render();
      printPreviewImgs
          .add(_createCard(RawImage(image: pageImage.image), i * 1.0));
    }

    setState(() {
      pageCount = doc.pageCount;
      currentPage = pageNum;
    });

    pdfPreviewDoc = doc;
  }

  _renderPdfPage(int i) async {
    PdfPage page = await pdfPreviewDoc.getPage(i);
    PdfPageImage pageImage = await page.render();

    setState(() {
      printPreviewImgs[i] = RawImage(image: pageImage.image);
    });
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
  List<Widget> cardList;
  // page on top has zero offset
  Widget _createCard(Widget content, double offset) {
    return Align(
      alignment: Alignment(0, -0.4),
      child: Container(
          color: Colors.transparent,
          width: 450,
          height: 450,
          alignment: Alignment.center,
          padding: EdgeInsets.all(10),
          child: Transform.scale(scale: (offset + 1) / (pageCount + 1), child: Material(
              color: Colors.white,
              elevation: 2,
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
                      ])))))),
    );
  }

  Widget build(BuildContext context) {
    return Stack(
        alignment: Alignment.center,
        children: printPreviewImgs?.reversed?.toList() ?? [_createCard(Container(), 0.70)]);
  }
}
