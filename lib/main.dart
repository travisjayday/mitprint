import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ssh/ssh.dart';
import 'package:ssh/ssh.dart';
import 'package:flutter/services.dart';
import "password.dart";
import "textfield_in_alert.dart";

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
  String printer = "";
  String auth_method = "1";

  @override
  _MyHomePageState createState() => _MyHomePageState();

  @override
  void initState() {
    TextFieldAlertDialog();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  static const platform = const MethodChannel('flutter.native/helper');

  void pickFile() async {
    var path = await FilePicker.getFilePath(type: FileType.ANY);
    setState(() {
      if (path != null) {
        widget.filePath = path;
      } else
        widget.filePath = "File not Found";
    });
  }

  void printFile() async {
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
        var dir = widget.kerb_user + "_printFiles";

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
          print("Uploading print files...");
          result =
              await client.sftpUpload(path: widget.filePath, toPath: dir);
          print("[Result] " + result);
          print("Disconnecting from SFTP...");

          // Disconnect form SFTP session
          result = await client.disconnectSFTP();
          await client.connect();
       //   print("[Result]" + result);
          var result2 = await client.startShell(
              ptyType: "xterm", // defaults to vanilla
              callback: (dynamic res) {
                print(res);     // read from shell
              }
          );
          // Execute ./printJob Command on mitprint.xvm.mit.edu
          String cmd = "ls";
          print("Running printJob command: `" + cmd + "`...");
          //result = await client.execute(cmd);
          await client.writeToShell(cmd + "\n");
          print("[Result]" + result);

          // Disconnect from SSH session
          print("Disconnecting from SSH session...");
          result = await client.disconnect();
          print("[Result]" + result);
        }
      }
      else {
        print("[Warning] No SSH session is connected...");
      }
    } on PlatformException catch (e) {
      print('[Error] in client.connect(): ${e.code}\n[Error] Message: ${e.message}');
    }
    setState(() {
      widget.filePath = result;
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
        body: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Text("MIT Print"),
        Column(children: [
          Text(widget.filePath),
          RaisedButton(onPressed: pickFile, child: Text("Pick File")),
          RaisedButton(
              onPressed: printFile,
              color: Colors.blue,
              padding: const EdgeInsets.all(20.20),
              shape: CircleBorder(),
              child: Icon(Icons.print, color: Colors.white, size: 80))
        ])
      ]),
    ));
  }
}
