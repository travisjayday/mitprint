import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _counter = 0;
  static const platform = const MethodChannel('flutter.native/helper');
  var prefs = null;

  _diskReadString(key) async => prefs?.getString(key);
  _diskReadBool(key) async => prefs?.getBool(key);
  _diskWriteString(key, value) async => prefs?.setString(key, value);
  _diskWriteBool(key, value) async => prefs?.setBool(key, value);

  void _log(String str, [String type]) {
    if (str.trim().length == 0) return;
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
    widget.terminalLines.add(str.trimRight());
  }

  void _updateProgress(String desc, double stepNum, double totalSteps) {
    setState(() {
      widget.currentStep = desc;
      widget.printProgress = stepNum / totalSteps;
    });
  }

  void _printFile() async {
    prefs = await SharedPreferences.getInstance();
    widget.terminalLines = new List<String>();

    if (widget.filePath == "") {
      print("No file was selected, picking file...");
      return await printPreviewView.pickFile();
    }

    widget.kerb_user = (await _diskReadString("kerb_user")) ?? "";
    widget.kerb_pass = (await _diskReadString("kerb_pass")) ?? "";
    widget.remember_pass = (await _diskReadBool("remember_pass")) ?? false;
    widget.auth_method = (await _diskReadString("auth_method")) ?? "1";

    if (widget.kerb_user == "" || widget.kerb_pass == "") {
      print("No user/pass was selected...");
      var result = await showDialog(
          context: context,
          builder: (context) {
            return new KerbDialog(
              kerbPass: widget.kerb_pass,
              kerbUser: widget.kerb_user,
              rememberPass: widget.remember_pass,
            );
          });

      if (result.toString() == "cancelled") {
        print("User action: Cancel");
        return;
      }

      widget.kerb_user = result[0];
      widget.kerb_pass = result[1];
      widget.remember_pass = result[2];

      if (widget.kerb_user == "") {
        print("Did not specify username!");
        return;
      } else if (widget.kerb_pass == "") {
        print("Did not specify password");
        return;
      } else {
        await _diskWriteBool("remember_pass", widget.remember_pass);
        await _diskWriteString("kerb_user", widget.kerb_user);
        if (widget.remember_pass)
          await _diskWriteString("kerb_pass", widget.kerb_pass);
      }
    }

    _log(
        "Attempting to start printjob for user: ${widget.kerb_user}...", "app");

    AthenaSSH()
      ..submitPrintjob(widget.kerb_user, widget.kerb_pass, widget.auth_method,
          widget.filePath, widget.printer, _updateProgress, _log);
  }

  PrintPreviewView printPreviewView;

  @override
  void initState() {
    super.initState();
    print("Inititing state");
    printPreviewView = PrintPreviewView(callback: (str) {
      widget.filePath = str;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body:
          Stack(children: [
          Positioned.fill(child: printPreviewView),
          IgnorePointer(
              child: ClipShadowPath(
            clipper: BackgroundClipper(),
            shadow: Shadow(blurRadius: 6, color: Color.fromRGBO(0, 0, 0, 0.4)),
            child: Container(
                color: Theme.of(context).primaryColor,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height),
          )),
          Positioned.fill(
              child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
                padding: EdgeInsets.only(bottom: 20.0),
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
          )),
          Positioned.fill(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 20.0, 14),
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
                                        builder: (context) =>
                                            MitPrintSettings()),
                                  );
                                }),
                            Container(
                                width: 40,
                                height: 40,
                                child: SvgPicture.asset(
                                  "assets/rgb2.svg",
                                ))
                          ])))),
          LoadingScreen(
            terminalShell: TerminalShell(textLines: widget.terminalLines),
            currentStep: widget.currentStep,
            percentProgress: widget.printProgress,
          ),
        ]));
  }
}
