import 'dart:io';
import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:animetrace/routes/route_log_observer.dart';
import 'package:animetrace/widgets/device_preview_screenshot_section.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:animetrace/components/classic_refresh_style.dart';
import 'package:animetrace/controllers/backup_service.dart';
import 'package:animetrace/global.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/controllers/theme_controller.dart';
import 'package:animetrace/pages/main_screen/view.dart';
import 'package:animetrace/utils/sp_profile.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  runZonedGuardedWithLog(() async {
    await Global.init();
    runApp(
      Global.enableDevicePreview
          ? DevicePreview(
              builder: (context) => const MyApp(),
              tools: const [
                DevicePreviewScreenshotSection(),
                ...DevicePreview.defaultTools,
              ],
            )
          : const MyApp(),
    );
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
    AppLog.info("全屏");
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final themeController = Get.put(ThemeController());

  @override
  Widget build(BuildContext context) {
    return RefreshConfiguration(
      headerBuilder: () => const MyClassicHeader(),
      footerBuilder: () => const MyClassicFooter(),
      hideFooterWhenNotFull: true,
      child: Obx(() {
        return GetMaterialApp(
          home: const WindowWrapper(
            child: MainScreen(),
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
            return child;
          },
          navigatorObservers: [
            BotToastNavigatorObserver(),
            RouteLogObserver(),
          ],
          // 后台应用显示名称
          title: '漫迹',
          // 自定义滚动行为(必须放在MaterialApp，放在GetMaterialApp无效)
          scrollBehavior: MyCustomScrollBehavior(),
          // 主题
          themeMode: themeController.getThemeMode(),
          theme: _genThemeData(),
          darkTheme: _genThemeData(isDark: true),
        );
      }),
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
        TargetPlatform.iOS:
            themeController.pageSwitchAnimation.value.pageTransitionsBuilder,
        TargetPlatform.windows: const SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.horizontal,
        ),
      },
    );
  }

  ThemeData _genThemeData({bool isDark = false}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: themeController.primaryColor.value,
      brightness: isDark ? Brightness.dark : Brightness.light,
      dynamicSchemeVariant: themeController.dynamicSchemeVariant.value,
    );

    return ThemeData(
      colorScheme: colorScheme,
      cardTheme: CardTheme(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        elevation: 0,
      ),
      pageTransitionsTheme: _getPageTransitionsTheme(),
      bottomSheetTheme: const BottomSheetThemeData(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.secondaryFixed,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: TextStyle(
          color: colorScheme.onSecondaryFixed,
        ),
      ),
      fontFamilyFallback: themeController.fontFamilyFallback,
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
