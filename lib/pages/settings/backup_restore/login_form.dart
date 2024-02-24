import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/models/enum/webdav_website.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/values/assets.dart';
import 'package:flutter_test_future/widgets/button/loading_button.dart';
import 'package:flutter_test_future/widgets/limit_width_center.dart';
import 'package:flutter_test_future/widgets/svg_asset_icon.dart';

class WebDavLoginForm extends StatefulWidget {
  const WebDavLoginForm({super.key});

  @override
  State<WebDavLoginForm> createState() => _WebDavLoginFormState();
}

class _WebDavLoginFormState extends State<WebDavLoginForm> {
  final WebDAVWebSite defaultWebsite = WebDAVWebSite.jianguoyun;
  late WebDAVWebSite curWebsite = defaultWebsite;

  late final TextEditingController inputUriController;
  final inputUserController =
      TextEditingController(text: SPUtil.getString('webdav_user'));
  final inputPasswordController =
      TextEditingController(text: SPUtil.getString('webdav_password'));
  bool showPwd = false;

  @override
  void initState() {
    super.initState();

    String inputUrl =
        SPUtil.getString('webdav_uri', defaultValue: defaultWebsite.url);
    inputUriController = TextEditingController(text: inputUrl);
    setState(() {
      curWebsite = WebDAVWebSite.getWebDAVWebSiteByUrlKeyword(inputUrl);
    });
  }

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
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: AlignLimitedBox(
        maxWidth: 500,
        alignment: Alignment.topCenter,
        child: AutofillGroup(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildLogoContainer(curWebsite),
                const SizedBox(height: 60),
                _buildTextField(inputUriController, '服务器地址',
                    onChanged: (value) {
                  setState(() {
                    curWebsite =
                        WebDAVWebSite.getWebDAVWebSiteByUrlKeyword(value);
                  });
                }),
                _buildTextField(
                  inputUserController,
                  '帐号',
                  autofillHints: [AutofillHints.username],
                ),
                _buildTextField(
                  inputPasswordController,
                  '密码',
                  isPwd: true,
                  showPwd: showPwd,
                  onTapPwdEye: () {
                    setState(() {
                      showPwd = !showPwd;
                    });
                  },
                  autofillHints: [AutofillHints.password],
                ),
                ActionButton(
                  height: 45,
                  loader: circularTextButtonLoader('登录中'),
                  loaderStyle: ButtonLoaderStyle.custom,
                  child: const Text('登录'),
                  onTap: () async {
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

  Container _buildTextField(
    TextEditingController textEditingController,
    String label, {
    bool isPwd = false,
    bool showPwd = false,
    void Function()? onTapPwdEye,
    void Function(String value)? onChanged,
    Iterable<String>? autofillHints,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextField(
        obscureText: isPwd && !showPwd,
        controller: textEditingController,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: isPwd
              ? IconButton(
                  splashRadius: 20,
                  onPressed: onTapPwdEye,
                  icon: const Icon(Icons.remove_red_eye))
              : null,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).hintColor.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        autofillHints: autofillHints,
      ),
    );
  }

  _buildLogoContainer(WebDAVWebSite webSite) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            children: [
              for (var item in WebDAVWebSite.values)
                RadioListTile(
                  title: Text(item.title),
                  value: item,
                  groupValue: webSite,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      curWebsite = value;
                    });
                    inputUriController.text = value.url;

                    Navigator.pop(context);
                  },
                )
            ],
          ),
        );
      },
      child: Column(
        children: [
          SizedBox(height: 100, width: 100, child: _buildLogo(webSite)),
          Text(
            webSite.title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 24, height: 1.5),
          ),
        ],
      ),
    );
  }

  _buildLogo(WebDAVWebSite website) {
    switch (website) {
      case WebDAVWebSite.common:
        return Icon(Icons.cloud,
            size: 80, color: Theme.of(context).primaryColor);
      case WebDAVWebSite.jianguoyun:
        return Image.asset(Assets.iconsJianguoyun);
      case WebDAVWebSite.infiniCloud:
        return const SvgAssetIcon(
          assetPath: Assets.iconsInfiniCloud,
          color: Color(0xFFEF8200),
        );
    }
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

    // 连接正确后，修改帐号后连接失败，需要重新更新显示状态。init里的ping会通过SPUtil记录状态
    if (mounted) setState(() {});
  }
}
