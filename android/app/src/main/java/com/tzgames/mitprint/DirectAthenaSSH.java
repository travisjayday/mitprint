package com.tzgames.mitprint;

import android.os.AsyncTask;
import android.util.Log;

import com.jcraft.jsch.Channel;
import com.jcraft.jsch.ChannelExec;
import com.jcraft.jsch.ChannelSftp;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.SftpException;
import com.jcraft.jsch.SftpProgressMonitor;
import com.jcraft.jsch.UIKeyboardInteractive;
import com.jcraft.jsch.UserInfo;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Properties;

import io.flutter.plugin.common.MethodChannel;

public class DirectAthenaSSH extends AsyncTask<String, String, String> {
    private MethodChannel gui;
    private Session session;
    private boolean cancelled;
    private boolean success = false;
    private static String TAG = "JSCH";

    DirectAthenaSSH(MethodChannel gui) {
        this.gui = gui;
    }

    void userCancel() {
        Log.d(TAG, "Cancelling SSH job...");
        cancelled = true;
        if (session != null) {
            session.disconnect();
        }
    }

    @Override
    protected String doInBackground(String... params) {
        String user = params[0];
        String pass = params[1];
        String auth = params[2];
        String filePath = params[3];
        String printer = params[4];
        String copies = params[5];
        String title = params[6];

        AthenaUser athenaUser = new AthenaUser(pass, auth);

        Properties config = new Properties();
        config.put("StrictHostKeyChecking", "no");
        config.put("PreferredAuthentications", "keyboard-interactive,password");

        try {
            JSch.setLogger(new MyLogger());

            /* STEP 1+2 */
            // Dummy Step to wait for animation. Then connect to SSH server and authenticate with DUO
            publishProgress("step:1| Preparing SSH...");
            Thread.sleep(850);                      // pause to wait for animation to finish
            publishProgress("step:2| Connecting to Athena Dialup (DUO)...",
                    "log: Connecting to " + user + "@athena.dialup.mit.edu...");
            int tries = 2;
            Exception latestException = null;
            while (tries > 0) {
                publishProgress("log:Connection attempts remaining: " + tries);
                tries--;
                if (cancelled) return "";
                try {
                    JSch jsch = new JSch();
                    session = jsch.getSession(user, "athena.dialup.mit.edu", 22);
                    session.setPassword(pass);
                    session.setUserInfo(athenaUser);
                    session.setConfig(config);
                    session.setTimeout(40000);
                    session.connect();
                } catch (JSchException t) {
                    latestException = t;
                    handleException(t, true);
                }
                if (session.isConnected())
                    break;
            }
            if (!session.isConnected() && latestException != null) {
                throw new Exception("Final failure cause: " + latestException.toString());
            }

            /* STEP 3 */
            // Create SFTP Channel
            publishProgress("step:3| Connecting to SFTP...",
                    "log: Established session with athena.dialup.mit.edu!",
                    "log: Creating SFTP channel...");

            Channel channel=session.openChannel("sftp");
            channel.connect();

            /* STEP 4 */
            // Upload user file through SFTP to specific directory
            publishProgress("step:4| Preparing for upload...",
                    "log: Created SFTP channel successfully...",
                    "log: Creating ~/PrintJobs folder and preparing to upload user file: " + filePath);

            ChannelSftp sftp = (ChannelSftp) channel;
            try {
                sftp.cd("PrintJobs");
            }
            catch (SftpException e) {
                sftp.mkdir("PrintJobs");
                sftp.cd("PrintJobs");
            }
            File file = new File(filePath);

            // sanitize filename
            String extension = "";
            int idx = file.getName().lastIndexOf('.');
            if (idx > 0) extension = file.getName().substring(idx + 1);
            String remoteFileName = "job." + extension;
            Log.d(TAG, "JDSKJFSLDJFKLSFJ :: :FILLE ISS : " + remoteFileName);

            sftp.put(new FileInputStream(file), remoteFileName, new SFTPMonitor());
            sftp.disconnect();
            channel.disconnect();

            /* STEP 5 */
            // Run lp command which submits the printjob
            publishProgress("step:5| Starting Print Job...",
                    "log: Uploaded user files successfully...",
                    "log: Trying to start the print job over SSH execute channel...");

            channel=session.openChannel("exec");
            String cmd = "lp" +
                    " -d " + printer +
                    " -n " + copies +
                    " -t \"" + title + "\"" +
                    " -- ~/PrintJobs/" + remoteFileName +
                    " ; rm -rf ~/PrintJobs";
            publishProgress("log: Running: " + cmd);
            ((ChannelExec)channel).setCommand(cmd);
            channel.setInputStream(null);

            OutputStream out = new OutputStream() {
                String buf = "";
                @Override
                public void write(int b) {
                    if (b != 10)
                        buf += (char) b;
                    else {
                        publishProgress("log: [Server] Error: occurred: " + buf);
                        success = false;
                        buf = "";
                    }
                }
            };
            ((ChannelExec)channel).setErrStream(out);

            InputStream in = channel.getInputStream();
            channel.connect();
            byte[] tmp = new byte[1024];
            while (true) {
                while(in.available() > 0){
                    int i = in.read(tmp, 0, 1024);
                    if (i < 0) break;
                    String response = new String(tmp, 0, i);
                    if (response.contains("request id is")) success = true;
                    publishProgress("log: [Server] " + response);
                }
                if(channel.isClosed()){
                    publishProgress("log: [Server] exit-status: " + channel.getExitStatus());
                    break;
                }
                try { Thread.sleep(1000); } catch(Exception ee){ Log.e(TAG, ee.toString()); }
            }
            channel.disconnect();
            session.disconnect();

            /* Step 6 */
            // Update GUI to reflect successful print job
            if (success)
                publishProgress("step:6| Job Submitted Successfully!",
                    "log: Print job '" + title + "' submitted succesfully for user "
                            + user + " on printer " + printer + "...");
            else
                publishProgress("step:6| Something went wrong",
                        "log: Print job '" + title + "' NOT submitted for user "
                                + user + " on printer " + printer + "...");
        } catch (Exception e) {
            handleException(e, false);
        }

        return "";
    }

