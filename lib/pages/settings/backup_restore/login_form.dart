import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/widgets/button/loading_button.dart';
import 'package:flutter_test_future/widgets/limit_width_center.dart';

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

  List<String> labelTexts = ["服务器地址", "帐号", "密码"];
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
    return Scaffold(
      appBar: AppBar(title: const Text('登录帐号')),
      body: AutofillGroup(
        child: AlignLimitedBox(
          maxWidth: 500,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                for (int i = 0; i < controllers.length; ++i)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: TextField(
                      obscureText: controllers[i] == inputPasswordController,
                      controller: controllers[i],
                      decoration: InputDecoration(
                        labelText: labelTexts[i],
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color:
                                  Theme.of(context).hintColor.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      autofillHints: autofillHintsList[i],
                    ),
                  ),
                ActionButton(
                  height: 45,
                  loader: circularTextButtonLoader('登录中'),
                  loaderStyle: ButtonLoaderStyle.custom,
                  child: const Text('登录'),
                  onTap: () async {
                    setState(() {
                      connecting = true;
                    });
                    await Future.delayed(const Duration(milliseconds: 400));
                    _connect();
                  },
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: () {
                        LaunchUrlUtil.launch(
                            context: context,
                            uriStr: "https://help.jianguoyun.com/?p=2064");
                      },
                      child: const Text('查看教程')),
                )
              ],
            ),
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
    // 连接正确后，修改帐号后连接失败，需要重新更新显示状态。init里的ping会通过SPUtil记录状态
    if (mounted) setState(() {});
  }
}
