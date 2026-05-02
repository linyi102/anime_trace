import 'package:animetrace/models/migrate_config.dart';
import 'package:flutter/material.dart';

/// 迁移配置页
class MigrateConfigPage extends StatefulWidget {
  const MigrateConfigPage({super.key, required this.config});
  final MigrateConfig? config;

  @override
  State<MigrateConfigPage> createState() => _MigrateConfigPageState();
}

class _MigrateConfigPageState extends State<MigrateConfigPage> {
  late final config = widget.config ?? MigrateConfig();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('迁移配置')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('封面'),
            value: config.coverIsNew,
            onChanged: (value) => setState(() => config.coverIsNew = value),
          ),
          SwitchListTile(
            title: const Text('名字'),
            value: config.nameIsNew,
            onChanged: (value) => setState(() => config.nameIsNew = value),
          ),
          SwitchListTile(
            title: const Text('别名'),
            value: config.anotherNameIsNew,
            onChanged: (value) =>
                setState(() => config.anotherNameIsNew = value),
          ),
          SwitchListTile(
            title: const Text('地区'),
            value: config.areaIsNew,
            onChanged: (value) => setState(() => config.areaIsNew = value),
          ),
          SwitchListTile(
            title: const Text('分类'),
            value: config.categoryIsNew,
            onChanged: (value) => setState(() => config.categoryIsNew = value),
          ),
          SwitchListTile(
            title: const Text('首播时间'),
            value: config.premiereTimeIsNew,
            onChanged: (value) =>
                setState(() => config.premiereTimeIsNew = value),
          ),
          SwitchListTile(
            title: const Text('播放状态'),
            value: config.playStatusIsNew,
            onChanged: (value) =>
                setState(() => config.playStatusIsNew = value),
          ),
          SwitchListTile(
            title: const Text('链接'),
            value: config.urlIsNew,
            onChanged: (value) => setState(() => config.urlIsNew = value),
          ),
          SwitchListTile(
            title: const Text('简介'),
            value: config.descIsNew,
            onChanged: (value) => setState(() => config.descIsNew = value),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, config);
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
