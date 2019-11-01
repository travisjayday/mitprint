import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrintDialog extends StatefulWidget {
  String fileName;

  PrintDialog({this.fileName});

  @override
  _PrintDialogState createState() => _PrintDialogState();
}

class _PrintDialogState extends State<PrintDialog> {
  int copies = 1;
  TextEditingController printName = new TextEditingController();

  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Printjob Settings'),
      contentPadding: EdgeInsets.fromLTRB(25, 15, 25, 0.0),
      content: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(mainAxisSize: MainAxisSize.max, children: [
            Row(children: [
              Text("Printjob: ", style: TextStyle(color: Colors.grey[600]),),
              Flexible(child: TextFormField(
                  controller: printName,
                  decoration: InputDecoration(
                      hintText: "Printjob Name (" +
                          widget.fileName.split("/").last +
                          ")")))
            ]),
            Padding(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text("Copies: " + copies.toString()),
                    Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                        child: SizedBox(
                            width: 36,
                            height: 36,
                            child: RaisedButton(
                              color: Colors.blue,
                              padding: EdgeInsets.all(0),
                              child: Icon(Icons.remove, color: Colors.white),
                              onPressed: () => setState(() => copies--),
                            ))),
                    SizedBox(
                        width: 36,
                        height: 36,
                        child: RaisedButton(
                          color: Colors.blue,
                          padding: EdgeInsets.all(0),
                          child: Icon(Icons.add, color: Colors.white),
                          onPressed: () => setState(() => copies++),
                        )),
                  ],
                ))
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
            Navigator.of(context).pop([printName.text.toString(), copies]);
          },
        )
      ],
    );
  }
}
