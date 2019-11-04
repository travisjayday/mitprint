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

## Development
MIT Print is developed with Flutter, a cross platform mobile development SDK. Currently, running on iOS should be possible but has not been tested. The app is currently available on Google Play at https://play.google.com/store/apps/details?id=com.tzgames.mitprint.

## Contact
This projcet is a SIPB project and is maintained by `tjz@mit.edu`. For questions or feature requests or problems, email `tjz` or open an issue in the repo.
