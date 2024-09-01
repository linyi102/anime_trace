import 'dart:io';
import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
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
            return Theme(
              data: _getFixedTheme(context),
              child: child,
            );
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
      iconTheme: theme.iconTheme.copyWith(color: iconColor),
      scrollbarTheme: _getScrollbarThemeData(context, isDark: isDark),
      // 不在底部添加margin是为了避免相邻卡片向下间距变大
      // 在顶部添加margin是为了保证不紧挨AppBar
      cardTheme: theme.cardTheme.copyWith(
        margin: themeController.useCardStyle.value
            ? const EdgeInsets.fromLTRB(10, 10, 10, 0)
            : const EdgeInsets.only(top: 10),
        elevation: 0,
        color:
            isDark ? curDarkThemeColor.cardColor : curLightThemeColor.cardColor,
      ),
      pageTransitionsTheme: _getPageTransitionsTheme(),
      floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      chipTheme: theme.chipTheme.copyWith(side: BorderSide.none),
      // 202308052321
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle:
            Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
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
    final primary = themeController.customPrimaryColor.value ??
        curLightThemeColor.primaryColor;

    return FlexThemeData.light(
      scheme: baseScheme,
      useMaterial3: themeController.useM3.value,
      fontFamilyFallback: textStyle.fontFamilyFallback,
      primary: primary,
      primaryContainer: primary.withOpacity(0.6),
      tertiaryContainer: primary.withOpacity(0.4),
      scaffoldBackground: curLightThemeColor.bodyColor,
      surface: curLightThemeColor.cardColor,
      // BottomNavigationBar
      background: curLightThemeColor.appBarColor,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 9,
      tabBarStyle: FlexTabBarStyle.forBackground,
      appBarBackground: curLightThemeColor.appBarColor,
      appBarStyle: FlexAppBarStyle.scaffoldBackground,
      tooltipsMatchBackground: true,
      subThemesData: FlexSubThemesData(
        // chip颜色
        chipSchemeColor: SchemeColor.primaryContainer,
        chipSelectedSchemeColor: SchemeColor.primary,
        useM2StyleDividerInM3: true,
        // 悬浮、按压等颜色不受主颜色影响
        interactionEffects: false,
        useTextTheme: true,
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
        splashType: FlexSplashType.inkSparkle,
        elevatedButtonElevation: 2.0,
        elevatedButtonSchemeColor: SchemeColor.onPrimary,
        elevatedButtonSecondarySchemeColor: SchemeColor.primary,
        // 对话框背景色
        dialogElevation: 0.0,
        // 滚动时AppBar背景色
        appBarScrolledUnderElevation: 0.0,
        // 底部面板背景色
        bottomSheetElevation: 0.0,
        bottomSheetModalElevation: 0.0,
        tabBarDividerColor: Colors.transparent,
        outlinedButtonOutlineSchemeColor: SchemeColor.primary,
        popupMenuElevation: 1,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
    );
  }

  ThemeData _getFlexThemeDataDark() {
    final primary = themeController.customPrimaryColor.value ??
        curDarkThemeColor.primaryColor;

    return FlexThemeData.dark(
      scheme: baseScheme,
      useMaterial3: themeController.useM3.value,
      fontFamilyFallback: textStyle.fontFamilyFallback,
      primary: primary,
      primaryContainer: primary.withOpacity(0.6),
      tertiaryContainer: primary.withOpacity(0.4),
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
        chipSchemeColor: SchemeColor.primaryContainer,
        chipSelectedSchemeColor: SchemeColor.tertiaryContainer,
        // 悬浮、按压等颜色不受主颜色影响
        interactionEffects: false,
        useTextTheme: true,
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
        splashType: FlexSplashType.inkSparkle,
        elevatedButtonElevation: 2.0,
        elevatedButtonSchemeColor: SchemeColor.onPrimary,
        elevatedButtonSecondarySchemeColor: SchemeColor.primary,
        // 对话框背景色
        dialogElevation: 0.0,
        // 滚动时AppBar背景色
        appBarScrolledUnderElevation: 0.0,
        // 底部面板背景色
        bottomSheetElevation: 0.0,
        bottomSheetModalElevation: 0.0,
        tabBarDividerColor: Colors.transparent,
        outlinedButtonOutlineSchemeColor: SchemeColor.primary,
        popupMenuElevation: 1,
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
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Enable scrolling with mouse dragging
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
