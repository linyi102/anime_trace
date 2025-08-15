import 'dart:io';
import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_logkit/logkit.dart';
import 'package:animetrace/components/classic_refresh_style.dart';
import 'package:animetrace/controllers/backup_service.dart';
import 'package:animetrace/global.dart';
import 'package:animetrace/utils/extensions/color.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/controllers/theme_controller.dart';
import 'package:animetrace/pages/main_screen/view.dart';
import 'package:animetrace/utils/sp_profile.dart';
import 'package:animetrace/values/theme.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  runLogkitZonedGuarded(logger, () async {
    await Global.init();
    runApp(const MyApp());
  });
}

class WindowWrapper extends StatefulWidget {
  const WindowWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<WindowWrapper> createState() => _WindowWrapperState();
}

class _WindowWrapperState extends State<WindowWrapper> with WindowListener {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();

    // 还原最新备份、开启间隔备份
    BackupService.to.startService();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _init() async {
    // Add this line to override the default close handler
    if (Platform.isWindows) await windowManager.setPreventClose(true);
    setState(() {});
  }

  @override
  void onWindowResize() async {}

  @override
  void onWindowClose() async {
    // Windows端点击右上角的关闭按钮时会调用此处，Android端不会
    bool _isPreventClose = await windowManager.isPreventClose();
    if (_isPreventClose) {
      // 如果开启了退出app前备份，那么先备份，如果备份成功则退出app
      // 备份失败则进行提示，让用户决定重试或者退出app
      BackupService.to.tryBackupBeforeExitApp(exitApp: () async {
        // 关闭窗口前等待记录窗口大小完毕
        await SpProfile.setWindowSize(await windowManager.getSize());
        // 退出
        Navigator.of(context).pop();
        await windowManager.destroy();
        exit(0);
      });
    }
  }

  @override
  void onWindowMaximize() async {
    Log.info("全屏");
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final ThemeController themeController = Get.put(ThemeController());
  TextStyle get textStyle =>
      TextStyle(fontFamilyFallback: themeController.fontFamilyFallback);
  ThemeColor get curLightThemeColor => themeController.lightThemeColor.value;
  ThemeColor get curDarkThemeColor => themeController.darkThemeColor.value;

  @override
  Widget build(BuildContext context) {
    return RefreshConfiguration(
      headerBuilder: () => const MyClassicHeader(),
      footerBuilder: () => const MyClassicFooter(),
      hideFooterWhenNotFull: true,
      child: Obx(() {
        return GetMaterialApp(
          home: LogkitOverlayAttacher(
            logger: logger,
            child: const WindowWrapper(
              child: MainScreen(),
            ),
          ),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
          builder: (context, child) {
            child = BotToastInit()(context, child);
            // 全局点击空白处隐藏软键盘
            child = _buildScaffoldWithHideKeyboardByClickBlank(context, child);
            return Obx(() => Theme(
                  data: _getFixedTheme(context),
                  child: child ?? const SizedBox(),
                ));
          },
          navigatorObservers: [BotToastNavigatorObserver()],
          // 后台应用显示名称
          title: '漫迹',
          // 自定义滚动行为(必须放在MaterialApp，放在GetMaterialApp无效)
          scrollBehavior: MyCustomScrollBehavior(),
          // 主题
          themeMode: themeController.getThemeMode(),
          theme: _getFlexThemeDataLight(),
          darkTheme: _getFlexThemeDataDark(),
        );
      }),
    );
  }

  ThemeData _getFixedTheme(BuildContext context) {
    final isDark = Global.isDark(context);
    final theme = Theme.of(context);
    final iconColor = isDark
        ? const Color.fromRGBO(169, 169, 169, 1)
        : const Color.fromRGBO(60, 60, 60, 1);

    return theme.copyWith(
      listTileTheme: theme.listTileTheme.copyWith(
        titleTextStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
        subtitleTextStyle: theme.textTheme.bodySmall
            ?.copyWith(fontSize: 13, color: Theme.of(context).hintColor),
        iconColor: iconColor,
      ),
      scrollbarTheme: _getScrollbarThemeData(context, isDark: isDark),
      // 不在底部添加margin是为了避免相邻卡片向下间距变大
      // 在顶部添加margin是为了保证不紧挨AppBar
      cardTheme: theme.cardTheme.copyWith(
        margin: themeController.useCardStyle.value
            ? const EdgeInsets.fromLTRB(10, 10, 10, 0)
            : const EdgeInsets.only(top: 10),
        elevation: 0,
      ),
      pageTransitionsTheme: _getPageTransitionsTheme(),
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle:
            Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
      ),
      switchTheme: SwitchThemeData(
        thumbIcon:
            WidgetStateProperty.resolveWith<Icon?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return Icon(Icons.check, color: theme.primaryColor);
          }
          return null;
        }),
      ),
      textTheme: theme.textTheme.copyWith(
        bodySmall: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
      ),
    );
  }

  Scaffold _buildScaffoldWithHideKeyboardByClickBlank(
      BuildContext context, Widget child) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus &&
              currentFocus.focusedChild != null) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: child,
      ),
    );
  }

  PageTransitionsTheme _getPageTransitionsTheme() {
    return PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android:
            themeController.pageSwitchAnimation.value.pageTransitionsBuilder,
        TargetPlatform.windows: const SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.horizontal,
        ),
      },
    );
  }

  ThemeData _getFlexThemeDataLight() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent, brightness: Brightness.light),
      useMaterial3: themeController.useM3.value,
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ThemeData _getFlexThemeDataDark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent, brightness: Brightness.dark),
      useMaterial3: themeController.useM3.value,
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ScrollbarThemeData _getScrollbarThemeData(BuildContext context,
      {bool isDark = false}) {
    return ScrollbarThemeData(
      trackVisibility: WidgetStateProperty.all(true),
      // 粗细
      thickness: WidgetStateProperty.all(5),
      interactive: true,
      radius: const Radius.circular(10),
      thumbColor: WidgetStateProperty.all(
        isDark ? Colors.white.withOpacityFactor(0.4) : Colors.black38,
      ),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Enable scrolling with mouse dragging
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
