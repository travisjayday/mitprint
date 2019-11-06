import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  @override
  _HelpScreenState createState() {
    return _HelpScreenState();
  }
}

class _HelpScreenState extends State<HelpScreen> {
  String markdown = "## Help Section\n loading...";

  @override
  void initState() {
    super.initState();

    () async {
      String md = await rootBundle.loadString('README.md');
      setState(() {
        markdown = md;
      });
    }();
  }

  void _open(String href) async {
    print("laucnhign " + href);
    launch(href);
  }

  Widget build(BuildContext context) {
    return MarkdownBody(
        data: markdown,
        onTapLink: (String href) {
          _open(href);
        });
  }
}
