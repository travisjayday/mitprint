package com.tzgames.mitprint;

import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "flutter.native/helper";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);
        MethodChannel channel = new MethodChannel(getFlutterView(), CHANNEL);
        channel.setMethodCallHandler(
            new MethodChannel.MethodCallHandler() {
                @Override
                public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                    Log.d(CHANNEL, "Recevied native call.");
                    if (call.method.equals("submitPrintjob")) {
                        String user = call.argument("user");
                        String pass = call.argument("pass");
                        String auth = call.argument("auth");
                        String filePath = call.argument("filePath");
                        String printer = call.argument("printer");
                        String copies = call.argument("copies");
                        String title = call.argument("title");

                        String params[] = {user, pass, auth, filePath, printer, copies, title};
                        DirectAthenaSSH asyncTask = new DirectAthenaSSH(channel);
                        asyncTask.execute(params);
                        result.success("called method");
                    }
                }});
    }
}
