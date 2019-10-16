import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mit_print/screens/loadingScreen.dart';
import 'package:mit_print/widgets/printPreviewView.dart';
import 'package:mit_print/widgets/terminalShell.dart';
import 'package:ssh/ssh.dart';
import 'package:ssh/ssh.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:flutter/services.dart';
import "../password.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mit_print/graphics/backgroundClipper.dart';
import 'package:mit_print/graphics/clipShadowPath.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:mit_print/screens/mitprintSettings.dart';
import 'package:mit_print/widgets/kerbDialog.dart';
import 'dart:io' as Io;
import 'dart:convert';

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
  double stepNum = 0;
  double totalSteps = 10;

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

  void _updateProgress(String step, [bool fullstep, bool done]) {
    if (fullstep == null || fullstep == false) stepNum++;
    if (done != null && done == true) stepNum = totalSteps;
    setState(() {
      widget.currentStep = step;
      widget.printProgress = stepNum / totalSteps;
    });
  }

  void _printFile() async {
    stepNum = 0.0;
    totalSteps = 17.0;
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

    var client = new SSHClient(
        host: "mitprint.xvm.mit.edu",
        port: 22,
        username: widget.user,
        passwordOrKey: widget.password);

    try {
      // STEP 1 -- Create SSH Session -----------
      _updateProgress("Connecting with SSH");
      _log("Attempting to create SSH session with ${client.host}...", "app");
      String result = await client.connect();
      _log(result, "result");
      // END STEP 1 -----------------------------

      if (result == "session_connected") {
        var dir = "${widget.kerb_user}_printFiles";

        // STEP 2 -- Remove Old Directories -----
        _updateProgress("Removing old files...");
        _log("Removing pre-existing directory...", "app");
        result = await client.execute("rm -rf " + dir);
        _log(result, "result");
        // END STEP 2 ---------------------------

        // STEP 3 -- Create SFTP Session --------
        _updateProgress("Connecting to SFTP");
        _log("Attempting to connect to SFTP...", "app");
        result = await client.connectSFTP();
        _log(result, "result");
        // END STEP 3 ---------------------------

        if (result == "sftp_connected") {
          // STEP 4 -- Upload PrintJob File -----
          _updateProgress("Uploading user files...", false);
          _log("Creating temporary directory...", "app");
          result = await client.sftpMkdir(dir);
          _log(result, "result");
          _log("Uploading print files to " + dir, "app");
          double step = stepNum;
          result = await client.sftpUpload(
            path: widget.filePath,
            toPath: dir,
            callback: (progress) {
              _log(progress.toString(), "server");
              stepNum = step + (progress / 100.0) * 2; // takes 2 steps
              _updateProgress("Uploading user files (${progress}%)...");
            },
          );
          _log(result, "result");
          _updateProgress("Disconnecting from SFTP...");
          _log("Disconnecting from SFTP...", "app");
          client.disconnectSFTP();
          // END STEP 4 -------------------------

          // STEP 5 -- Connecting to Athena -----
          _updateProgress("Connecting to Athena...");
          _log("Re-connecting to client...", "app");
          result = await client.connect();
          _log(result, "result");

          bool printSucc = false;
          result = await client.startShell(
              ptyType: "xterm",
              callback: (dynamic res) {
                _log(res, "server"); // read from shell
                if (res.toString().contains("request id is")) {
                  printSucc = true;
                  _log("Found success message! Printjob submitted!", "app");
                }
                print("res is: " + res.toString());
                if (res
                    .toString()
                    .contains("Permission denied, please try again")) {
                  _updateProgress("Invalid Athena Credentials!", null, true);
                  _log("Invalid athena credentials! Clearing username / pass");
                  _diskWriteString("kerb_user", "");
                  _diskWriteString("kerb_pass", "");
                }
                if (res.toString().contains("Connection refused")) {
                  _updateProgress(
                      "Connection refused! Check credentials.", null, true);
                  _log("Invalid athena credentials!");
                }
                // find json updates from logging to console
                RegExp regExp = new RegExp(r"\{.*\}");
                if (regExp.hasMatch(res)) {
                  String response = regExp.allMatches(res).first.group(0);
                  var status = json.decode(response);
                  _updateProgress(status["desc"]);
                  // check if status step is 6, the last step in printjob script
                  if (status["step"] == "6") {
                    if (printSucc) {
                      _updateProgress(
                          "Printjob Succesfully Submitted!", null, true);
                      _log("Script terminates successfully...", "app");
                    } else {
                      _updateProgress("Something Went Wrong", null, true);
                      _log("Script terminates unsuccessfully...", "app");
                    }
                    _log("Disconnecting from SSH server", "app");
                    client.disconnect();
                  }
                }
              });
          // END Step 5 -------------------------

          // STEP 6 -- Execute ./printJob Command on mitprint.xvm.mit.edu
          _updateProgress("Starting printjob...");

          // Note: the script has 6 sub-steps
          String cmd = "expect /home/${SSH_USER}/printJob.sh " +
              "${widget.kerb_user} " +
              "${widget.kerb_pass} " +
              "${widget.auth_method} " +
              "${dir} " +
              "${widget.printer}";
          _log("Running printJob command on server...", "app");
          result = await client.writeToShell(cmd + "\n");
          _log(result, "result");
          // END STEP 6

          new Future.delayed(
            const Duration(seconds: 60),
            () async {
              _log("Timeout Disconnecting from SSH session...", "app");
              client.disconnect();
            },
          );
        }
      } else {
        _log("No SSH session is connected... Terminating...", "warning");
      }
    } on PlatformException catch (e) {
      _log('Fatal: ${e.code}\n[Error] Message: ${e.message}', "error");
      _updateProgress("Something went wrong...", null, true);
    }
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
        body: Center(
            child: Stack(children: [
          Center(
              child: printPreviewView),
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
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                      padding: EdgeInsets.only(bottom: 14.0),
                      child: IconButton(
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
                          })))),
          Positioned.fill(
              child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                      padding: EdgeInsets.only(bottom: 14.0),
                      child: IconButton(
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
                          })))),
          LoadingScreen(
            terminalShell: TerminalShell(textLines: widget.terminalLines),
            currentStep: widget.currentStep,
            percentProgress: widget.printProgress,
          ),
        ])));
  }
}
