import 'dart:io';
import 'dart:ui';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_test_future/components/classic_refresh_style.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/utils/log.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/pages/main_screen/main_screen.dart';
import 'package:flutter_test_future/utils/backup_util.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/webdav_util.dart';
import 'package:flutter_test_future/values/theme.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:window_manager/window_manager.dart';

import 'components/update_hint.dart';

void main() {
  Global.init().then((_) => runApp(_getMaterialApp()));
}

GetMaterialApp _getMaterialApp() {
  return const GetMaterialApp(
    // GetMaterialApp必须放在这里，而不能在MyApp的build返回GetMaterialApp，否则导致Windows端无法关闭
    home: MyApp(),
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
    _autoBackup();
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
    bool _isPreventClose = await windowManager.isPreventClose();
    if (_isPreventClose) {
      // 关闭窗口前等待记录窗口大小完毕
      await SpProfile.setWindowSize(await windowManager.getSize());
      // 退出
      Navigator.of(context).pop();
      await windowManager.destroy();
    }
  }

  @override
  void onWindowMaximize() async {
    Log.info("全屏");
  }

  _autoBackup() async {
    // 之前登录过，因为关闭应用会导致连接关闭，所以下次重启应用时需要再次连接
    if (SPUtil.getBool("login")) {
      await WebDavUtil.initWebDav(
        SPUtil.getString("webdav_uri"),
        SPUtil.getString("webdav_user"),
        SPUtil.getString("webdav_password"),
      );
    }
    // 如果都设置了自动备份，则只需要压缩一次
    if (SPUtil.getBool("auto_backup_local") &&
        SPUtil.getBool("auto_backup_webdav")) {
      Log.info("准备本地和WebDav自动备份");
      BackupUtil.backup(
        localBackupDirPath:
            SPUtil.getString("backup_local_dir", defaultValue: "unset"),
        remoteBackupDirPath: await WebDavUtil.getRemoteDirPath(),
        showToastFlag: false,
        automatic: true,
      );
    } else if (SPUtil.getBool("auto_backup_local")) {
      Log.info("准备本地自动备份");
      BackupUtil.backup(
        localBackupDirPath:
            SPUtil.getString("backup_local_dir", defaultValue: "unset"),
        showToastFlag: false,
        automatic: true,
      );
    } else if (SPUtil.getBool("auto_backup_webdav")) {
      Log.info("准备WebDav自动备份");
      BackupUtil.backup(
        remoteBackupDirPath: await WebDavUtil.getRemoteDirPath(),
        showToastFlag: false,
        automatic: true,
      );
      // String lastTimeBackup = SPUtil.getString("last_time_backup");
      // // 不为空串表示之前备份过
      // if (lastTimeBackup != "") {
      //   Log.info("上次备份的时间：$lastTimeBackup");
      //   DateTime dateTime = DateTime.parse(lastTimeBackup);
      //   DateTime now = DateTime.now();
      //   // 距离上次备份超过1天，则进行备份
      //   // if (now.difference(dateTime).inSeconds >= 10) {
      //   if (now.difference(dateTime).inDays >= 1) {
      //     // WebDavUtil.backupData(true);
      //   }
      // }
    }
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
          primary: curLightThemeColor.primaryColor,
          appBarBackground: curLightThemeColor.appBarColor,
          scaffoldBackground: curLightThemeColor.bodyColor,
          surface: curLightThemeColor.cardColor,
          textTheme: _buildTextTheme(textStyle, context),
          // BottomNavigationBar
          background: curLightThemeColor.appBarColor,
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 9,
          tabBarStyle: FlexTabBarStyle.forBackground,
          tooltipsMatchBackground: true,
          subThemesData: const FlexSubThemesData(
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
            cardRadius: AppTheme.cardRadius,
            chipRadius: AppTheme.chipRadius,
            dialogRadius: AppTheme.dialogRadius,
            timePickerDialogRadius: AppTheme.timePickerDialogRadius,
          ),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          // To use the playground font, add GoogleFonts package and uncomment
          // fontFamily: GoogleFonts.notoSans().fontFamily,
        );

        var curDarkThemeColor = themeController.darkThemeColor.value;
        var dark = FlexThemeData.dark(
          scheme: baseScheme,
          primary: curDarkThemeColor.primaryColor,
          appBarBackground: curDarkThemeColor.appBarColor,
          scaffoldBackground: curDarkThemeColor.bodyColor,
          surface: curDarkThemeColor.cardColor,
          // BottomNavigationBar
          background: curDarkThemeColor.appBarColor,
          textTheme: _buildTextTheme(textStyle, context),
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          tooltipsMatchBackground: true,
          blendLevel: 15,
          tabBarStyle: FlexTabBarStyle.forBackground,
          subThemesData: const FlexSubThemesData(
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
            cardRadius: AppTheme.cardRadius,
            chipRadius: AppTheme.chipRadius,
            dialogRadius: AppTheme.dialogRadius,
            timePickerDialogRadius: AppTheme.timePickerDialogRadius,
          ),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
        );

        return OKToast(
          position: ToastPosition.bottom,
          animationDuration: const Duration(milliseconds: 200),
          animationBuilder: (BuildContext context, Widget child,
              AnimationController controller, double percent) {
            Animation<double> animation = CurvedAnimation(
              parent: controller,
              curve: Curves.ease,
            );

            return ScaleTransition(
                alignment: Alignment.bottomCenter,
                child: child,
                scale: animation);
          },
          // true表示弹出消息时会先关闭前一个消息
          dismissOtherOnShow: true,
          radius: 10,
          textPadding: const EdgeInsets.all(8),
          backgroundColor: Colors.white,
          textStyle: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.normal,
              decoration: TextDecoration.none,
              fontFamilyFallback: themeController.fontFamilyFallback),
          child: RefreshConfiguration(
            headerBuilder: () => const MyClassicHeader(),
            footerBuilder: () => const MyClassicFooter(),
            hideFooterWhenNotFull: true,
            child: MaterialApp(
              themeMode: themeController.getThemeMode(),
              theme: light.copyWith(
                scrollbarTheme:
                    _buildScrollbarThemeData(context, isDark: false),
                // 使用Theme.of(context).cardTheme会丢失FlexThemeData.light的圆角
                cardTheme: light.cardTheme.copyWith(
                  // 不在底部添加margin是为了避免相邻卡片向下间距变大
                  // 在顶部添加margin是为了保证不紧挨AppBar
                  margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  elevation: 0,
                ), // 路由动画
                pageTransitionsTheme: PageTransitionsTheme(
                  builders: <TargetPlatform, PageTransitionsBuilder>{
                    TargetPlatform.android: themeController
                        .pageSwitchAnimation.value.pageTransitionsBuilder,
                    TargetPlatform.windows: themeController
                        .pageSwitchAnimation.value.pageTransitionsBuilder,
                  },
                ),
              ),
              // darkTheme: AppTheme.dark,
              darkTheme: dark.copyWith(
                scrollbarTheme: _buildScrollbarThemeData(context, isDark: true),
                cardTheme: dark.cardTheme.copyWith(
                  margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  elevation: 0,
                ), // 路由动画
                pageTransitionsTheme: PageTransitionsTheme(
                  builders: <TargetPlatform, PageTransitionsBuilder>{
                    TargetPlatform.android: themeController
                        .pageSwitchAnimation.value.pageTransitionsBuilder,
                    TargetPlatform.windows: themeController
                        .pageSwitchAnimation.value.pageTransitionsBuilder,
                  },
                ),
              ),

              home: _buildHome(),
              // 后台应用显示名称
              title: '漫迹',
              // 去除右上角的debug标签
              debugShowCheckedModeBanner: false,
              // 自定义滚动行为(必须放在MaterialApp，放在GetMaterialApp无效)
              scrollBehavior: MyCustomScrollBehavior(),
            ),
          ),
        );
      },
    );
  }

  Stack _buildHome() {
    return Stack(
      children: const [
        MainScreen(),
        UpdateHint(checkLatestVersion: true),
      ],
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
      subtitle1: textStyle.copyWith(
          fontSize: Theme.of(context).textTheme.subtitle2?.fontSize),
      // 按钮里的文字
      button: textStyle,
      // 底部tab，ListTile副标题
      bodyText2: textStyle,
      // Text
      bodyText1: textStyle,
      // AppBar里的title
      headline6: textStyle,
      // 未知
      subtitle2: textStyle,
      overline: textStyle,
      caption: textStyle,
      headline1: textStyle,
      headline2: textStyle,
      headline3: textStyle,
      headline4: textStyle,
      headline5: textStyle,
    );
  }
}

// Enable scrolling with mouse dragging
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
