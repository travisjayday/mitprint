import 'package:flutter/material.dart';

class TerminalShell extends StatefulWidget {
  final List<String> textLines;
  const TerminalShell({Key key, this.textLines}) : super(key: key);

  @override
  _TerminalShellState createState() => _TerminalShellState();
}

class _TerminalShellState extends State<TerminalShell> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.fromLTRB(30, 0, 30, 00),
        child: SelectableText(widget.textLines != null && widget.textLines.length > 0?
        widget.textLines?.reduce((value, element) => value + "\n" + element) ?? "" : "",
            style: TextStyle(color: Colors.green, fontFamily: "Monospace")));
  }
}
