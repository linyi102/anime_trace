import 'package:animetrace/controllers/host_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class HostsPage extends StatefulWidget {
  const HostsPage({super.key});

  @override
  State<HostsPage> createState() => _HostsPageState();
}

class _HostsPageState extends State<HostsPage> {
  final inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    inputController.text = HostService.to.content;
  }

  void _onWillPop() {
    HostService.to.updateHosts(inputController.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('转发规则'),
          leading: BackButton(onPressed: _onWillPop),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: inputController,
            minLines: 10,
            maxLines: null,
            decoration: const InputDecoration(hintText: '''
Bangumi 示例：

# 网站：bangumi.tv 和 bgm.tv 请求转发到 bgm.proxy
bgm.proxy bangumi.tv bgm.tv

# 接口：api.bgm.tv 请求转发到 api.bgm.proxy
api.bgm.proxy api.bgm.tv

# 封面：lain.bgm.tv 请求转发到 lain.bgm.proxy
lain.bgm.proxy lain.bgm.tv
'''),
          ),
        ),
      ),
    );
  }
}
