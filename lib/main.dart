import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ssh/ssh.dart';
import 'package:ssh/ssh.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:flutter/services.dart';
import "password.dart";
import 'package:shared_preferences/shared_preferences.dart';
import 'backgroundPainter.dart';
import 'ClipShadowPath.dart';
import 'backgroundClipper.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'mitprintSettings.dart';
import 'dart:io' as Io;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  String filePath = "";
  String user = SSH_USER;
  String password = SSH_PASS;
  String kerb_user = "";
  String kerb_pass = "";
  String printer = "mitprint";
  String auth_method = "1";

  TextEditingController kerbPassTextController = TextEditingController();
  TextEditingController kerbUserTextController = TextEditingController();

  bool remember_pass = false;

  var printPreviewImg;
  int pageCount = 1;
  int currentPage = 1;
  PdfDocument pdfPreviewDoc;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  static const platform = const MethodChannel('flutter.native/helper');

  _diskRead(key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key) ?? null;
    print('read: $value');
    return value;
  }

  _diskReadBool(key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(key) ?? null;
    print('read: $value');
    return value;
  }

  _diskWrite(key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
    print('saved $value');
  }

  _renderPdfPreview(int pageNum) async {
    final PdfDocument doc = await PdfDocument.openFile(widget.filePath);
    PdfPage page = await doc.getPage(pageNum);
    PdfPageImage pageImage = await page.render();

    var data = await pageImage.image.toByteData();
    Uint8List tmp =
        await data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    print(tmp);
    setState(() {
      widget.pageCount = doc.pageCount;
      widget.currentPage = pageNum;
      widget.printPreviewImg = RawImage(image: pageImage.image);
    });

    doc.dispose();

    widget.pdfPreviewDoc = doc;
  }

  void _pickFile() async {
    var path = await FilePicker.getFilePath(type: FileType.ANY);
    if (path != null) {
      widget.filePath = path;
      if (widget.filePath.endsWith(".pdf")) {
        await _renderPdfPreview(1);
      } else if (widget.filePath.endsWith(".jpg") ||
          widget.filePath.endsWith(".png") ||
          widget.filePath.endsWith(".bmp") ||
          widget.filePath.endsWith(".jpeg")) {
        setState(() {
          widget.printPreviewImg = Image.file(new Io.File(widget.filePath));
        });
      } else {
        // TODO: Better user feedback
        print("Unsupported FileType!!!");
      }
    } else
      widget.filePath = "";
  }

  void _printFile() async {
    if (widget.filePath == "") {
      print("No file was selected, picking file...");
      await _pickFile();
      return;
    }
    String stored = await _diskRead("kerb_user");
    if (stored != null) {
      widget.kerb_user = stored;
    }
    stored = await _diskRead("kerb_pass");
    if (stored != null) {
      widget.kerb_pass = stored;
    }
    var boo = await _diskReadBool("remember_pass");
    if (boo != null) {
      widget.remember_pass = boo;
    }

    if (widget.kerb_user == "" || widget.kerb_pass == "") {
      print("No user/pass was selected...");
      await _displayKerbDialog(context);
      if (widget.kerb_user == "") {
        print("User action: Cancel");
        return;
      } else {
        await _diskWrite("kerb_user", widget.kerb_user);
        if (widget.remember_pass)
          await _diskWrite("kerb_pass", widget.kerb_pass);
        /*await _diskWrite(
            "remember_pass", widget.remember_pass ? "true" : "false");*/
      }
      print("Attempting to start printjob for user: ${widget.kerb_user}...");
    }

    var client = new SSHClient(
        host: "mitprint.xvm.mit.edu",
        port: 22,
        username: widget.user,
        passwordOrKey: widget.password);

    String result;

    try {
      // Create SSH session
      print("Attempting to create SSH session with " + client.host + "...");
      result = await client.connect();
      print("[Result] " + result);

      if (result == "session_connected") {
        var dir = "${widget.kerb_user}_printFiles";

        print("Removing pre-existing directory...");
        result = await client.execute("rm -rf " + dir);
        print("[Result]" + result);

        // Create SFTP Session
        print("Attempting to connect to SFTP...");
        result = await client.connectSFTP();
        print("[Result] " + result);

        if (result == "sftp_connected") {
          // Upload PrintJob File
          print("Creating temporary directory...");
          result = await client.sftpMkdir(dir);
          print("[Result] " + result);
          print("Uploading print files to " + dir);
          result = await client.sftpUpload(path: widget.filePath, toPath: dir);
          print("[Result] " + result);
          print("Disconnecting from SFTP...");

          // Disconnect form SFTP session
          client.disconnectSFTP();

          print("Re-connecting to client...");
          result = await client.connect();

          result = await client.startShell(
              ptyType: "xterm", // defaults to vanilla
              callback: (dynamic res) {
                print(res); // read from shell
              });

          // Execute ./printJob Command on mitprint.xvm.mit.edu
          String cmd = "expect /home/${SSH_USER}/printJob.sh " +
              "${widget.kerb_user} " +
              "${widget.kerb_pass} " +
              "${widget.auth_method} " +
              "${dir} " +
              "${widget.printer}";
          print("Running printJob command: `" + cmd + "`...");
          result = await client.writeToShell(cmd + "\n");
          print("[Result]" + result);

          new Future.delayed(
            const Duration(seconds: 60),
            () async {
              //client.closeShell();
              print("Disconnecting from SSH session...");
              client.disconnect();
            },
          );
          // Disconnect from SSH session
        }
      } else {
        print("[Warning] No SSH session is connected...");
      }
    } on PlatformException catch (e) {
      print(
          '[Error] in client.connect(): ${e.code}\n[Error] Message: ${e.message}');
    }
  }

  _displayKerbDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Kerberos Credentials'),
            content: Column(children: [
              TextField(
                controller: widget.kerbUserTextController
                  ..text = widget.kerb_user,
                decoration: InputDecoration(hintText: "Kerb username"),
              ),
              TextField(
                controller: widget.kerbPassTextController,
                decoration: InputDecoration(hintText: "Kerb password"),
                obscureText: true,
              ),
              CheckboxListTile(
                onChanged: (bool value) {
                  widget.remember_pass = value;
                },
                title: Text("Remember password"),
                value: widget.remember_pass,
              )
            ]),
            actions: <Widget>[
              new FlatButton(
                child: new Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text('CONTINUE'),
                onPressed: () {
                  widget.kerb_user = widget.kerbUserTextController.text;
                  widget.kerb_pass = widget.kerbPassTextController.text;
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(child: Stack(children: [
          Center(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 90),
                  child: Material(
                      color: Colors.white,
                      elevation: 2,
                      child: InkWell(
                          // When the user taps the button, show a snackbar.
                          onTap: () {
                            _pickFile();
                          },
                          child: Padding(
                              padding: EdgeInsets.all(00),
                              child: AspectRatio(
                                aspectRatio: 8.5 / 11.0,
                                child: Container(
                                    padding: EdgeInsets.only(left: 10.0),
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    child: Center(child: AspectRatio(
                                        aspectRatio: 8.5 /11.0, child: widget.printPreviewImg))),
                              )))))),
          Padding(
              padding: EdgeInsets.fromLTRB(23, 50, 25, 0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("MIT Print"),
                    Text(
                        "Page ${widget.currentPage.toString()}/${widget.pageCount.toString()}")
                  ])),
          IgnorePointer(
              child: ClipShadowPath(
            clipper: SideArrowClip(),
            shadow: Shadow(blurRadius: 6, color: Color.fromRGBO(0, 0, 0, 0.4)),
            child: Container(
                color: Colors.grey[900],
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
                        color: Colors.grey[900], size: 70)) //Your widget here,
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
        ])));
    /*Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: CustomPaint(

          painter: BackgroundPainter(),
          child: Container(width: MediaQuery.of(context).size.width, child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("MIT Print"),
                Column(children: [
                  Text(widget.filePath),
                  RaisedButton(onPressed: _pickFile, child: Text("Pick File")),
                  Padding(
                      padding: EdgeInsets.only(bottom: 20.0),
                      child: RaisedButton(
                          onPressed: _printFile,
                          color: Colors.white,
                          padding: const EdgeInsets.all(30.0),
                          shape: CircleBorder(),
                          child: Icon(Icons.print,
                              color: Colors.blue, size: 90)) //Your widget here,
                      ),
                ])
              ]),
        ))));*/
  }
}
