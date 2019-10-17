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
  Widget printPreviewImg;
  Widget printPreviewIcon = Icon(Icons.add, color: Colors.grey[400], size: 100);
  int pageCount = 1;
  int currentPage = 1;
  PdfDocument pdfPreviewDoc;

  _renderPdfPreview(int pageNum) async {
    final PdfDocument doc = await PdfDocument.openFile(filePath);
    PdfPage page = await doc.getPage(pageNum);
    PdfPageImage pageImage = await page.render();

    setState(() {
      pageCount = doc.pageCount;
      currentPage = pageNum;
      printPreviewImg = RawImage(image: pageImage.image);
    });

    //doc.dispose();

    pdfPreviewDoc = doc;
  }

  void _pickFile() async {
    setState(() {
      printPreviewIcon = SpinKitRing(color: Colors.grey[300], size: 110);
    });
    var path = await FilePicker.getFilePath(type: FileType.ANY);
    print("Selected file: " + path.toString());
    if (path != null) {
      widget.callback(path);
      filePath = path;
      if (path.endsWith(".pdf")) {
        await _renderPdfPreview(1);
      } else if (path.endsWith(".jpg") ||
          path.endsWith(".png") ||
          path.endsWith(".bmp") ||
          path.endsWith(".jpeg")) {
        setState(() {
          printPreviewImg = Padding(
              padding: EdgeInsets.all(30.0),
              child: Image.file(new Io.File(path)));
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

  Widget build(BuildContext context) {
    /*
    Padding(
              padding: EdgeInsets.fromLTRB(23, 50, 25, 0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("MIT Print"),
                    Text(
                        "Page ${widget.currentPage.toString()}/${widget.pageCount.toString()}")
                  ])),
     */
    return new
      Swiper(
            itemBuilder: (BuildContext context, int index) {
              return new Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.all(10),
                  child: Material(
                      color: Colors.white,
                      elevation: 2,
                      child: InkWell(
                          // When the user taps the button, show a snackbar.
                          onTap: () {
                            _pickFile();
                          },
                          child: AspectRatio(
                            aspectRatio: 8.5 / 11.0,
                            child: Container(

                                child: AspectRatio(
                                    aspectRatio: 8.5 / 11.0,
                                    child: Stack(children: [
                                      Center(child: printPreviewIcon),
                                      Center(child: printPreviewImg)
                                    ]))),
                          ))));
            },
            itemCount: 10,
            pagination: new SwiperPagination(
                builder: const DotSwiperPaginationBuilder(
                    size: 8.0, activeSize: 8.0, space: 5.0, color: Colors.black12),
                alignment: Alignment.topCenter),
            itemWidth: MediaQuery.of(context).size.width * 0.95,
            itemHeight: (11.0 / 8.5) * MediaQuery.of(context).size.width * 0.95,
            layout: SwiperLayout.TINDER,
            loop: false);
    /*Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 90),
        child: Material(
            color: Colors.white,
            elevation: 2,
            child: InkWell(
                // When the user taps the button, show a snackbar.
                onTap: () {
                  _pickFile();
                },
                child: AspectRatio(
                  aspectRatio: 8.5 / 11.0,
                  child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: AspectRatio(
                          aspectRatio: 8.5 / 11.0,
                          child: Stack(children: [
                            Center(child: printPreviewIcon),
                            Center(child: printPreviewImg)
                          ]))),
                ))));*/
  }
}
