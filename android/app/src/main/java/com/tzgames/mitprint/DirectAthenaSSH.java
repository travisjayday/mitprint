package com.tzgames.mitprint;

import android.os.AsyncTask;
import android.util.Log;

import com.jcraft.jsch.Buffer;
import com.jcraft.jsch.Channel;
import com.jcraft.jsch.ChannelExec;
import com.jcraft.jsch.ChannelSftp;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Packet;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.SftpException;
import com.jcraft.jsch.SftpProgressMonitor;
import com.jcraft.jsch.UIKeyboardInteractive;
import com.jcraft.jsch.UserInfo;

import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import java.net.SocketTimeoutException;
import java.util.Properties;
import java.util.stream.Stream;

import io.flutter.plugin.common.MethodChannel;

public class DirectAthenaSSH extends AsyncTask<String, String, String> {
    private MethodChannel gui;
    private Session session;
    private AthenaUser athenaUser;
    private boolean cancelled;

    DirectAthenaSSH(MethodChannel gui) {
        this.gui = gui;
    }

    public void userCancel() {
        Log.d("JSH", "Cancelling SSH job...");
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

        athenaUser = new AthenaUser(user, pass, auth);

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
                } catch (JSchException t) { }
                if (session.isConnected())
                    break;
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
            sftp.put(new FileInputStream(file), file.getName(), new SFTPMonitor());
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
                    " -t " + title +
                    " -- ~/PrintJobs/" + file.getName() +
                    " ; rm -rf ~/PrintJobs";
            ((ChannelExec)channel).setCommand(cmd);
            channel.setInputStream(null);

            OutputStream out = new OutputStream() {
                String buf = "";
                @Override
                public void write(int b) throws IOException {
                    if (b != 10)
                        buf += (char) b;
                    else {
                        publishProgress("log: [Server] Error: occurred: " + buf);
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
                    publishProgress("log: [Server] " + new String(tmp, 0, i));
                }
                if(channel.isClosed()){
                    publishProgress("log: [Server] exit-status: " + channel.getExitStatus());
                    break;
                }
                try{Thread.sleep(1000);}catch(Exception ee){}
            }
            channel.disconnect();
            session.disconnect();

            /* Step 6 */
            // Update GUI to reflect successful print job
            publishProgress("step:6| Job Submitted Successfully!",
                    "log: Print job '" + title + "' submitted succesfully for user "
                            + user + " on printer " + printer + "...");
        } catch (Exception e) {
            handleException(e);
        }

        return "";
    }

    private void handleException(Exception e) {
        if (e.toString().contains("authentication failures")) {
            publishProgress("step:-1| Incorrect Kerberos Credentials!", "log: Error: " + e.toString());
        }
        else if (e.toString().contains("Connection refused")) {
            publishProgress("step:-1|Connection Refused",
                    "log: This could happen because you've used too many log-in attempts without" +
                            "successfully authenticating with DUO.");
        }
        else if (e.toString().toLowerCase().contains("time")) {
            publishProgress("step:-1|Connection Timed Out", "log: Error: " + e.toString());
        }
        else {
            publishProgress("step:-1| Something went wrong", "log: Error: " + e.toString());
        }
    }

    @Override
    protected void onPostExecute(String result) {
        gui.invokeMethod("printSuccess", "");
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
        static java.util.Hashtable name=new java.util.Hashtable();
        static{
            name.put(new Integer(DEBUG), "DEBUG: ");
            name.put(new Integer(INFO), "INFO: ");
            name.put(new Integer(WARN), "WARN: ");
            name.put(new Integer(ERROR), "ERROR: ");
            name.put(new Integer(FATAL), "FATAL: ");
        }
        public boolean isEnabled(int level){
            return true;
        }
        public void log(int level, String message){
            Log.d("JSCH", name.get(level).toString() + message);
        }
    }

    public static class AthenaUser implements UserInfo, UIKeyboardInteractive {
        private String password;
        private String username;
        private String authMethod;

        AthenaUser(String usr, String pass, String auth) {
            username = usr;
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
            System.out.println("name: " + name);
            System.out.println("instruction: " + instruction);
            for (int i = 0; i < prompt.length; i++) {
                System.out.println("prompt: " + prompt[i]);
            }
            System.out.println("Responding with auth method: " + authMethod);
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
