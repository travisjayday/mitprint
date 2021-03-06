import 'package:flutter/services.dart';

class AthenaSSH {
  MethodChannel platform;
  void Function(String) logString;
  void Function(String, double) setStep;
  void Function() printSuccess;
  int totalSteps = 6;
  int currentStep = 0;

  AthenaSSH(MethodChannel platform) {
    this.platform = platform;
  }
  Future<Null> submitPrintjob(var params,
      {void Function(String) logString,
      void Function(String, double) setStep, Function() printSuccess}) async {
    this.logString = logString;
    this.setStep = setStep;
    this.printSuccess = printSuccess;
    platform.setMethodCallHandler(_nativeCallbackHandler);
    platform.invokeMethod('submitPrintjob', params);
  }

  Future<dynamic> _nativeCallbackHandler(MethodCall call) async {
    print("Received native callback in flutter");
    print(call.arguments);
    switch (call.method) {
      case "logString":
        logString(call.arguments);
        break;
      case "setStep":
        int code = int.parse(call.arguments.split("|")[0]);
        if (code == -1)
          currentStep = totalSteps;
        else
          currentStep = code;
        setStep(call.arguments.split("|")[1],
            currentStep++ / totalSteps.toDouble());
        break;
      case "printSuccess":
        if (call.arguments == "success")
          printSuccess();
    }
  }
}
