import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KerbDialog extends StatefulWidget {
  String kerbUser;
  String kerbPass;
  bool rememberPass;

  final TextEditingController kerbUserTextController = new TextEditingController();
  final TextEditingController kerbPassTextController = new TextEditingController();

  KerbDialog({
    this.kerbUser,
    this.kerbPass,
    this.rememberPass,
  });

  @override
  _KerbDialogState createState() => _KerbDialogState();
}

class _KerbDialogState extends State<KerbDialog> {
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Kerberos Credentials'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: widget.kerbUserTextController..text = widget.kerbUser,
          decoration: InputDecoration(hintText: "Kerb username"),
        ),
        TextField(
          controller: widget.kerbPassTextController,
          decoration: InputDecoration(hintText: "Kerb password"),
          obscureText: true,
        ),
        CheckboxListTile(
          onChanged: (bool value) {
            setState(() {
              widget.rememberPass = value;
            });
          },
          title: Text("Save password"),
          value: widget.rememberPass,
        )
      ]),
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
            Navigator.of(context)
                .pop([widget.kerbUserTextController.text.toString(), widget.kerbPassTextController.text.toString(), widget.rememberPass]);
          },
        )
      ],
    );
  }
}
