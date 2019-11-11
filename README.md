# MIT Print

A mobile printing solution for MIT Pharos printers. 

 ## Features

- Preview and print images and PDF files
- Send print jobs to color or black/white Pharos printers
- Kerberos & DUO two-factor authentication
- Print multiple copies, name print jobs, remember credentials and more!

 ## How it works

- The user supplies his kerberos / athena credentials, configures other settings, and selects a document to print. 
- An SSH session is started with athena.dialup.mit.edu and the user authenticates himself with DUO.
- User files are uploaded via SFTP to his athena locker into a temporary folder.
- `lp` is run over SSH and the document from the temp folder is sent to the user's print queue.

 ## Help
 ### Common Errors
- `Connection Refused` - This either means you're credentials are incorrect or you've tried start print jobs too many times without authenticating yourself successfully with DUO so you've been temporarily locked out of your Kerberos account.
- `Connection Timed Out` - The connection took too long to make (>40s). Are you connected to the Internet?
- `Incorrect Kerberos Credentials` - You've probably mistyped your username or password. Try going into Settings, clearing your credentials, and then print again.
- `Authentication Cancelled` - You probably didn't respond to the DUO prompt correctly
- `Something went wrong` - This means something else went wrong. Click on the details button to find out what! If that didn't help...

 ### Make sure:
- Make sure you've entered you're credentials correctly.
- Make sure you've selected the right printer (color or black/white).
- Make sure you've waited at least one minute after submitting the print job before swiping your card at the Pharos terminal.
- Make sure that you're phone can receive DUO requests.
- Make sure to click on the "Details" button during the loading screen to see why you're job failed.

- If you've made sure of all of the above, please contact <tjz@mit.edu> or <sipb@mit.edu> with a copy of your debug log (you can select and copy/paste it).



 ## Development
MIT Print is developed with Flutter, a cross platform mobile development SDK. Currently, running on iOS should be possible but has not been tested.

The app is currently available on Google Play [here](https://play.google.com/store/apps/details?id=com.tzgames.mitprint). The GitHub repo is located [here](https://github.com/travisjayday/mitprint). Make sure to leave a review if you like it!

 ## Contact
This project is a SIPB project and is maintained by <tjz@mit.edu>. For questions or feature requests or problems, email `tjz` or open an issue in the repo.
