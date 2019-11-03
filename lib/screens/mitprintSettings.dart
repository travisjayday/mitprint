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
            TextFieldModalSettingsTile(obscureText: true, settingKey: "kerb_pass", title: "Set Kerberos Password"),
            SwitchSettingsTile(settingKey: "remember_pass", title: "Save & Remember Password"),
            RadioPickerSettingsTile(settingKey: 'auth_method', title: 'Select Duo-authentication method',
              values: {'1': 'Duo Push Notification', '2': 'Phone Call'})
          ],
        ),
        SettingsTileGroup(
          title: "Printing",
          children: <Widget>[
            SwitchSettingsTile(settingKey: "color_print", title: "Use the Color Printer")
          ],
        ),
        SettingsTileGroup(
          title: "Other",
          children: <Widget>[
            SimpleSettingsTile(
              title: 'Feedback & Help',
              screen:
                SettingsScreen(
                  title: "Feedback & Help",
                    children: [
                    SettingsContainer(
                      // TODO: Write help section
                      children: <Widget>[Text("This help section has not been completed yet :(. Email sipb@mit.edu for feedback / help.")],
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
                        children: <Widget>[Text("This section has not been completed yet.")],
                      )
                    ])
            ),
          ],

        )
      ],
    );
  }
}