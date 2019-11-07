import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

class MarkdownTiled extends StatefulWidget {
  final String file;

  MarkdownTiled({this.file});

  @override
  _MarkdownTiledState createState() {
    return _MarkdownTiledState(file);
  }
}

class _MarkdownTiledState extends State<MarkdownTiled> {
  String markdown = "## Help Section\n loading...";
  List<Widget> cards = new List<Widget>();
  String file;

  _MarkdownTiledState(String file) {
    this.file = file;
  }

  @override
  void initState() {
    super.initState();

    () async {
      String md = await rootBundle.loadString(file);
      List<String> sections = md.split("##");
      for (String section in sections) {
        if (section.length < 3) continue;
        if (!section.startsWith("#")) section = "##" + section;
        cards.add(Card(
            margin: EdgeInsets.symmetric(vertical: 6.0),
            child: Padding(
                padding: EdgeInsets.all(15.0),
                child: MarkdownBody(
                    data: section,
                    onTapLink: (String href) {
                      _open(href);
                    }))));
      }
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
    return Column(children: cards);
  }
}
