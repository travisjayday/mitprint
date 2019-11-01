import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KerbDialog extends StatefulWidget {
  String usr;
  String pass;
  bool remember;

  KerbDialog({
    this.usr,
    this.pass,
    this.remember,
  });

  @override
  _KerbDialogState createState() => _KerbDialogState(usr, pass, remember);
}

class _KerbDialogState extends State<KerbDialog> {
  String kerbUser;
  String kerbPass;
  bool rememberPass;

  TextEditingController kerbUserTextController =
      new TextEditingController();
  TextEditingController kerbPassTextController =
      new TextEditingController();

  _KerbDialogState(usr, pass, remember) {
    kerbUser = usr;
    kerbPass = pass;
    rememberPass = remember;
    kerbUserTextController.text = usr;
  }

  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Kerberos Credentials'),
      contentPadding: EdgeInsets.fromLTRB(25, 15, 25, 0.0),
      content: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(mainAxisSize: MainAxisSize.max, children: [
            TextField(
              controller: kerbUserTextController,
              decoration: InputDecoration(hintText: "Kerb username"),
            ),
            TextField(
              controller: kerbPassTextController,
              decoration: InputDecoration(hintText: "Kerb password"),
              obscureText: true,
            ),
            CheckboxListTile(
              onChanged: (bool value) {
                setState(() {
                  rememberPass = value;
                });
              },
              title: Text("Save password"),
              value: rememberPass,
            )
          ])),
      actions: <Widget>[
        new FlatButton(
          child: new Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop("cancelled");
          },
        ),
        new FlatButton(
          child: new Text('CONTINUE'),
          onPressed: () async {
            Navigator.of(context).pop([
              kerbUserTextController.text.toString(),
              kerbPassTextController.text.toString(),
              rememberPass
            ]);
          },
        )
      ],
    );
  }
}
