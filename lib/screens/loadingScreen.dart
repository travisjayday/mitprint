import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mitprint/widgets/terminalShell.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class LoadingScreen extends StatefulWidget {
  final TerminalShell terminalShell;
  final String currentStep;
  final double percentProgress;
  final Function doneCallback;

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
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        child: Container(
            color: Theme.of(context).backgroundColor,
            width: MediaQuery.of(context).size.width,
            height: widget.currentStep == ""
                ? 0
                : MediaQuery.of(context).size.height,
            child: Stack(children: [
              Center(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    GestureDetector(
                        onTap: () {

                            widget.doneCallback();

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
                            style: TextStyle(
                                decoration: TextDecoration.underline))),
                    AnimatedSize(
                        vsync: this,
                        duration: Duration(seconds: 1),
                        reverseDuration: Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: showingTerm
                                ? MediaQuery.of(context).size.height * 0.4
                                : 0,
                            color: Colors.black,
                            child: widget.terminalShell)),
                  ])),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 800),
                    opacity:
                        widget.currentStep.toLowerCase().contains("success")
                            ? 1.0
                            : 0.0,
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(40.0, 0.0, 40.0,
                            MediaQuery.of(context).size.height * 0.08),
                        child: Text(
                          "It may take up to a minute for the print job to appear in Pharos terminals.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ))),
              ),
              Container(
                  child: widget.currentStep.toLowerCase().contains("duo")
                      ? Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          color: Color.fromARGB(90, 0, 0, 0),
                          child: AlertDialog(
                              title: Text("Touchstone@MIT"),
                              content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: RichText(
                                          textAlign: TextAlign.left,
                                          text: TextSpan(
                                            style: Theme.of(context)
                                                .textTheme
                                                .body1,
                                            children: <TextSpan>[
                                              TextSpan(
                                                  text: 'Duo ',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: Colors.green)),
                                              TextSpan(
                                                text:
                                                    "Authentication is required.\nWaiting for response...",
                                              ),
                                            ],
                                          ),
                                        )),
                                    Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(0, 25.0, 10, 0),
                                        child: SpinKitWave(color: Colors.green))
                                  ])))
                      : Container()),
            ])));
  }
}
