import 'dart:convert';

import 'package:ssh/ssh.dart';

import '../password.dart';

class AthenaSSH {
  Future<Null> submitPrintjob(
      String kerb_user,
      String kerb_pass,
      String auth_method,
      String filePath,
      String printer,
      String copies,
      String title,
      Function(String, double, double) _updateProgress,
      Function _log,
      Function onSuccessPrint) async {
    double stepNum = 0.0;
    double totalSteps = 17.0;

    bool clientConnected = false;
    var client = new SSHClient(
        host: "mitprint.xvm.mit.edu",
        port: 22,
        username: SSH_USER,
        passwordOrKey: SSH_PASS);

    try {
      // STEP 1 -- Create SSH Session -----------
      _updateProgress("Connecting with SSH", stepNum++, totalSteps);
      _log("Attempting to create SSH session with ${client.host}...", "app");
      String result = await client.connect();
      _log(result, "result");
      // END STEP 1 -----------------------------

      if (result == "session_connected") {
        clientConnected = true;
        var dir = "$kerb_user\_printFiles";

        // STEP 2 -- Remove Old Directories -----
        _updateProgress("Removing old files...", stepNum++, totalSteps);
        _log("Removing pre-existing directory...", "app");
        result = await client.execute("rm -rf " + dir);
        _log(result, "result");
        // END STEP 2 ---------------------------

        // STEP 3 -- Create SFTP Session --------
        _updateProgress("Connecting to SFTP", stepNum++, totalSteps);
        _log("Attempting to connect to SFTP...", "app");
        result = await client.connectSFTP();
        _log(result, "result");
        // END STEP 3 ---------------------------

        if (result == "sftp_connected") {
          // STEP 4 -- Upload PrintJob File -----
          _updateProgress("Uploading user files...", stepNum, totalSteps);
          _log("Creating temporary directory...", "app");
          result = await client.sftpMkdir(dir);
          _log(result, "result");
          _log("Uploading print files to " + dir, "app");
          double step = stepNum;
          result = await client.sftpUpload(
            path: filePath,
            toPath: dir,
            callback: (progress) {
              _log(progress.toString(), "server");
              stepNum = step + (progress / 100.0) * 2; // takes 2 steps
              _updateProgress(
                  "Uploading user files ($progress%)...", stepNum, totalSteps);
            },
          );
          _log(result, "result");
          _updateProgress("Disconnecting from SFTP...", stepNum++, totalSteps);
          _log("Disconnecting from SFTP...", "app");
          client.disconnectSFTP();
          // END STEP 4 -------------------------

          // STEP 5 -- Connecting to Athena -----
          _updateProgress("Connecting to Athena...", stepNum++, totalSteps);
          _log("Re-connecting to client...", "app");
          result = await client.connect();
          _log(result, "result");

          bool printSucc = false;
          result = await client.startShell(
              ptyType: "xterm",
              callback: (dynamic res) {
                _log(res, "server"); // read from shell
                if (res.toString().contains("request id is")) {
                  printSucc = true;
                  _log("Found success message! Printjob submitted!", "app");
                }
                print("res is: " + res.toString());
                if (res
                    .toString()
                    .contains("Permission denied, please try again")) {
                  _updateProgress(
                      "Invalid Athena Credentials!", totalSteps, totalSteps);
                  _log("Invalid athena credentials!");
                }
                if (res.toString().contains("Connection refused")) {
                  _updateProgress("Connection refused! Check credentials.",
                      totalSteps, totalSteps);
                  _log("Invalid athena credentials!");
                }
                // find json updates from logging to console
                RegExp regExp = new RegExp(r"\{.*\}");
                if (regExp.hasMatch(res)) {
                  String response = regExp.allMatches(res).first.group(0);
                  var status = json.decode(response);
                  _updateProgress(status["desc"], stepNum++, totalSteps);

                  if (status["step"] == 4) {

                  }
                    // check if status step is 6, the last step in printjob script
                  if (status["step"] == "6") {
                    if (printSucc) {
                      _updateProgress("Printjob Succesfully Submitted!",
                          totalSteps, totalSteps);
                      onSuccessPrint();
                      _log("Script terminates successfully...", "app");
                    } else {
                      _updateProgress(
                          "Something Went Wrong", totalSteps, totalSteps);
                      _log("Script terminates unsuccessfully...", "app");
                    }
                    _log("Disconnecting from SSH server", "app");
                    clientConnected = false;
                    client.disconnect();
                  }
                }
              });
          // END Step 5 -------------------------

          // STEP 6 -- Execute ./printJob Command on mitprint.xvm.mit.edu
          _updateProgress("Starting printjob...", stepNum++, totalSteps);

          // Note: the script has 6 sub-steps
          String cmd = "expect /home/$SSH_USER/printJob.sh " +
              "$kerb_user " +
              "$kerb_pass " +
              "$auth_method " +
              "$dir " +
              "$printer " +
              "$copies " +
              "$title";
          _log("Running printJob command on server...", "app");
          result = await client.writeToShell(cmd + "\n");
          _log(result, "result");
          // END STEP 6

          new Future.delayed(
            const Duration(seconds: 60),
            () async {
              _log("Timeout Disconnecting from SSH session...", "app");
              if (!printSucc) {
                _updateProgress("Session Timed Out!", totalSteps, totalSteps);
              }
              if (clientConnected)
                client.disconnect();
            },
          );
        }
      } else {
        _log("No SSH session is connected... Terminating...", "warning");
      }
    } on Exception catch (e) {
      _log('Fatal: ${e.toString()}\n[Error] Message: ${e.toString()}', "error");
      _updateProgress("Something went wrong...", totalSteps, totalSteps);
    }
  }
}
