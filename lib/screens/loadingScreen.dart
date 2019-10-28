import 'package:flutter/material.dart';
import 'package:mit_print/widgets/terminalShell.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class LoadingScreen extends StatefulWidget {
  TerminalShell terminalShell;
  String currentStep;
  double percentProgress;
  Function doneCallback;

  LoadingScreen(
      {Key key,
      this.terminalShell,
      this.currentStep,
      this.percentProgress = 0.0,
      this.doneCallback})
      : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  bool showingTerm = false;
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
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.currentStep = "";
                          widget.doneCallback();
                        });
                      },
                      child: CircularPercentIndicator(
                        radius: 120,
                        lineWidth: 15.0,
                        percent: widget.percentProgress,
                        progressColor: Theme.of(context).primaryColor,
                        circularStrokeCap: CircularStrokeCap.round,
                        center: widget.percentProgress == 1.00
                            ? new Icon(
                                Icons.arrow_back,
                                size: 70.0,
                                color: Colors.blue,
                              )
                            : Container(),
                        footer: new Text(
                          widget.currentStep,
                          style: new TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17.0),
                        ),
                      )),
                  FlatButton(
                      onPressed: () {
                        setState(() {
                          showingTerm = !showingTerm;
                          print("showingTerm: $showingTerm");
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
                          height: showingTerm
                              ? MediaQuery.of(context).size.height * 0.4
                              : 0,
                          color: Colors.black,
                          child: widget.terminalShell))
                ]))));
  }
}