    //
    // if silent is set, do not publish progress, handle exception silently
    private void handleException(Exception e, boolean silent) {
        if (e.toString().toLowerCase().contains("authentication failure")) {
            if (!silent) publishProgress("step:-1| Incorrect Kerberos Credentials!");
            publishProgress("log: Error: " + e.toString());
        }
        else if (e.toString().contains("Connection refused")) {
            if (!silent) publishProgress("step:-1|Connection Refused");
            publishProgress("log: This could happen because you've used too many log-in attempts without" +
                            " successfully authenticating with DUO.");
        }
        else if (e.toString().toLowerCase().contains("time")) {
            if (!silent) publishProgress("step:-1|Connection Timed Out");
            publishProgress("log: Error: " + e.toString());
        }
        else if (e.toString().toLowerCase().contains("auth cancel")) {
            if (!silent) publishProgress("step:-1|Authentication Cancelled");
            publishProgress("log: Error: " + e.toString());
        }
        else {
            if (!silent) publishProgress("step:-1| Something went wrong");
            publishProgress("log: Error: " + e.toString());
        }
    }

    @Override
    protected void onPostExecute(String result) {
        gui.invokeMethod("printSuccess", success? "success" : "failure");
    }

    @Override
    protected void onPreExecute() {}

    @Override
    protected void onProgressUpdate(String... text) {
        for (String s : text) {
            if (s.contains("log:")) {
                gui.invokeMethod("logString", s.split("log:")[1]);
            }
            else if (s.contains("step:")) {
                gui.invokeMethod("setStep", s.split("step:")[1]);
            }
        }
    }

    // TODO: remove all this default logging and add a DEBUG feature in settings menu
    public static class MyLogger implements com.jcraft.jsch.Logger {
        static java.util.Hashtable<Integer, String> name = new java.util.Hashtable<>();
        static{
            name.put(DEBUG, "DEBUG: ");
            name.put(INFO, "INFO: ");
            name.put(WARN, "WARN: ");
            name.put(ERROR, "ERROR: ");
            name.put(FATAL, "FATAL: ");
        }
        public boolean isEnabled(int level){
            return true;
        }
        public void log(int level, String message){
            Log.d(TAG, name.get(level) + message);
        }
    }

    public static class AthenaUser implements UserInfo, UIKeyboardInteractive {
        private String password;
        private String authMethod;

        AthenaUser(String pass, String auth) {
            password = pass;
            authMethod = auth;
        }

        public boolean promptYesNo(String str){ return true; }
        public boolean promptPassphrase(String message){ return true; }
        public boolean promptPassword(String message){ return true; }
        public String getPassword(){ return password; }
        public String getPassphrase(){return password; }
        public void showMessage(String message){}

        // Response to DUO prompt at SSH terminal. User chooses (1-3).
        public String[] promptKeyboardInteractive(String destination, String name,
                                                  String instruction, String[] prompt,
                                                  boolean[] echo) {
            Log.d(TAG, "name: " + name);
            Log.d(TAG, "instruction: " + instruction);
            for (String p : prompt) {
                Log.d(TAG, "prompt: " + p);
                // if user denies DUO request, return null, e.g. break connection attempt
                if (p.contains("denied")) {
                    return null;
                }
            }
            return new String[]{authMethod};
        }
    }

    public class SFTPMonitor implements SftpProgressMonitor {
        private long max                = 0;
        private long count              = 0;
        private long percent            = 0;

        public void init(int op, java.lang.String src, java.lang.String dest, long max) {
            this.max = max;
        }

        public boolean count(long bytes){
            this.count += bytes;
            long percentNow = this.count*100/max;
            if(percentNow>this.percent){
                this.percent = percentNow;
                publishProgress("step:4| Upload Progress: " + this.percent + "%",
                        "log: Upload Progress: " + this.percent + "%");
            }
            return(true);
        }

        public void end() {}
    }
}
