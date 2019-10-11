import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ssh/ssh.dart';
import 'package:ssh/ssh.dart';
import 'package:flutter/services.dart';
import "password.dart";
import 'package:shared_preferences/shared_preferences.dart';

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

  _diskWrite(key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
    print('saved $value');
  }

  void _pickFile() async {
    var path = await FilePicker.getFilePath(type: FileType.ANY);
    setState(() {
      if (path != null) {
        widget.filePath = path;
      } else
        widget.filePath = "";
    });
  }

  void _printFile() async {
    if (widget.filePath == "") {
      print("No file was selected, picking file...");
      await _pickFile();
    }
    String stored = await _diskRead("kerb_user");
    if (stored != null) {
      widget.kerb_user = stored;
    }
    stored = await _diskRead("kerb_pass");
    if (stored != null) {
      widget.kerb_pass = stored;
    }
    stored = await _diskRead("remember_pass");
    if (stored != null) {
      widget.remember_pass = (stored == "true");
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
        await _diskWrite(
            "remember_pass", widget.remember_pass ? "true" : "false");
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
          result = await client.disconnectSFTP();

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
    setState(() {
      widget.filePath = result;
    });
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
        body: Center(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("MIT Print"),
            Column(children: [
              Text(widget.filePath),
              RaisedButton(onPressed: _pickFile, child: Text("Pick File")),
              Stack(children: [
                Positioned.fill(child: Align(alignment: Alignment.bottomCenter,
                child:
                Container(
                    width: MediaQuery.of(context).size.width,
                    height: 100,
                    decoration: new BoxDecoration(
                      color: Colors.blue,
                    ),
                ))),
                Center(
                    child: Padding(
                        padding: EdgeInsets.only(bottom: 20.0),
                        child: RaisedButton(
                            onPressed: _printFile,
                            color: Colors.white,
                            padding: const EdgeInsets.all(30.0),
                            shape: CircleBorder(),
                            child: Icon(Icons.print,
                                color: Colors.blue,
                                size: 90)) //Your widget here,
                        ))
              ]),
            ])
          ]),
    ));
  }
}
