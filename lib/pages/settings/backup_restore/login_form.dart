import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/components/operation_button.dart';

import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

class WebDavLoginForm extends StatefulWidget {
  const WebDavLoginForm({super.key});

  @override
  State<WebDavLoginForm> createState() => _WebDavLoginFormState();
}

class _WebDavLoginFormState extends State<WebDavLoginForm> {
  final inputUriController = TextEditingController(
    text: SPUtil.getString('webdav_uri',
        defaultValue: 'https://dav.jianguoyun.com/dav/'),
  );
  final inputUserController =
      TextEditingController(text: SPUtil.getString('webdav_user'));
  final inputPasswordController =
      TextEditingController(text: SPUtil.getString('webdav_password'));
  late List<TextEditingController> controllers = [
    inputUriController,
    inputUserController,
    inputPasswordController
  ];
  bool connecting = false;

  List<String> labelTexts = ["服务器地址", "账号", "密码"];
  List<List<String>?> autofillHintsList = [
    null,
    [AutofillHints.username],
    [AutofillHints.password]
  ];

  @override
  void dispose() {
    inputUriController.dispose();
    inputUserController.dispose();
    inputPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("账号配置"),
      content: AutofillGroup(
        child: SingleChildScrollView(
          child: Column(
            children: [
              for (int i = 0; i < controllers.length; ++i)
                TextField(
                  obscureText: controllers[i] == inputPasswordController,
                  controller: controllers[i],
                  decoration: InputDecoration(labelText: labelTexts[i]),
                  autofillHints: autofillHintsList[i],
                ),
              OperationButton(
                horizontal: 0,
                text: connecting ? '连接中' : '连接',
                fontSize: 14,
                // 连接时不允许再次点击按钮
                active: !connecting,
                onTap: () {
                  setState(() {
                    connecting = true;
                  });
                  _connect();
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  _connect() async {
    String uri = inputUriController.text;
    String user = inputUserController.text;
    String password = inputPasswordController.text;
    if (uri.isEmpty || user.isEmpty || password.isEmpty) {
      ToastUtil.showText("请将信息填入完整！");
    } else {
      TextInput.finishAutofillContext();
      SPUtil.setString("webdav_uri", uri);
      SPUtil.setString("webdav_user", user);
      SPUtil.setString("webdav_password", password);
      if (await WebDavUtil.initWebDav(uri, user, password)) {
        ToastUtil.showText("连接成功");
        Navigator.pop(context);
      } else {
        ToastUtil.showText("无法连接，请确保输入正确和网络正常！");
      }
    }

    connecting = false;
    // 连接正确后，修改账号后连接失败，需要重新更新显示状态。init里的ping会通过SPUtil记录状态
    if (mounted) setState(() {});
  }
}
