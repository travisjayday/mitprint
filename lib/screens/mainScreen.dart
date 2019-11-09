import 'package:flutter/material.dart';
import 'package:mitprint/screens/loadingScreen.dart';
import 'package:mitprint/widgets/printDialog.dart';
import 'package:mitprint/widgets/printPreviewView.dart';
import 'package:mitprint/widgets/terminalShell.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mitprint/graphics/backgroundClipper.dart';
import 'package:mitprint/graphics/clipShadowPath.dart';
import 'package:mitprint/screens/mitprintSettings.dart';
import 'package:mitprint/widgets/kerbDialog.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

import '../pharos/athenaSSH.dart';

class MainScreen extends StatefulWidget {
  MainScreen({Key key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const platform = const MethodChannel('flutter.native/helper');
  SharedPreferences prefs;

  String filePath = "";
  String kerbUser = "";
  String kerbPass = "";
  String printer = "mitprint";
  String authMethod = "1";
  bool rememberPass = false;

  List<String> terminalLines = new List<String>();
  String currentStep = "";
  double printProgress = 0.0;

  int currentPagePreview = 0;
  int totalPagePreview = 0;

  PrintPreviewView printPreviewView;

  void _togglePrinter() {
    setState(() {
      if (printer == "mitprint") {
        printer = "mitprint-color";
      } else {
        printer = "mitprint";
      }
      _updatePrintPreviewColor();
    });
    prefs.setBool("color_print", printer == "mitprint-color");
  }

  void _updatePrintPreviewColor() {
    setState(() => printPreviewView.setGrayscale(printer == "mitprint", true));
  }

  void _printFile() async {
    prefs = await SharedPreferences.getInstance();
    terminalLines = new List<String>();

    if (filePath == "") {
      print("No file was selected, picking file...");
      printPreviewView.pickFile();
      _updatePrintPreviewColor();
      return;
    }

    kerbUser = (prefs.getString("kerbUser")) ?? "";
    kerbPass = (prefs.getString("kerbPass")) ?? "";
    printer = ((prefs.getBool("color_print")) ?? false)
        ? "mitprint-color"
        : "mitprint";
    rememberPass = (prefs.getBool("rememberPass")) ?? false;
    authMethod = (prefs.getString("authMethod")) ?? "1";

    if (kerbUser == "" || kerbPass == "") {
      print("No user/pass was selected...");
      var result = await showDialog(
          context: context,
          builder: (context) {
            return new KerbDialog(
              pass: kerbPass,
              usr: kerbUser,
              remember: rememberPass,
            );
          });

      if (result == null) {
        print("User action: Cancel");
        return;
      }

      kerbUser = result[0];
      kerbPass = result[1];
      rememberPass = result[2];

      if (kerbUser == "") {
        print("Did not specify username!");
        return;
      } else if (kerbPass == "") {
        print("Did not specify password");
        return;
      } else {
        await prefs.setBool("rememberPass", rememberPass);
        await prefs.setString("kerbUser", kerbUser);
        if (rememberPass) await prefs.setString("kerbPass", kerbPass);
      }
    }

    var printConfig = await showDialog(
        context: context,
        builder: (context) {
          return new PrintDialog(
            fileName: filePath,
          );
        });
    if (printConfig == null) return;
    String copies = printConfig["copies"];
    String title = printConfig["title"];

    AthenaSSH(platform)
      ..submitPrintjob({
        "user": kerbUser,
        "pass": kerbPass,
        "auth": authMethod,
        "filePath": filePath,
        "printer": printer,
        "copies": copies,
        "title": title
      }, logString: (str) {
        setState(() {
          if (str.trim().length == 0) return;
          terminalLines.add(str);
        });
      }, setStep: (desc, percentage) {
        setState(() {
          currentStep = desc;
          printProgress = percentage;
        });
      }, printSuccess: () {
        printPreviewView.clearPreview();
      });
  }

  Future<Null> _loadSharedPrefs() async {
    print("loading shared prefs");
    prefs = await SharedPreferences.getInstance();
    setState(() {
      kerbUser = prefs.getString("kerbUser") ?? "";
      printer = ((prefs.getBool("color_print")) ?? false)
          ? "mitprint-color"
          : "mitprint";
      authMethod = prefs.getString("authMethod");
      if (authMethod == null) {
        authMethod = "1";
        prefs.setString("authMethod", "1");
      }
    });
  }

  @override
  void initState() {
    super.initState();
    print("Inititing state");
    _loadSharedPrefs();
    printPreviewView = PrintPreviewView(
      callback: (str) {
        filePath = str;
      },
      pageChangeCallback: (currentPage, totalPages) {
        setState(() {
          currentPagePreview = currentPage;
          totalPagePreview = totalPages;
        });
      },
    );
    printPreviewView.setGrayscale(printer == "mitprint", false);
    BackButtonInterceptor.add(_cancelSSH);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(_cancelSSH);
    super.dispose();
    print("Disposing printjob");
    platform.invokeMethod('cancelPrintjob');
  }

  _buildSummaryText() {
    List<Widget> texts = List<Widget>();
    Widget _txtFmt(String s) {
      return Expanded(
          flex: 33,
          child: Center(
              child: Text(s,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600))));
    }

    if (kerbUser != "")
      texts.add(_txtFmt(kerbUser));
    else
      texts.add(_txtFmt(printer));
    texts.add(_txtFmt("$currentPagePreview/$totalPagePreview"));
    texts.add(_txtFmt(printer == "mitprint" ? "black/white" : "color"));
    return texts;
  }

  bool _cancelSSH(bool stopDefaultButtonEvent) {
    if (currentStep == "") return false;
    setState(() { currentStep = ""; });
    print("currentSTEP: " + currentStep);
    platform.invokeMethod('cancelPrintjob');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: Stack(children: [
          Positioned.fill(
              bottom: MediaQuery.of(context).size.height * 0.19,
              // 65dp = appbar height, 24dp = statusbar height, 30dp = blue banner height
              top: totalPagePreview > 0 ? 65 + 24 + 32.0 : 65.0 + 24.0,
              child: printPreviewView,
    ),
          IgnorePointer(
              child: ClipShadowPath(
            clipper: BackgroundClipper(),
            shadow: Shadow(blurRadius: 4, color: Color.fromRGBO(0, 0, 0, 0.6)),
            child: Container(
                color: Theme.of(context).primaryColor,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height),
          )),
          Positioned.fill(
            bottom: 15.0,
            child: Align(
                alignment: Alignment.bottomCenter,
                child: RaisedButton(
                    onPressed: _printFile,
                    color: Colors.white,
                    elevation: 10,
                    padding: const EdgeInsets.all(30.0),
                    shape: CircleBorder(),
                    child: Icon(Icons.print,
                        color: Theme.of(context).primaryColor,
                        size: 70)) //Your widget here,
                ),
          ),
          Positioned.fill(
              left: MediaQuery.of(context).size.width * 0.15,
              right: MediaQuery.of(context).size.width * 0.15 + 10.0,
              bottom: 10.0,
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              size: 40,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MitPrintSettings()),
                              );
                              await _loadSharedPrefs();
                              _updatePrintPreviewColor();
                            }),
                        IconButton(
                          icon: Icon(
                              printer == "mitprint"
                                  ? Icons.invert_colors_off
                                  : Icons.invert_colors,
                              size: 35,
                              color: Colors.white),
                          onPressed: () {
                            _togglePrinter();
                          },
                        )
                      ]))),
          LoadingScreen(
            terminalShell: TerminalShell(textLines: terminalLines),
            currentStep: currentStep,
            percentProgress: printProgress,
            doneCallback: () {
              setState(() {
                currentStep = "";
                printProgress = 0.0;
              });
            },
          ),
          Positioned.fill(
              top: 0,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                        height: 65.0 + 24.0,
                        child: Material(
                            elevation: 4,
                            color: Theme.of(context).primaryColor,
                            child: Align(
                                alignment: Alignment(-0.833333, .33333),
                                child: Text("MIT Print Mobile",
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .title)))),
                    AnimatedContainer(
                        height: totalPagePreview > 0 ? 32 : 0,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.bounceInOut,
                        child: Material(
                            elevation: 4,
                            color: Colors.blue,
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: _buildSummaryText())))
                  ])),
        ]));
  }
}
