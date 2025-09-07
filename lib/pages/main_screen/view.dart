import 'package:animetrace/utils/event.dart';
import 'package:animetrace/widgets/animation/fade_in_up.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/controllers/backup_service.dart';
import 'package:animetrace/controllers/theme_controller.dart';
import 'package:animetrace/global.dart';
import 'package:animetrace/pages/main_screen/logic.dart';
import 'package:animetrace/utils/sp_profile.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/values/assets.gen.dart';
import 'package:get/get.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../widgets/common_divider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with MultiEventsStateMixin {
  final logic = Get.put(MainScreenLogic());
  int _clickBackCnt = 0;
  bool get enableAnimation => false;

  bool expandSideBar = SpProfile.getExpandSideBar();
  bool get hideMobileBottomLabel =>
      ThemeController.to.hideMobileBottomLabel.value;

  bool hideBottomNavigator = false;

  @override
  List<VoidCallback> get initialListeners => [
        Event(EventName.setNavigator).listen<bool>((to) {
          AppLog.debug('${to ? '显示' : '隐藏'}导航栏状态');
          setState(() {
            hideBottomNavigator = !to;
          });
        }),
      ];

  @override
  Widget build(BuildContext context) {
    AppLog.debug('build main screen');
    return WillPopScope(
      onWillPop: clickTwiceToExitApp,
      child: GetBuilder(
        init: logic,
        builder: (_) =>
            // FIXME Windows应用窗口宽小于高时首次启动会先是landscape，然后是portrait，导致创建两次动漫收藏页
            MediaQuery.orientationOf(context) == Orientation.portrait
                ? _buildPortraitScreen()
                : _buildLandscapeScreen(),
      ),
    );
  }

  Widget _buildLandscapeScreen() {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // 侧边栏
            _buildSideBar(),
            // 主体
            Expanded(child: _buildMainPage())
          ],
        ),
      ),
    );
  }

  Future<bool> clickTwiceToExitApp() async {
    _clickBackCnt++;
    if (_clickBackCnt == 2) {
      // 备份后退出
      BackupService.to.tryBackupBeforeExitApp(exitApp: () async {
        Global.exitApp();
      });
      // 始终返回false，暂时不退出App，等待备份成功后执行exitApp来退出
      return false;
    }
    Future.delayed(const Duration(seconds: 2)).then((value) {
      _clickBackCnt = 0;
      AppLog.info("点击返回次数重置为0");
    });
    ToastUtil.showText("再次点击退出应用");
    return false;
  }

  Widget _buildSideBar() {
    return Material(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: AnimatedContainer(
        curve: Curves.fastOutSlowIn,
        width: expandSideBar ? 150 : 70,
        duration: const Duration(milliseconds: 200),
        child: CustomScrollView(
          slivers: [
            // SliverFillRemaining作用：在Column中使用Spacer
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: _buildSideMenu(),
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSideMenu() {
    List<Widget> widgets = [];

    widgets.add(Container(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(Assets.images.logoRound.path, height: 40, width: 40),
        ],
      ),
    ));

    for (int i = 0; i < logic.tabs.length; ++i) {
      var mainTab = logic.tabs[i];
      double radius = 99;

      bool isSelected = logic.selectedTabIdx == i;
      widgets.add(
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            // color: isSelected && expandSideBar
            //     ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            //     : null,
          ),
          margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: () {
              if (logic.searchTabIdx == i && logic.selectedTabIdx == i) {
                // 如果点击的是探索页，且当前已在探索页，则进入聚合搜索页
                logic.openSearchPage(context);
              } else {
                logic.toTabPage(i);
              }
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
              child: Row(
                  mainAxisAlignment: expandSideBar
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    isSelected
                        ? IconTheme.merge(
                            data: IconThemeData(
                                color: Theme.of(context).colorScheme.primary),
                            child: mainTab.selectedIcon ?? mainTab.icon)
                        : mainTab.icon,
                    // 使用Spacer而不是固定宽度，这样展开时文字就不会溢出的
                    if (expandSideBar) const Spacer(flex: 2),
                    if (expandSideBar)
                      Expanded(
                        flex: 4,
                        child: Text(
                          mainTab.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            fontSize: 15,
                          ),
                        ),
                      ),
                  ]),
            ),
          ),
        ),
      );
    }

    widgets.add(const Spacer());
    widgets.add(const CommonDivider(
      padding: EdgeInsets.symmetric(vertical: 5),
    ));
    widgets.add(Row(
      mainAxisAlignment:
          expandSideBar ? MainAxisAlignment.end : MainAxisAlignment.center,
      children: [
        IconButton(
          splashRadius: 24,
          icon: Icon(
            expandSideBar
                ? MingCuteIcons.mgc_left_line
                : MingCuteIcons.mgc_right_line,
            // 不适合暗色主题
            // color: Colors.black54,
          ),
          onPressed: () {
            SpProfile.turnExpandSideBar();
            setState(() {
              expandSideBar = !expandSideBar;
            });
          },
        ),
      ],
    ));

    return widgets;
  }

  Widget _buildPortraitScreen() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _buildMainPage(),
      // TODO 隐藏时仍然会占用位置(背景色)，只有为null时才会彻底隐藏
      bottomNavigationBar: FadeInUp(
        animate: !hideBottomNavigator,
        child: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Obx(
      () => NavigationBar(
          selectedIndex: logic.selectedTabIdx,
          height: hideMobileBottomLabel ? 60 : null,
          elevation: hideMobileBottomLabel ? 0 : null,
          labelBehavior: hideMobileBottomLabel
              ? NavigationDestinationLabelBehavior.alwaysHide
              : null,
          indicatorColor: hideMobileBottomLabel ? Colors.transparent : null,
          onDestinationSelected: (value) {
            if (logic.searchTabIdx == value && logic.selectedTabIdx == value) {
              // 如果点击的是探索页，且当前已在探索页，则进入聚合搜索页
              logic.openSearchPage(context);
            } else {
              logic.toTabPage(value);
            }
          },
          destinations: [
            for (var tab in logic.tabs)
              NavigationDestination(
                icon: tab.icon,
                selectedIcon: tab.selectedIcon ?? tab.icon,
                label: tab.name,
              ),
          ]),
    );
  }

  Widget _buildMainPage() {
    if (!enableAnimation) return logic.tabs[logic.selectedTabIdx].page;

    return logic.tabs[logic.selectedTabIdx].page;
  }
}
