import 'package:animetrace/controllers/host_service.dart';
import 'package:animetrace/controllers/proxy_service.dart';
import 'package:animetrace/widgets/setting_card.dart';
import 'package:flutter/material.dart';

class ProxyPage extends StatefulWidget {
  const ProxyPage({super.key});

  @override
  State<ProxyPage> createState() => _ProxyPageState();
}

class _ProxyPageState extends State<ProxyPage> {
  late ProxyType proxyType;
  final proxyInputController = TextEditingController();
  final hostsInputController = TextEditingController();

  String get forwardHint => '''
Bangumi 示例：

# 网站：bangumi.tv 和 bgm.tv 请求转发到 bgm.mirror
bgm.mirror bangumi.tv bgm.tv

# 接口：api.bgm.tv 请求转发到 api.bgm.mirror
api.bgm.mirror api.bgm.tv

# 封面：lain.bgm.tv 请求转发到 lain.bgm.mirror
lain.bgm.mirror lain.bgm.tv
''';

  @override
  void initState() {
    super.initState();
    proxyType = ProxyService.to.type;
    proxyInputController.text = ProxyService.to.proxy;
    hostsInputController.text = HostService.to.content;
  }

  @override
  void dispose() {
    proxyInputController.dispose();
    super.dispose();
  }

  void _onWillPop() async {
    ProxyService.to
        .loadProxy(type: proxyType, proxy: proxyInputController.text);
    HostService.to.updateHosts(hostsInputController.text);
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
          title: const Text('代理设置'),
          leading: BackButton(onPressed: _onWillPop),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingCard(
                title: '代理',
                useCard: false,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownMenu<ProxyType>(
                        width: 140,
                        requestFocusOnTap: false,
                        initialSelection: proxyType,
                        dropdownMenuEntries: ProxyType.values
                            .map((e) =>
                                DropdownMenuEntry(value: e, label: e.label))
                            .toList(),
                        onSelected: (value) {
                          if (value == null) return;

                          setState(() {
                            proxyType = value;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: proxyInputController,
                          enabled: proxyType != ProxyType.direct,
                          decoration: const InputDecoration(
                              helperText: 'username:password@host:port'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              SettingCard(
                title: '转发',
                useCard: false,
                children: [
                  TextField(
                    controller: hostsInputController,
                    maxLines: null,
                    decoration: InputDecoration(hintText: forwardHint),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
