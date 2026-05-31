import 'package:animetrace/controllers/host_service.dart';
import 'package:animetrace/controllers/setting_service.dart';
import 'package:animetrace/models/enum/proxy_type.dart';
import 'package:animetrace/utils/dio_util.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:animetrace/widgets/setting_title.dart';
import 'package:flutter/material.dart';

class HostsPage extends StatefulWidget {
  const HostsPage({super.key});

  @override
  State<HostsPage> createState() => _HostsPageState();
}

class _HostsPageState extends State<HostsPage> {
  late ProxyType proxyType;
  final proxyInputController = TextEditingController();
  final hostsInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    proxyType = SettingService.to.getProxyType();
    proxyInputController.text = SettingService.to.getProxy();
    hostsInputController.text = HostService.to.content;
  }

  @override
  void dispose() {
    proxyInputController.dispose();
    super.dispose();
  }

  void _onWillPop() async {
    await SettingService.to.setProxyType(proxyType);
    await SettingService.to.setProxy(proxyInputController.text);
    DioUtil.loadProxy();
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
          title: const Text('代理转发'),
          leading: BackButton(onPressed: _onWillPop),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (PlatformUtil.isDesktop) ...[
              const SettingTitle(title: '代理'),
              ListTile(
                title: const Text('代理类型'),
                trailing: DropdownMenu<ProxyType>(
                  requestFocusOnTap: false,
                  initialSelection: proxyType,
                  dropdownMenuEntries: ProxyType.values
                      .map((e) => DropdownMenuEntry(value: e, label: e.label))
                      .toList(),
                  onSelected: (value) {
                    if (value == null) return;

                    setState(() {
                      proxyType = value;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: proxyInputController,
                  decoration: const InputDecoration(
                      hintText: 'username:password@host:port'),
                ),
              ),
            ],
            const SettingTitle(title: '转发'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: hostsInputController,
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
          ],
        ),
      ),
    );
  }
}
