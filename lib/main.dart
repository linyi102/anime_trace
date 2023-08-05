import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_test_future/components/classic_refresh_style.dart';
import 'package:flutter_test_future/controllers/backup_service.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/pages/main_screen/main_screen.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/values/theme.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  Global.init().then((_) => runApp(_getMaterialApp()));
}

GetMaterialApp _getMaterialApp() {
  return const GetMaterialApp(
    // GetMaterialApp必须放在这里，而不能在MyApp的build返回GetMaterialApp，否则导致Windows端无法关闭
    home: MyApp(),
    debugShowCheckedModeBanner: false,
    // 中文(必须放在GetMaterialApp)
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [
      Locale('zh', 'CN'),
      Locale('en', 'US'),
    ],
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WindowListener {
  // StatefulWidget才有initState和dispose
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
      });
    }
  }

  @override
  void onWindowMaximize() async {
    Log.info("全屏");
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.put(ThemeController());

    return Obx(
      () {
        TextStyle textStyle = TextStyle(
          fontFamilyFallback: themeController.fontFamilyFallback,
        );

        var curLightThemeColor = themeController.lightThemeColor.value;
        var baseScheme = FlexScheme.blue;
        var light = FlexThemeData.light(
          scheme: baseScheme,
          useMaterial3: themeController.useM3.value,
          textTheme: _buildTextTheme(textStyle, context),
          primary: curLightThemeColor.primaryColor,
          scaffoldBackground: curLightThemeColor.bodyColor,
          surface: curLightThemeColor.cardColor,
          // BottomNavigationBar
          background: curLightThemeColor.appBarColor,
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 9,
          tabBarStyle: FlexTabBarStyle.forBackground,
          // 亮色模式下不管设置哪个，都会导致看不见手机状态栏(暗色模式正常)
          // 解决方式：该代码文件中搜索202308052321
          appBarBackground: curLightThemeColor.appBarColor,
          appBarStyle: FlexAppBarStyle.scaffoldBackground,
          tooltipsMatchBackground: true,
          subThemesData: FlexSubThemesData(
            // true会导致AppBar的title字体有些大
            useTextTheme: false,
            // true会导致文字和按钮颜色受主色影响
            blendTextTheme: false,
            // 隐藏输入框底部边界
            inputDecoratorUnfocusedHasBorder: false,
            blendOnLevel: 10,
            blendOnColors: false,
            inputDecoratorIsFilled: false,
            inputDecoratorBorderType: FlexInputBorderType.underline,
            bottomSheetRadius: AppTheme.bottomSheetRadius,
            cardRadius:
                themeController.useCardStyle.value ? AppTheme.cardRadius : 0,
            chipRadius: AppTheme.chipRadius,
            dialogRadius: AppTheme.dialogRadius,
            timePickerDialogRadius: AppTheme.timePickerDialogRadius,
            popupMenuRadius: 8.0,
            splashType: FlexSplashType.inkRipple,
          ),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
        );

        var curDarkThemeColor = themeController.darkThemeColor.value;
        var dark = FlexThemeData.dark(
          scheme: baseScheme,
          useMaterial3: themeController.useM3.value,
          textTheme: _buildTextTheme(textStyle, context),
          primary: curDarkThemeColor.primaryColor,
          scaffoldBackground: curDarkThemeColor.bodyColor,
          surface: curDarkThemeColor.cardColor,
          // BottomNavigationBar
          background: curDarkThemeColor.appBarColor,
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 15,
          tabBarStyle: FlexTabBarStyle.forBackground,
          appBarBackground: curDarkThemeColor.appBarColor,
          appBarStyle: FlexAppBarStyle.scaffoldBackground,
          tooltipsMatchBackground: true,
          subThemesData: FlexSubThemesData(
            // true会导致AppBar的title字体有些大
            useTextTheme: false,
            // true会导致文字和按钮颜色受主色影响
            blendTextTheme: false,
            // 隐藏输入框底部边界
            inputDecoratorUnfocusedHasBorder: false,
            blendOnLevel: 20,
            inputDecoratorIsFilled: false,
            inputDecoratorBorderType: FlexInputBorderType.underline,
            bottomSheetRadius: AppTheme.bottomSheetRadius,
            cardRadius:
                themeController.useCardStyle.value ? AppTheme.cardRadius : 0,
            chipRadius: AppTheme.chipRadius,
            dialogRadius: AppTheme.dialogRadius,
            timePickerDialogRadius: AppTheme.timePickerDialogRadius,
            popupMenuRadius: 8.0,
            splashType: FlexSplashType.defaultSplash,
          ),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
        );

        return RefreshConfiguration(
          headerBuilder: () => const MyClassicHeader(),
          footerBuilder: () => const MyClassicFooter(),
          hideFooterWhenNotFull: true,
          child: MaterialApp(
            themeMode: themeController.getThemeMode(),
            // theme: ThemeData.light().copyWith(
            //   dialogTheme: DialogTheme(
            //       shape: RoundedRectangleBorder(
            //           borderRadius:
            //               BorderRadius.circular(AppTheme.dialogRadius))),
            //   appBarTheme: AppBarTheme(
            //     backgroundColor: curLightThemeColor.appBarColor,
            //     foregroundColor: Colors.black,
            //     elevation: 0,
            //   ),
            //   cardTheme: CardTheme(
            //     elevation: 0,
            //     shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
            //   ),
            //   outlinedButtonTheme: OutlinedButtonThemeData(
            //     style: ButtonStyle(
            //         shape: MaterialStatePropertyAll(RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(99)))),
            //   ),
            // ),
            theme: light.copyWith(
              scrollbarTheme: _buildScrollbarThemeData(context, isDark: false),
              // 使用Theme.of(context).cardTheme会丢失FlexThemeData.light的圆角
              cardTheme: light.cardTheme.copyWith(
                // 不在底部添加margin是为了避免相邻卡片向下间距变大
                // 在顶部添加margin是为了保证不紧挨AppBar
                margin: themeController.useCardStyle.value
                    ? const EdgeInsets.fromLTRB(10, 10, 10, 0)
                    : const EdgeInsets.only(top: 10),
                elevation: 0,
              ),
              // 路由动画
              pageTransitionsTheme: PageTransitionsTheme(
                builders: <TargetPlatform, PageTransitionsBuilder>{
                  TargetPlatform.android: themeController
                      .pageSwitchAnimation.value.pageTransitionsBuilder,
                  TargetPlatform.windows: themeController
                      .pageSwitchAnimation.value.pageTransitionsBuilder,
                },
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: light.primaryColor,
                foregroundColor: Colors.white,
              ),
              listTileTheme: ListTileThemeData(
                // iconColor: light.iconTheme.color?.withOpacity(0.6),
                iconColor: light.hintColor,
                titleTextStyle: light.textTheme.bodyMedium,
                subtitleTextStyle: light.textTheme.bodySmall,
              ),
              // 202308052321
              appBarTheme: light.appBarTheme.copyWith(
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                ),
              ),
            ),
            darkTheme: dark.copyWith(
                scrollbarTheme: _buildScrollbarThemeData(context, isDark: true),
                cardTheme: dark.cardTheme.copyWith(
                  margin: themeController.useCardStyle.value
                      ? const EdgeInsets.fromLTRB(10, 10, 10, 0)
                      : const EdgeInsets.only(top: 10),
                  elevation: 0,
                ),
                // 路由动画
                pageTransitionsTheme: PageTransitionsTheme(
                  builders: <TargetPlatform, PageTransitionsBuilder>{
                    TargetPlatform.android: themeController
                        .pageSwitchAnimation.value.pageTransitionsBuilder,
                    TargetPlatform.windows: themeController
                        .pageSwitchAnimation.value.pageTransitionsBuilder,
                  },
                ),
                floatingActionButtonTheme: FloatingActionButtonThemeData(
                  backgroundColor: dark.primaryColor,
                  foregroundColor: Colors.white,
                ),
                listTileTheme: ListTileThemeData(
                  // iconColor: dark.iconTheme.color?.withOpacity(0.6),
                  iconColor: dark.hintColor,
                )),
            builder: (context, child) {
              child = BotToastInit()(context, child);
              // 全局点击空白处隐藏软键盘
              child = Scaffold(
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
              return child;
            },
            navigatorObservers: [BotToastNavigatorObserver()],
            home: const MainScreen(),
            // 后台应用显示名称
            title: '漫迹',
            // 去除右上角的debug标签
            debugShowCheckedModeBanner: false,
            // 自定义滚动行为(必须放在MaterialApp，放在GetMaterialApp无效)
            scrollBehavior: MyCustomScrollBehavior(),
          ),
        );
      },
    );
  }

  ScrollbarThemeData _buildScrollbarThemeData(BuildContext context,
      {bool isDark = false}) {
    return ScrollbarThemeData(
      trackVisibility: MaterialStateProperty.all(true),
      thickness: MaterialStateProperty.all(5),
      interactive: true,
      radius: const Radius.circular(10),
      thumbColor: MaterialStateProperty.all(
        isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4),
      ),
    );
  }

  TextTheme _buildTextTheme(TextStyle textStyle, BuildContext context) {
    return TextTheme(
      // ListTile标题
      // titleMedium: textStyle.copyWith(
      //     fontSize: Theme.of(context).textTheme.titleSmall?.fontSize),
      // 按钮里的文字
      labelLarge: textStyle,
      // 底部tab，ListTile副标题
      bodyMedium: textStyle,
      // Text
      bodyLarge: textStyle,
      // AppBar里的title
      titleLarge: textStyle,
      // 未知
      titleSmall: textStyle,
      labelSmall: textStyle,
      bodySmall: textStyle,
      displayLarge: textStyle,
      displayMedium: textStyle,
      displaySmall: textStyle,
      headlineMedium: textStyle,
      headlineSmall: textStyle,
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

  // @override
  // ScrollPhysics getScrollPhysics(BuildContext context) {
  //   // 回弹效果
  //   // return const BouncingScrollPhysics();
  //   // 边界停止
  //   return const ClampingScrollPhysics();
  // }

  // 滚动到边界时的效果
  // Windows端和聚合搜索页左右滑动会报错
  // 'package:flutter/src/widgets/overscroll_indicator.dart': Failed assertion: line 243 pos 14: 'notification.metrics.axis == widget.axis': is not true.
  // 因此这里注释掉
  // @override
  // Widget buildOverscrollIndicator(
  //     BuildContext context, Widget child, ScrollableDetails details) {
  //   // 拉伸
  //   // return StretchingOverscrollIndicator(
  //   //   child: child,
  //   //   axisDirection: details.direction,
  //   // );

  //   // 发光
  //   return GlowingOverscrollIndicator(
  //     axisDirection: details.direction,
  //     color: Theme.of(context).colorScheme.secondary,
  //     child: child,
  //   );
  // }
}
