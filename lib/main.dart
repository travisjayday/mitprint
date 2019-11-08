import 'package:flutter/material.dart';
import 'screens/mainScreen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIT Print',
      theme: ThemeData(
        primaryColor: Color.fromRGBO(163, 31, 52, 1.0),
        accentColor: Color.fromRGBO(138, 139, 140, 1.0),
        backgroundColor: Colors.grey[100],
      ),
      home: MainScreen(),
    );
  }
}

