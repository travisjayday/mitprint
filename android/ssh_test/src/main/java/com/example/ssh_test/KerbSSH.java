package com.example.ssh_test;
import com.jcraft.jsch.ChannelExec;
import com.jcraft.jsch.ChannelSftp;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.UIKeyboardInteractive;
import com.jcraft.jsch.UserInfo;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;


public class KerbSSH {

    private static final String CHANNEL = "flutter.native/helper";
    public static void main(String args[]) {
        String user="tjz";
        String password="2001US@tz";
        String filePath = "/tmp/this.txt";
        printFile(filePath, user, password);
    }

    private static void log(String str) {
        System.out.println(str);
    }

    public static String printFile(String filePath, String user, String password)
    {
        log("Preparing to connect to athena.dialup.mit.edu...");
        String host="athena.dialup.mit.edu";
        try {
            // create ssh session
            JSch.setLogger(new MyLogger());
            JSch jsch = new JSch();

            Session session = jsch.getSession(user, host, 22);


            // disable the "press yes to authenticate with unkown host" dialog
            java.util.Properties config = new java.util.Properties();
            //config.put("StrictHostKeyChecking", "no");
            config.put("PreferredAuthentications", "gssapi-with-mic,keyboard-interactive,password");
            //session.setPassword(password);
            session.setConfig(config);

            // set user to handle the duo authentication
            UserInfo ui = new MyUserInfo(password);
            session.setUserInfo(ui);

            // Connect!
            log("Connecting...");
            session.connect();
            log("Connection successful!");

            // Connect to SFTP Channel to upload file to print
            ChannelSftp channelSftp = (ChannelSftp) session.openChannel("sftp");;
            channelSftp.connect();

            channelSftp.cd("./Documents");
            File f1 = new File(filePath);
            channelSftp.put(new FileInputStream(f1), f1.getName());

            channelSftp.disconnect();

            // Connect to Exec channel to execute a shell command to print to Pharos printer
            ChannelExec channelExec = (ChannelExec) session.openChannel("exec");
            InputStream in = channelExec.getInputStream();
            channelExec.setCommand("ls Documents");
            channelExec.connect();

            // Optionally read output and return it
            BufferedReader reader = new BufferedReader(new InputStreamReader(in));
            String line;
            int index = 0;

            StringBuilder builder = new StringBuilder();
            while ((line = reader.readLine()) != null)
            {
                builder.append(++index);
                builder.append(" : ");
                builder.append(line);
            }

            // disconnect and return response
            channelExec.disconnect();
            session.disconnect();

            log("Done. Print job submitted.");
            return builder.toString();
        }
        catch (Exception e) {
            log("Exception in ssh job: " + e.getMessage());
        }
        return "Failed...";
    }

    // Class to hold user information to handle the Duo authentication prompt
    public static class MyUserInfo implements UserInfo, UIKeyboardInteractive {
        String passwd;
        MyUserInfo(String p) {
            passwd = p;
        }
        public String getPassword(){ return passwd; }
        public boolean promptYesNo(String str){
            log("answer yes");  return true;
        }
        public String getPassphrase(){ return passwd; }
        public boolean promptPassphrase(String message){ log("prompted pass"); return false; }
        public boolean promptPassword(String message){
           System.out.println("Prompting password: " + message);
           return false;
        }
        public void showMessage(String message) {
            System.out.println(message);
        }
        // This handles the prompt. Returns "1" to select Duo Push Notificaiton
        public String[] promptKeyboardInteractive(String destination,
                                                  String name,
                                                  String instruction,
                                                  String[] prompt,
                                                  boolean[] echo){
            log("Received message: " + instruction);
            String[] response=new String[prompt.length];
            response[0] = "1";
            return response;
        }
    }

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
            System.err.print(name.get(new Integer(level)));
            System.err.println(message);
        }
    }
}
