import 'package:flutter/material.dart';

class SideArrowClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    var height = size.height - size.width - 25;
    var buttonRadius = 90.0;
    var buttonPadding = 7.0;
    var topRad = 100.0;
    var ovalH = size.width;
    var margin = 100.0;
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    num degToRad(num deg) => deg * (3.1415926535897932 / 180.0);
    path.arcTo(Rect.fromLTWH(0, height, size.width, size.width), degToRad(0), degToRad(180), false);
    path.moveTo(size.width / 2, 0);
    var r = Rect.fromLTWH(0, -topRad, size.width, 2 * topRad);
    //path.addArc(r, degToRad(0), degToRad(360));
    //path.addRect(Rect.fromLTWH(margin, -topRad, size.width - 2 * margin, 2 * topRad));
    r = Rect.fromLTWH(size.width / 2 - buttonRadius, size.height - 2 * buttonRadius - buttonPadding, 2 * buttonRadius, 2 * buttonRadius);
    Path path2 = Path();
    path2.addArc(r, degToRad(0), degToRad(360));
    path.close();
    return Path.combine(PathOperation.union, path, path2);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}