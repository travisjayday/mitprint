import 'package:flutter/material.dart';

class BackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    var oH = 60;
    var oW = size.width * 10;
    var buttonRadius = 75.0;
    var buttonPadding = 10.0;
    num degToRad(num deg) => deg * (3.1415926535897932 / 180.0);
    path.arcTo(Rect.fromLTRB(
        -(oW - size.width) / 2, size.height - oH,
        size.width + (oW - size.width) / 2,
        size.height + oH),
        degToRad(0),
        degToRad(-180),
        false
    );
    var r = Rect.fromLTWH(
        size.width / 2 - buttonRadius,
        size.height - 2 * buttonRadius - buttonPadding + 5,
        2 * buttonRadius, 2 * buttonRadius
    );
    Path path2 = Path();
    path2.addArc(r, degToRad(0), degToRad(360));
    return Path.combine(PathOperation.union, path, path2);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}