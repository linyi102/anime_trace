import 'package:animations/animations.dart';
import 'package:animetrace/pages/network/sources/pages/migrate/migrate_page.dart';
import 'package:expand_widget/expand_widget.dart';
import 'package:flutter/material.dart';

import 'package:animetrace/models/climb_website.dart';
import 'package:animetrace/components/website_logo.dart';
import 'package:animetrace/models/enum/bangumi_search_category.dart';
import 'package:animetrace/pages/network/climb/anime_climb_one_website.dart';
import 'package:animetrace/pages/network/sources/pages/import/import_collection_page.dart';
import 'package:animetrace/utils/common_util.dart';
import 'package:animetrace/utils/form_validator.dart';
import 'package:animetrace/utils/global_data.dart';
import 'package:animetrace/utils/launch_uri_util.dart';
import 'package:animetrace/utils/sp_util.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:animetrace/values/values.dart';
import 'package:animetrace/widgets/common_divider.dart';
import 'package:animetrace/widgets/common_scaffold_body.dart';
import 'package:animetrace/widgets/common_text_field.dart';
import 'package:animetrace/widgets/responsive.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import 'anime_list_in_source.dart';

/// 单个搜索源详细页面
class SourceDetail extends StatefulWidget {
  final ClimbWebsite climbWebstie;

  const SourceDetail(this.climbWebstie, {Key? key}) : super(key: key);

  @override
  State<SourceDetail> createState() => _SourceDetailState();
}

