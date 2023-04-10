import 'package:flutter/material.dart';

import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/pages/network/sources/pages/source_detail_page.dart';
import 'package:flutter_test_future/pages/network/sources/widgets/ping_status.dart';
import 'package:flutter_test_future/utils/global_data.dart';
import 'package:flutter_test_future/utils/sp_util.dart';

class SourceListPage extends StatefulWidget {
  const SourceListPage({super.key});

  @override
  State<SourceListPage> createState() => _SourceListPageState();
}

class _SourceListPageState extends State<SourceListPage> {
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("搜索源"),
      ),
      body: Scrollbar(
        controller: scrollController,
        child: ListView.builder(
          controller: scrollController,
          itemCount: climbWebsites.length,
          itemBuilder: (context, index) {
            final climbWebsite = climbWebsites[index];
            return _buildClimbWebsiteListItem(climbWebsite);
          },
        ),
      ),
    );
  }

  _buildClimbWebsiteListItem(ClimbWebsite climbWebsite) {
    return ListTile(
        title: Text(climbWebsite.name),
        subtitle: buildPingStatusRow(context, climbWebsite),
        leading: WebSiteLogo(url: climbWebsite.iconUrl, size: 35),
        trailing: _buildSwitchButton(climbWebsite),
        onTap: () => _enterSourceDetail(climbWebsite));
  }

  _enterSourceDetail(ClimbWebsite climbWebsite) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return SourceDetail(climbWebsite);
    })).then((value) {
      setState(() {});
      // 可能从里面取消了启动
    });
  }

  _buildSwitchButton(ClimbWebsite climbWebsite) {
    if (climbWebsite.discard) return null;

    return IconButton(
      onPressed: () {
        _invertSource(climbWebsite);
      },
      icon: climbWebsite.enable
          ? Icon(Icons.check_box, color: Theme.of(context).primaryColor)
          : const Icon(Icons.check_box_outline_blank),
    );
  }

  // 取消/启用搜索源
  void _invertSource(ClimbWebsite e) {
    e.enable = !e.enable;
    setState(() {}); // 使用的是StatefulBuilder的setState
    // 保存
    SPUtil.setBool(e.spkey, e.enable);
  }
}
