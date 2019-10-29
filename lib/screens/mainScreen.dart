import 'package:flutter/material.dart';
import 'package:mit_print/pharos/athenaSSH.dart';
import 'package:mit_print/screens/loadingScreen.dart';
import 'package:mit_print/widgets/printPreviewView.dart';
import 'package:mit_print/widgets/terminalShell.dart';
import 'package:flutter/services.dart';
import "../password.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mit_print/graphics/backgroundClipper.dart';
import 'package:mit_print/graphics/clipShadowPath.dart';
import 'package:mit_print/screens/mitprintSettings.dart';
import 'package:mit_print/widgets/kerbDialog.dart';

class MainScreen extends StatefulWidget {
  MainScreen({Key key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const platform = const MethodChannel('flutter.native/helper');
  var prefs = null;
  String filePath = "";
  String user = SSH_USER;
  String password = SSH_PASS;
  String kerb_user = "";
  String kerb_pass = "";
  String printer = "mitprint";
  String auth_method = "1";

  bool remember_pass = false;

  List<String> terminalLines = new List<String>();
  String currentStep = "";
  double printProgress = 0.0;

  int currentPagePreview = 0;
  int totalPagePreview = 0;

  _diskReadString(key) async => prefs?.getString(key);
  _diskReadBool(key) async => prefs?.getBool(key);
  _diskWriteString(key, value) async => prefs?.setString(key, value);
  _diskWriteBool(key, value) async => prefs?.setBool(key, value);

  void _togglePrinter() {
    setState(() {
      if (printer == "mitprint") {
        printer = "mitprint-color";
      } else {
        printer = "mitprint";
      }
      printPreviewView.setGrayscale(printer == "mitprint");
      _diskWriteBool("color_print", printer == "mitprint-color");
    });
  }

  void _log(String str, [String type]) {
    if (str.trim().length == 0) return;
    // hide password
    if (str.contains(kerb_pass))
      str = str.replaceAll(kerb_pass, "*" * kerb_pass.length);
    switch (type) {
      case "app":
        str = "[APP_LOG] " + str;
        break;
      case "result":
        str = "[Result] " + str;
        break;
      case "server":
        str = "[SERVER_LOG] " + str;
        break;
      case "warning":
        str = "[WARNING] " + str;
        break;
      case "error":
        str = "[ERROR] " + str;
    }
    print(str);
    terminalLines.add(str.trimRight());
  }

  void _updateProgress(String desc, double stepNum, double totalSteps) {
    setState(() {
      currentStep = desc;
      printProgress = stepNum / totalSteps;
    });
  }

  void _printFile() async {
    prefs = await SharedPreferences.getInstance();
    terminalLines = new List<String>();

    if (filePath == "") {
      print("No file was selected, picking file...");
      return await printPreviewView.pickFile();
    }

    kerb_user = (await _diskReadString("kerb_user")) ?? "";
    kerb_pass = (await _diskReadString("kerb_pass")) ?? "";
    printer = ((await _diskReadBool("color_print")) ?? false)
        ? "mitprint-color"
        : "mitprint";
    remember_pass = (await _diskReadBool("remember_pass")) ?? false;
    auth_method = (await _diskReadString("auth_method")) ?? "1";

    if (kerb_user == "" || kerb_pass == "") {
      print("No user/pass was selected...");
      var result = await showDialog(
          context: context,
          builder: (context) {
            return new KerbDialog(
              kerbPass: kerb_pass,
              kerbUser: kerb_user,
              rememberPass: remember_pass,
            );
          });

      if (result.toString() == "cancelled") {
        print("User action: Cancel");
        return;
      }

      kerb_user = result[0];
      kerb_pass = result[1];
      remember_pass = result[2];

      if (kerb_user == "") {
        print("Did not specify username!");
        return;
      } else if (kerb_pass == "") {
        print("Did not specify password");
        return;
      } else {
        await _diskWriteBool("remember_pass", remember_pass);
        await _diskWriteString("kerb_user", kerb_user);
        if (remember_pass) await _diskWriteString("kerb_pass", kerb_pass);
      }
    }

    _log("Attempting to start printjob for user: ${kerb_user}...", "app");

    await AthenaSSH()
      ..submitPrintjob(kerb_user, kerb_pass, auth_method, filePath, printer,
          _updateProgress, _log, /*on success*/ () {
        printPreviewView.clearPreview();
        setState(() {
          totalPagePreview = 0;
          currentPagePreview = 0;
        });
      });
  }

  PrintPreviewView printPreviewView;

  Future<Null> loadSharedPrefs() async {
    print("loading shared prefs");
    prefs = await SharedPreferences.getInstance();
    setState(() {
      kerb_user = prefs.getString("kerb_user") ?? "";
      printer = ((prefs.getBool("color_print")) ?? false)
          ? "mitprint-color"
          : "mitprint";
    });
  }

  @override
  void initState() {
    super.initState();
    print("Inititing state");
    loadSharedPrefs();
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
      mainScreen: this.widget,
      grayscale: printer == "mitprint",
    );
  }

  _buildSummaryText() {
    List<Text> texts = List<Text>();
    Text _txtFmt(String s) {
      return Text(s,
          style: TextStyle(
            color: Colors.white,
          ));
    }

    if (kerb_user != "")
      texts.add(_txtFmt(kerb_user));
    else
      texts.add(_txtFmt(printer));
    texts.add(_txtFmt("$currentPagePreview/$totalPagePreview"));
    texts.add(_txtFmt(printer == "mitprint" ? "black/white" : "color"));
    return texts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: Stack(children: [
          Positioned.fill(
              bottom: 125,
              // 56dp = appbar height, 24dp = statusbar height, 30dp = blue banner height
              top: totalPagePreview > 0 ? 56.0 + 24.0 + 30.0 : 56.0 + 24.0,
              child: Align(
                alignment: Alignment.center,
                child: printPreviewView,
              )),
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MitPrintSettings()),
                              );
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
              currentStep = "";
              printProgress = 0.0;
            },
          ),
          Positioned.fill(
              top: 0,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                        height: 56.0 + 24.0,
                        color: Theme.of(context).primaryColor,
                        padding: EdgeInsets.fromLTRB(30, 24.0 + 15, 0, 0),
                        child: Text("MIT Pharos Mobile",
                            style: Theme.of(context).primaryTextTheme.title)),
                    AnimatedContainer(
                        height: totalPagePreview > 0 ? 30 : 0,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.bounceInOut,
                        color: Colors.blue,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _buildSummaryText()))
                  ])),
        ]));
  }
}