class _SourceDetailState extends State<SourceDetail> {
  ClimbWebsite? lastClimbWebsite;
  late ClimbWebsite curClimbWebsite = widget.climbWebstie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(curClimbWebsite.name)),
      body: CommonScaffoldBody(
          child: Responsive(
              mobile: Column(
                children: [
                  _buildAllSourceHorizontal(),
                  // const CommonDivider(direction: Axis.horizontal),
                  Expanded(
                      child: _buildSourceDetail(
                          transitionType: SharedAxisTransitionType.horizontal)),
                ],
              ),
              desktop: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAllSourceVertical(),
                  const CommonDivider(direction: Axis.vertical),
                  Expanded(
                      child: _buildSourceDetail(
                          transitionType: SharedAxisTransitionType.vertical)),
                ],
              ))),
    );
  }

  _buildAllSourceHorizontal() {
    return Container(
      decoration:
          BoxDecoration(color: Theme.of(context).appBarTheme.backgroundColor),
      height: 60,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemCount: climbWebsites.length,
        itemBuilder: (context, index) => _buildSourceItem(climbWebsites[index]),
      ),
    );
  }

  SizedBox _buildAllSourceVertical() {
    return SizedBox(
        width: 80,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: climbWebsites.length,
          itemBuilder: (context, index) =>
              _buildSourceItem(climbWebsites[index]),
        ));
  }

  GestureDetector _buildSourceItem(ClimbWebsite website) {
    return GestureDetector(
      onTap: () {
        setState(() {
          lastClimbWebsite = curClimbWebsite;
          curClimbWebsite = website;
        });
      },
      child: Container(
        color: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1.5,
                  color: website == curClimbWebsite
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(99),
              ),
              child:
                  WebSiteLogo(url: website.iconUrl, size: 35, addShadow: false),
            ),
            // Text(climbWebsites[index].name),
          ],
        ),
      ),
    );
  }

  _buildSourceDetail({required SharedAxisTransitionType transitionType}) {
    return PageTransitionSwitcher(
      reverse: lastClimbWebsite == null
          ? false
          : climbWebsites.indexOf(lastClimbWebsite!) >
              climbWebsites.indexOf(curClimbWebsite),
      transitionBuilder: (
        Widget child,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: transitionType,
          child: child,
        );
      },
      child: Scaffold(
        key: ObjectKey(curClimbWebsite),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              WebSiteLogo(
                  url: curClimbWebsite.iconUrl, size: 100, addShadow: false),
              _buildUrl(),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: ExpandText(curClimbWebsite.desc,
                    maxLines: 2, textAlign: TextAlign.center),
              ),
              ListTile(
                enabled: !curClimbWebsite.discard,
                title: const Text("启动搜索"),
                leading: !curClimbWebsite.discard && curClimbWebsite.enable
                    ? Icon(Icons.check_box,
                        color: Theme.of(context).primaryColor)
                    : Icon(
                        Icons.check_box_outline_blank,
                        color: Theme.of(context).primaryColor,
                      ),
                onTap: () {
                  if (curClimbWebsite.discard) {
                    ToastUtil.showText("很抱歉，该搜索源已经无法使用");
                    return;
                  }
                  curClimbWebsite.enable = !curClimbWebsite.enable;
                  setState(() {});
                  // 保存
                  SPUtil.setBool(curClimbWebsite.spkey, curClimbWebsite.enable);
                },
              ),
              ListTile(
                enabled: !curClimbWebsite.discard,
                title: const Text("搜索动漫"),
                leading: Icon(
                  MingCuteIcons.mgc_search_2_line,
                  color: Theme.of(context).primaryColor,
                ),
                onTap: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return AnimeClimbOneWebsite(climbWebStie: curClimbWebsite);
                  }));
                },
              ),
              if (curClimbWebsite == bangumiClimbWebsite)
                ListTile(
                  leading: Icon(
                    Icons.filter_alt_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text('搜索类型'),
                  subtitle: Text(
                    BangumiSearchCategory.getCategoryByKey(
                                Config.selectedBangumiSearchCategoryKey)
                            ?.label ??
                        '',
                  ),
                  onTap: _showDialogSelectBangumiCategory,
                ),
              ListTile(
                title: const Text("收藏列表"),
                leading: Icon(
                  MingCuteIcons.mgc_heart_line,
                  color: Theme.of(context).primaryColor,
                ),
                onTap: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return AnimeListInSource(website: curClimbWebsite);
                  }));
                },
              ),
              if (curClimbWebsite.supportImport) _buildImportDataTile(),
              ListTile(
                title: const Text("迁移动漫"),
                leading: Icon(
                  MingCuteIcons.mgc_transfer_line,
                  color: Theme.of(context).primaryColor,
                ),
                onTap: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return MigratePage(website: curClimbWebsite);
                  }));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container _buildUrl() {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          _showUrlMenuDialog();
        },
        child: Container(
          padding: const EdgeInsets.all(6.0),
          child: Text(
            curClimbWebsite.climb.baseUrl,
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ),
      ),
    );
  }

  void _showDialogSelectBangumiCategory() {
    String categoryKey = Config.selectedBangumiSearchCategoryKey;

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('搜索类型'),
        children: BangumiSearchCategory.values
            .map((e) => RadioListTile(
                title: Text(e.label),
                groupValue: categoryKey,
                value: e.key,
                onChanged: (value) {
                  Config.setSelectedBangumiSearchCategoryKey(e.key);
                  Navigator.pop(context);
                  setState(() {});
                }))
            .toList(),
      ),
    );
  }

  Future<dynamic> _showUrlMenuDialog() {
    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new_rounded),
            title: const Text('访问网站'),
            onTap: () {
              Navigator.pop(context);
              LaunchUrlUtil.launch(
                  context: context, uriStr: curClimbWebsite.climb.baseUrl);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: const Text('复制链接'),
            onTap: () {
              Navigator.pop(context);
              CommonUtil.copyContent(curClimbWebsite.climb.baseUrl);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: const Text('自定义'),
            onTap: () {
              Navigator.pop(context);
              showEditBaseUrlDialog();
            },
            trailing: TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await curClimbWebsite.climb.removeCustomBaseUrl();
                  if (mounted) setState(() {});
                },
                child: const Text('重置')),
          ),
        ],
      ),
    );
  }

  Future<dynamic> showEditBaseUrlDialog() {
    final formKey = GlobalKey<FormState>();
    final urlTEC = TextEditingController(text: curClimbWebsite.climb.baseUrl);
    const title = '自定义';
    const labelText = '链接';

    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text(title),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      CommonTextFormField(
                        controller: urlTEC,
                        autofocus: true,
                        labelText: labelText,
                        validator: FormValidator.checkIsUrl,
                        maxLength: 99,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消')),
                TextButton(
                    onPressed: () {
                      if (FormValidator.isInvalid(formKey)) {
                        return;
                      }

                      Navigator.pop(context);
                      curClimbWebsite.climb.customBaseUrl = urlTEC.text;
                      setState(() {});
                    },
                    child: const Text('确定')),
              ],
            ));
  }

  _buildImportDataTile() {
    return ListTile(
      title: const Text("导入数据"),
      leading: Icon(
        // Icons.post_add,
        // Icons.add_chart_outlined,
        // Icons.bar_chart_rounded,
        MingCuteIcons.mgc_file_import_line,
        color: Theme.of(context).primaryColor,
      ),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ImportCollectionPage(
                      climbWebsite: curClimbWebsite,
                    )));
      },
    );
  }
}
