import 'package:flutter/material.dart';

class WebDavSetting extends StatefulWidget {
  const WebDavSetting({Key? key}) : super(key: key);

  @override
  _WebDavSettingState createState() => _WebDavSettingState();
}

class _WebDavSettingState extends State<WebDavSetting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "账号配置",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        shadowColor: Colors.transparent,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: Center(
        child: Column(
          children: const [
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.settings),
                labelText: "服务器地址",
              ),
            )
          ],
        ),
      ),
    );
  }
}
