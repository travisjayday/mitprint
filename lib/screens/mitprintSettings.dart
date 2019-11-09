import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';

import 'markdownTiled.dart';

class MitPrintSettings extends StatelessWidget {
  const MitPrintSettings() : super();

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      title: "MIT Print Settings",
      children: <Widget>[
        SettingsTileGroup(
          title: "Authentication",
          children: <Widget>[
            TextFieldModalSettingsTile(
                settingKey: "kerbUser", title: "Set Kerberos Username"),
            TextFieldModalSettingsTile(
                obscureText: true,
                settingKey: "kerbPass",
                title: "Set Kerberos Password"),
            SwitchSettingsTile(
                settingKey: "rememberPass", title: "Save & Remember Password"),
            RadioPickerSettingsTile(
                settingKey: 'authMethod',
                title: 'Select Duo-authentication method',
                values: {'1': 'Duo Push Notification', '2': 'Phone Call'})
          ],
        ),
        SettingsTileGroup(
          title: "Printing",
          children: <Widget>[
            SwitchSettingsTile(
                settingKey: "color_print", title: "Use the Color Printer")
          ],
        ),
        SettingsTileGroup(
          title: "Other",
          children: <Widget>[
            SimpleSettingsTile(
                title: 'Feedback & Help',
                screen: SettingsScreen(title: "Feedback & Help", children: [
                  SettingsContainer(
                      children: [MarkdownTiled(file: "README.md")])
                ])),
            SimpleSettingsTile(
                title: 'Credits & Data',
                screen: SettingsScreen(title: "Credits & Data", children: [
                  SettingsContainer(
                      children: [MarkdownTiled(file: "CREDITS.md")])
                ])),
          ],
        )
      ],
    );
  }
}
