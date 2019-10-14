import 'package:flutter/material.dart';
import 'package:mit_print/terminalShell.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class LoadingScreen extends StatefulWidget {
  final TerminalShell terminalShell;
  final String currentStep;
  final double percentProgress;
  bool showingTerm = false;
  LoadingScreen(
      {Key key,
      this.terminalShell,
      this.currentStep,
      this.percentProgress = 0.0})
      : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
        vsync: this,
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
        child: Container(
            color: Theme.of(context).backgroundColor,
            width: MediaQuery.of(context).size.width,
            height: widget.currentStep == ""
                ? 0
                : MediaQuery.of(context).size.height,
            child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                CircularPercentIndicator(
                  radius: 120,
                  lineWidth: 15.0,
                  percent: widget.percentProgress,
                  progressColor: Theme.of(context).primaryColor,
                  circularStrokeCap: CircularStrokeCap.round,
                  footer: new Text(
                    widget.currentStep,
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17.0),
                  ),
                ),
                FlatButton(
                    onPressed: () {
                      setState(() {
                        widget.showingTerm = !widget.showingTerm;
                        print("showingTerm: ${widget.showingTerm}");
                      });
                    },
                    child: Text("Details",
                        style:
                            TextStyle(decoration: TextDecoration.underline))),

                  AnimatedSize(
                  vsync: this,
                  duration: Duration(seconds: 1),
                  reverseDuration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: widget.showingTerm
                          ? MediaQuery.of(context).size.height * 0.4
                          : 0,
                      color: Colors.black,
                      child: widget.terminalShell))
            ]))));
  }
}
