import 'package:flutter/material.dart';

class SideArrowClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    var height = size.height - size.width - 155;
    var oH = 100;
    var oW = size.width * 1.3;
    var buttonRadius = 85.0;
    var buttonPadding = 7.0;
    var topRad = 100.0;
    var ovalH = size.width;
    var margin = 100.0;
    num degToRad(num deg) => deg * (3.1415926535897932 / 180.0);
    /*path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);

    path.arcTo(Rect.fromLTWH(0, height, size.width, size.width * 1.2), degToRad(0), degToRad(180), false);
    path.moveTo(size.width / 2, 0);
    var r = Rect.fromLTWH(0, -topRad, size.width, 2 * topRad);
    path.close();*/
    path.arcTo(Rect.fromLTRB(-(oW - size.width) / 2, size.height - oH, size.width + (oW - size.width) / 2, size.height + oH), degToRad(0), degToRad(-180), false);
    //path.addArc(r, degToRad(0), degToRad(360));
    //path.addRect(Rect.fromLTWH(margin, -topRad, size.width - 2 * margin, 2 * topRad));
    var r = Rect.fromLTWH(size.width / 2 - buttonRadius, size.height - 2 * buttonRadius - buttonPadding + 5, 2 * buttonRadius, 2 * buttonRadius);
    Path path2 = Path();
    path2.addArc(r, degToRad(0), degToRad(360));

    return Path.combine(PathOperation.union, path, path2);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}