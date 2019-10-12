import 'package:flutter/material.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';

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
            TextFieldModalSettingsTile(settingKey: "kerb_user", title: "Set Kerberos Username"),
            TextFieldModalSettingsTile(settingKey: "kerb_pass", title: "Set Kerberos Password"),
            SwitchSettingsTile(settingKey: "remember_pass", title: "Save & Remember Password"),
            RadioPickerSettingsTile(settingKey: 'Select Duo-authentication method', title: 'Select one option',
              values: {'1': 'Duo Push Notification', '2': 'Phone Call'})
          ],
        ),
        SettingsTileGroup(
          title: "Printing",
          children: <Widget>[
            SwitchSettingsTile(settingKey: "colorprint", title: "Use the Color Printer")
          ],
        ),
        SettingsTileGroup(
          title: "Other",
          children: <Widget>[
            SimpleSettingsTile(
              title: 'Help',
              screen:
                SettingsScreen(
                  title: "Help",
                    children: [
                    SettingsContainer(
                      // TODO: Write help section
                      children: <Widget>[Text("This is a help section.")],
                    )
                ])
            ),
            SimpleSettingsTile(
                title: 'Credits',
                screen:
                SettingsScreen(
                    title: "Credits",
                    children: [
                      SettingsContainer(
                        // TODO: Write help section
                        children: <Widget>[Text("This is a Credits section.")],
                      )
                    ])
            ),
          ],
        )
      ],
    );
  }
}