import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/path_helper.dart';
import 'package:path_provider/path_provider.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FloatingActionButton(
        onPressed: () async {
          await writeString();
          debugPrint(
              "getExternalStorageDirectory(): ${await getExternalStorageDirectory()}");
          debugPrint(
              "getExternalStorageDirectories(): ${await getExternalStorageDirectories()}");
        },
        child: const Icon(Icons.ad_units),
      ),
    );
  }
}
