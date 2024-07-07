import 'dart:io';
import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test_future/components/classic_refresh_style.dart';
import 'package:flutter_test_future/controllers/backup_service.dart';
import 'package:flutter_test_future/global.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/pages/main_screen/view.dart';
import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/values/theme.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  Global.init().then((_) => runApp(const MyApp()));
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
  FlexScheme get baseScheme => FlexScheme.blue;
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
          home: WindowWrapper(
              child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (context, child) => const MainScreen(),
          )),
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
          navigatorObservers: [BotToastNavigatorObserver()],
          // 后台应用显示名称
          title: '漫迹',
          // 自定义滚动行为(必须放在MaterialApp，放在GetMaterialApp无效)
          scrollBehavior: MyCustomScrollBehavior(),
          // 主题
          themeMode: themeController.getThemeMode(),
          theme: _getLightTheme(),
          darkTheme: _getDarkTheme(),
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

  ThemeData _getDarkTheme() {
    var dark = _getFlexThemeDataDark();
    return dark.copyWith(
      scrollbarTheme: _getScrollbarThemeData(context, isDark: true),
      cardTheme: _getCardTheme(dark),
      pageTransitionsTheme: _getPageTransitionsTheme(),
      floatingActionButtonTheme: _getFABTheme(dark),
      listTileTheme: _getListTileTheme(dark),
      dialogTheme: _getDialogTheme(dark),
    );
  }

  ThemeData _getLightTheme() {
    var light = _getFlexThemeDataLight();
    return light.copyWith(
      scrollbarTheme: _getScrollbarThemeData(context, isDark: false),
      cardTheme: _getCardTheme(light),
      pageTransitionsTheme: _getPageTransitionsTheme(),
      floatingActionButtonTheme: _getFABTheme(light),
      listTileTheme: _getListTileTheme(light),
      dialogTheme: _getDialogTheme(light),
      // 202308052321
      appBarTheme: light.appBarTheme.copyWith(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
    );
  }

  DialogTheme _getDialogTheme(ThemeData light) {
    return light.dialogTheme.copyWith(
        contentTextStyle: TextStyle(
      fontSize: 15,
      color: light.colorScheme.onSurface,
      height: 1.6,
    ));
  }

  FloatingActionButtonThemeData _getFABTheme(ThemeData themeData) {
    return FloatingActionButtonThemeData(
      backgroundColor: themeData.primaryColor,
      foregroundColor: Colors.white,
    );
  }

  CardTheme _getCardTheme(ThemeData themeData) {
    // 不在底部添加margin是为了避免相邻卡片向下间距变大
    // 在顶部添加margin是为了保证不紧挨AppBar
    return themeData.cardTheme.copyWith(
      margin: themeController.useCardStyle.value
          ? const EdgeInsets.fromLTRB(10, 10, 10, 0)
          : const EdgeInsets.only(top: 10),
      elevation: 0,
      color: themeData.brightness == Brightness.dark
          ? curDarkThemeColor.cardColor
          : curLightThemeColor.cardColor,
    );
  }

  ListTileThemeData _getListTileTheme(ThemeData themeData) {
    return ListTileThemeData(
      titleTextStyle: themeData.textTheme.bodyMedium,
      subtitleTextStyle: themeData.textTheme.bodySmall,
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
        // TargetPlatform.windows:
        //     themeController.pageSwitchAnimation.value.pageTransitionsBuilder,
      },
    );
  }

  ThemeData _getFlexThemeDataDark() {
    return FlexThemeData.dark(
      scheme: baseScheme,
      useMaterial3: themeController.useM3.value,
      textTheme: _getTextTheme(textStyle, context),
      primary: themeController.customPrimaryColor.value ??
          curDarkThemeColor.primaryColor,
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
        // chip颜色
        chipSchemeColor: SchemeColor.outlineVariant,
        chipSelectedSchemeColor: SchemeColor.inversePrimary,
        // 悬浮、按压等颜色不受主颜色影响
        interactionEffects: false,
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
        textButtonRadius: AppTheme.textButtonRadius,
        splashType: FlexSplashType.defaultSplash,
        elevatedButtonElevation: 0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
    );
  }

  ThemeData _getFlexThemeDataLight() {
    return FlexThemeData.light(
      scheme: baseScheme,
      useMaterial3: themeController.useM3.value,
      textTheme: _getTextTheme(textStyle, context),
      primary: themeController.customPrimaryColor.value ??
          curLightThemeColor.primaryColor,
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
        // chip颜色
        chipSchemeColor: SchemeColor.outlineVariant,
        chipSelectedSchemeColor: SchemeColor.inversePrimary,
        // 悬浮、按压等颜色不受主颜色影响
        interactionEffects: false,
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
        textButtonRadius: AppTheme.textButtonRadius,
        splashType: FlexSplashType.inkRipple,
        elevatedButtonElevation: 0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
    );
  }

  ScrollbarThemeData _getScrollbarThemeData(BuildContext context,
      {bool isDark = false}) {
    return ScrollbarThemeData(
      trackVisibility: MaterialStateProperty.all(true),
      // 粗细
      thickness: MaterialStateProperty.all(5),
      interactive: true,
      radius: const Radius.circular(10),
      thumbColor: MaterialStateProperty.all(
        isDark ? Colors.white.withOpacity(0.4) : Colors.black38,
      ),
    );
  }

  TextTheme _getTextTheme(TextStyle textStyle, BuildContext context) {
    return TextTheme(
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
}
