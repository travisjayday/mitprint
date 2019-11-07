import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrintDialog extends StatefulWidget {
  final String fileName;

  PrintDialog({this.fileName});

  @override
  _PrintDialogState createState() => _PrintDialogState();
}

class _PrintDialogState extends State<PrintDialog> {
  int copies = 1;
  TextEditingController printNameCotrol = new TextEditingController();
  TextEditingController copiesControl = new TextEditingController();

  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Print Job Configuration'),
      contentPadding: EdgeInsets.fromLTRB(25, 15, 25, 0.0),
      content: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Wrap(
            runSpacing: 10,
            children: [
              Row(
                children: [
                  Expanded(
                      flex: 40,
                      child: Text(
                        "Job Name: ",
                        style: TextStyle(color: Colors.grey[700]),
                      )),
                  Expanded(
                      flex: 60,
                      child: TextField(
                          controller: printNameCotrol,
                          decoration: InputDecoration(
                              hintText: widget.fileName.split("/").last)))
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 40,
                      child: Text(
                        "# Copies: ",
                        style: TextStyle(color: Colors.grey[700]),
                      )),
                  Expanded(
                      flex: 60,
                      child: Row(children: [
                        Expanded(
                            flex: 40,
                            child: TextField(
                                controller: copiesControl,
                                keyboardType: TextInputType.number,
                                onChanged: (text) {
                                  setState(() {});
                                  var c = int.tryParse(text);
                                  if (c != null && c > 0) copies = c;
                                  if (text.contains(new RegExp("[^0-9]"))) {
                                    String txt = text.replaceAll(
                                        new RegExp("[^0-9]"), "");
                                    copiesControl.value = copiesControl.value
                                        .copyWith(
                                            text: txt,
                                            selection: TextSelection(
                                                baseOffset: txt.length,
                                                extentOffset: txt.length));
                                  }
                                },
                                decoration: InputDecoration(hintText: "1"))),
                        Expanded(
                            flex: 60,
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                      padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                      child: SizedBox(
                                          width: 36,
                                          height: 36,
                                          child: RaisedButton(
                                            padding: EdgeInsets.all(0),
                                            color: Colors.grey[400],
                                            child: Icon(Icons.remove,
                                                color: Colors.white),
                                            onPressed: () => setState(() =>
                                                copiesControl.text = (copies > 1
                                                        ? --copies
                                                        : copies)
                                                    .toString()),
                                          ))),
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: RaisedButton(
                                      padding: EdgeInsets.all(0),
                                      color: Colors.grey[400],
                                      child:
                                          Icon(Icons.add, color: Colors.white),
                                      onPressed: () => setState(() =>
                                          copiesControl.text =
                                              (++copies).toString()),
                                    ),
                                  )
                                ]))
                      ])),
                ],
              )
            ],
          )),
      actions: <Widget>[
        new FlatButton(
          child: new Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        new FlatButton(
          child: new Text('CONTINUE'),
          onPressed: () async {
            Navigator.of(context).pop({
              "title": printNameCotrol.text.length > 0
                  ? printNameCotrol.text.toString()
                  : widget.fileName.split("/").last,
              "copies": copies.toString()
            });
          },
        )
      ],
    );
  }
}
