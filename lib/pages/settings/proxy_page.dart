import 'package:animetrace/controllers/host_service.dart';
import 'package:animetrace/controllers/proxy_service.dart';
import 'package:animetrace/models/ping_result.dart';
import 'package:animetrace/utils/climb/climb_bangumi.dart';
import 'package:animetrace/utils/dio_util.dart';
import 'package:animetrace/utils/network/bangumi_api.dart';
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

  final pingDests = [
    _PingDest('Bangumi 网站', ClimbBangumi().baseUrl, const PingStatus()),
    _PingDest('Bangumi 接口', BangumiApi.baseUrl, const PingStatus()),
    _PingDest('Bangumi 封面', 'https://lain.bgm.tv', const PingStatus()),
  ];
  int _pingToken = 0;

  @override
  void initState() {
    super.initState();
    proxyType = ProxyService.to.type;
    proxyInputController.text = ProxyService.to.proxy;
    hostsInputController.text = HostService.to.content;
    _ping();
  }

  @override
  void dispose() {
    proxyInputController.dispose();
    super.dispose();
  }

  void _onWillPop() {
    _saveConfig();
    Navigator.pop(context);
  }

  Future<void> _saveConfig() async {
    ProxyService.to
        .loadProxy(type: proxyType, proxy: proxyInputController.text);
    await HostService.to.updateHosts(hostsInputController.text);
  }

  void _ping() async {
    List<Future> futures = [];

    for (final dest in pingDests) {
      dest.status = const PingStatus.pinging();
    }
    setState(() {});

    final token = ++_pingToken;
    for (final dest in pingDests) {
      futures.add(DioUtil.ping(
        dest.url,
        checkCode: (statusCode) => const {200, 404}.contains(statusCode),
      ).then((r) {
        if (token != _pingToken) return;

        dest.status = r;
        if (mounted) setState(() {});
      }));
    }
    await futures.wait;
  }

  void _showProxyHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('帮助'),
        content: const SelectableText('''
假设 Banugmi 存在 bgm.mirror 镜像，可进行以下配置：

# 网站
bgm.mirror bangumi.tv bgm.tv

# 接口
api.bgm.mirror api.bgm.tv

# 封面
lain.bgm.mirror lain.bgm.tv
'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          )
        ],
      ),
    );
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
          padding: const EdgeInsets.only(bottom: 64),
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
                          decoration:
                              const InputDecoration(hintText: 'host:port'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              SettingCard(
                title: '转发',
                useCard: false,
                trailing: IconButton(
                  onPressed: _showProxyHelpDialog,
                  icon: const Icon(Icons.help_outline),
                ),
                children: [
                  TextField(
                    controller: hostsInputController,
                    minLines: 3,
                    maxLines: 10,
                    decoration:
                        const InputDecoration(hintText: '<host-mirror> <host>'),
                  )
                ],
              ),
              SettingCard(
                title: '测试',
                trailing: FilledButton(
                    onPressed: () async {
                      await _saveConfig();
                      _ping();
                    },
                    child: const Text('检测')),
                children: [
                  for (final dest in pingDests)
                    ListTile(
                      title: Text(dest.title),
                      subtitle: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: dest.status.color,
                          ),
                          const SizedBox(width: 4),
                          Text(dest.status.label),
                        ],
                      ),
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

class _PingDest {
  final String title;
  final String url;
  PingStatus status;

  _PingDest(this.title, this.url, this.status);
}
