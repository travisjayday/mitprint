package com.tzgames.mit_print;

import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;


import com.tzgames.mit_print.PharosPrint;

public class MainActivity extends FlutterActivity implements PharosPrint.AsyncResponse {
    private static final String CHANNEL = "flutter.native/helper";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);
        new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
            new MethodChannel.MethodCallHandler() {
                @Override
                public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                    Log.d(CHANNEL, "Recevied native call.");
                    if (call.method.equals("printFile")) {
                        String filePath = call.argument("filePath");
                        String password = call.argument("password");
                        String user = call.argument("user");
                        String params[] = {filePath, user, password};
                        AsyncTask asyncTask = new PharosPrint().execute(params);
                        result.success("called method");
                    }
                }});
    }

    @Override
    public void processFinish(String output){
        //Here you will receive the result fired from async class
        //of onPostExecute(result) method.
    }
}
