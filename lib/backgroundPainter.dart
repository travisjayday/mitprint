import 'package:flutter/material.dart';

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // set the color property of the paint
    paint.color = Colors.deepOrange;
    // center of the canvas is (x,y) => (width/2, height/2)
    var center = Offset(size.width / 2, size.height / 2);
    var h = 400.0;

    // draw the circle on centre of canvas having radius 75.0
    canvas.clipRect(Rect.fromLTWH(0, size.height - h, size.width, h));
    canvas.drawRect(Rect.fromLTWH(0, size.height - h, size.width, h), paint);
    //canvas.drawColor(Color.fromARGB(255, 255, 255, 0), BlendMode.clear);

  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}