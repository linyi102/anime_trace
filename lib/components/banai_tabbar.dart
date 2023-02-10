import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;

typedef OnChange = void Function(int index);
typedef OnAnimatedChange = void Function(
    double animateValue, double diff, int currentIndex, int nextInddex);

class BanaiTabbar extends StatefulWidget {
  const BanaiTabbar({
    Key? key,
    required this.tabs,
    required this.controller,
    required this.labelFontSize,
    this.onChange,
    this.onAnimatedChange,
    this.isScrollable = false,
    this.indicatorColor,
    this.automaticIndicatorColorAdjustment = true,
    this.indicatorWeight = 2.0,
    this.indicatorPadding = EdgeInsets.zero,
    this.indicator,
    this.indicatorSize,
    this.labelColor,
    this.labelStyle,
    this.labelPadding,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
    this.dragStartBehavior = DragStartBehavior.start,
    this.overlayColor,
    this.mouseCursor,
    this.enableFeedback,
    this.onTap,
    this.physics,
  })  :
        // ignore: unnecessary_null_comparison
        assert(indicator != null || (indicatorWeight > 0.0)),
        // ignore: unnecessary_null_comparison
        assert(indicator != null || (indicatorPadding != null)),
        super(key: key);

  /// Typically a list of two or more [Tab] widgets.
  ///
  /// The length of this list must match the [controller]'s [TabController.length]
  /// and the length of the [TabBarView.children] list.
  final List<Widget> tabs;

  /// This widget's selection and animation state.
  ///
  /// If [TabController] is not provided, then the value of [DefaultTabController.of]
  /// will be used.
  final TabController? controller;

  final double labelFontSize;

  final OnChange? onChange;

  final OnAnimatedChange? onAnimatedChange;

  /// Whether this tab bar can be scrolled horizontally.
  ///
  /// If [isScrollable] is true, then each tab is as wide as needed for its label
  /// and the entire [TabBar] is scrollable. Otherwise each tab gets an equal
  /// share of the available space.
  final bool isScrollable;

  /// The color of the line that appears below the selected tab.
  ///
  /// If this parameter is null, then the value of the Theme's indicatorColor
  /// property is used.
  ///
  /// If [indicator] is specified or provided from [TabBarTheme],
  /// this property is ignored.
  final Color? indicatorColor;

  /// The thickness of the line that appears below the selected tab.
  ///
  /// The value of this parameter must be greater than zero and its default
  /// value is 2.0.
  ///
  /// If [indicator] is specified or provided from [TabBarTheme],
  /// this property is ignored.
  final double indicatorWeight;

  /// Padding for indicator.
  /// This property will now no longer be ignored even if indicator is declared
  /// or provided by [TabBarTheme]
  ///
  /// For [isScrollable] tab bars, specifying [kTabLabelPadding] will align
  /// the indicator with the tab's text for [Tab] widgets and all but the
  /// shortest [Tab.text] values.
  ///
  /// The default value of [indicatorPadding] is [EdgeInsets.zero].
  final EdgeInsetsGeometry indicatorPadding;

  /// Defines the appearance of the selected tab indicator.
  ///
  /// If [indicator] is specified or provided from [TabBarTheme],
  /// the [indicatorColor], and [indicatorWeight] properties are ignored.
  ///
  /// The default, underline-style, selected tab indicator can be defined with
  /// [UnderlineTabIndicator].
  ///
  /// The indicator's size is based on the tab's bounds. If [indicatorSize]
  /// is [TabBarIndicatorSize.tab] the tab's bounds are as wide as the space
  /// occupied by the tab in the tab bar. If [indicatorSize] is
  /// [TabBarIndicatorSize.label], then the tab's bounds are only as wide as
  /// the tab widget itself.
  final Decoration? indicator;

  /// Whether this tab bar should automatically adjust the [indicatorColor].
  ///
  /// If [automaticIndicatorColorAdjustment] is true,
  /// then the [indicatorColor] will be automatically adjusted to [Colors.white]
  /// when the [indicatorColor] is same as [Material.color] of the [Material] parent widget.
  final bool automaticIndicatorColorAdjustment;

  /// Defines how the selected tab indicator's size is computed.
  ///
  /// The size of the selected tab indicator is defined relative to the
  /// tab's overall bounds if [indicatorSize] is [TabBarIndicatorSize.tab]
  /// (the default) or relative to the bounds of the tab's widget if
  /// [indicatorSize] is [TabBarIndicatorSize.label].
  ///
  /// The selected tab's location appearance can be refined further with
  /// the [indicatorColor], [indicatorWeight], [indicatorPadding], and
  /// [indicator] properties.
  final TabBarIndicatorSize? indicatorSize;

  /// The color of selected tab labels.
  ///
  /// Unselected tab labels are rendered with the same color rendered at 70%
  /// opacity unless [unselectedLabelColor] is non-null.
  ///
  /// If this parameter is null, then the color of the [ThemeData.primaryTextTheme]'s
  /// bodyText1 text color is used.
  final Color? labelColor;

  /// The color of unselected tab labels.
  ///
  /// If this property is null, unselected tab labels are rendered with the
  /// [labelColor] with 70% opacity.
  final Color? unselectedLabelColor;

  /// The text style of the selected tab labels.
  ///
  /// If [unselectedLabelStyle] is null, then this text style will be used for
  /// both selected and unselected label styles.
  ///
  /// If this property is null, then the text style of the
  /// [ThemeData.primaryTextTheme]'s bodyText1 definition is used.
  final TextStyle? labelStyle;

  /// The padding added to each of the tab labels.
  ///
  /// If this property is null, then kTabLabelPadding is used.
  final EdgeInsetsGeometry? labelPadding;

  /// The text style of the unselected tab labels.
  ///
  /// If this property is null, then the [labelStyle] value is used. If [labelStyle]
  /// is null, then the text style of the [ThemeData.primaryTextTheme]'s
  /// bodyText1 definition is used.
  final TextStyle? unselectedLabelStyle;

  /// Defines the ink response focus, hover, and splash colors.
  ///
  /// If non-null, it is resolved against one of [MaterialState.focused],
  /// [MaterialState.hovered], and [MaterialState.pressed].
  ///
  /// [MaterialState.pressed] triggers a ripple (an ink splash), per
  /// the current Material Design spec. The [overlayColor] doesn't map
  /// a state to [InkResponse.highlightColor] because a separate highlight
  /// is not used by the current design guidelines. See
  /// https://material.io/design/interaction/states.html#pressed
  ///
  /// If the overlay color is null or resolves to null, then the default values
  /// for [InkResponse.focusColor], [InkResponse.hoverColor], [InkResponse.splashColor]
  /// will be used instead.
  final MaterialStateProperty<Color?>? overlayColor;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// individual tab widgets.
  ///
  /// If this property is null, [SystemMouseCursors.click] will be used.
  final MouseCursor? mouseCursor;

  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a long-press
  /// will produce a short vibration, when feedback is enabled.
  ///
  /// Defaults to true.
  final bool? enableFeedback;

  /// An optional callback that's called when the [TabBar] is tapped.
  ///
  /// The callback is applied to the index of the tab where the tap occurred.
  ///
  /// This callback has no effect on the default handling of taps. It's for
  /// applications that want to do a little extra work when a tab is tapped,
  /// even if the tap doesn't change the TabController's index. TabBar [onTap]
  /// callbacks should not make changes to the TabController since that would
  /// interfere with the default tap handler.
  final ValueChanged<int>? onTap;

  /// How the [TabBar]'s scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? physics;

  @override
  _BanaiTabbarState createState() => _BanaiTabbarState();
}

class _BanaiTabbarState extends State<BanaiTabbar> {
  // 缩放比例
  double proportion = 0.0;

  // 当前index
  var currentIndex = 0;
  // 动画值
  var tabviewAnimateValue = 0.0;
  // 下一个准备前往的值
  var nextInddex = 0;
  // 两个之前的动画差值0-1之间
  var diff = 1.0;
  @override
  void initState() {
    super.initState();

    if (widget.labelStyle != null && widget.labelStyle!.fontSize != null) {
      throw 'The fontSize property of labelStyle cannot be set';
    }

    if (widget.unselectedLabelStyle != null &&
        widget.unselectedLabelStyle!.fontSize == null) {
      throw 'The fontSize property of unselectedLabelStyle must be set';
    }

    if (widget.unselectedLabelStyle!.fontSize! <= 0) {
      throw 'The fontSize property of unselectedLabelStyle must be greater than 0';
    }

    //  初始化当前值
    currentIndex = widget.controller!.index;
    nextInddex = currentIndex;

    proportion =
        (widget.labelFontSize - widget.unselectedLabelStyle!.fontSize!) /
            widget.unselectedLabelStyle!.fontSize!;

    // print(widget.unselectedLabelStyle!.fontSize! + (widget.unselectedLabelStyle!.fontSize! * proportion));

    widget.controller!.addListener(() {
      currentIndex = widget.controller!.index;
      updateTabviewAnimateValue(widget.controller!.animation!.value);
      if (widget.onChange != null) widget.onChange!(currentIndex);
    });
    widget.controller!.animation!.addListener(() {
      updateTabviewAnimateValue(widget.controller!.animation!.value);
    });
  }

  @override
  void dispose() {
    widget.controller!.animation!.removeListener(() {});
    widget.controller!.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
        controller: widget.controller,
        // isScrollable: widget.isScrollable,
        // indicatorColor: widget.indicatorColor,
        // automaticIndicatorColorAdjustment:
        //     widget.automaticIndicatorColorAdjustment,
        // indicatorWeight: widget.indicatorWeight,
        // indicatorPadding: widget.indicatorPadding,
        // indicator: widget.indicator,
        // indicatorSize: widget.indicatorSize,
        // labelColor: widget.labelColor,
        // labelStyle: widget.labelStyle ?? const TextStyle(),
        // labelPadding: widget.labelPadding,
        // unselectedLabelColor: widget.unselectedLabelColor,
        // unselectedLabelStyle: widget.unselectedLabelStyle,
        // dragStartBehavior: widget.dragStartBehavior,
        // overlayColor: widget.overlayColor,
        // mouseCursor: widget.mouseCursor,
        // enableFeedback: widget.enableFeedback,
        // onTap: widget.onTap,
        // physics: widget.physics,
        tabs: getTabsWidget(widget.tabs));
  }

  List<Widget> getTabsWidget(List<Widget> tabs) {
    List<Widget> tabWidgetList = [];
    for (var i = 0; i < tabs.length; i++) {
      // 默认显示一倍
      double defalutProportion = 1.0;
      double showProportion = defalutProportion;
      if (currentIndex == i) {
        showProportion = defalutProportion + (proportion - proportion * diff);
      }
      if (nextInddex == i) {
        showProportion = defalutProportion + (proportion * diff);
      }
      if (showProportion < 0) {
        showProportion = 0;
      }
      tabWidgetList.add(Transform.scale(
        scale: showProportion,
        child: tabs[i],
      ));
    }
    return tabWidgetList;
  }

  void updateTabviewAnimateValue(newValue) {
    tabviewAnimateValue = newValue;
    // 判断向后移动，还是向前移动
    if (newValue > currentIndex) {
      nextInddex = currentIndex + 1;
      diff = tabviewAnimateValue - (nextInddex - 1);
    } else {
      nextInddex = currentIndex - 1;
      diff = nextInddex + 1 - tabviewAnimateValue;
    }
    if (nextInddex < 0) nextInddex = 0;
    if (diff == 0) {
      nextInddex = -1;
    }

    if (widget.onAnimatedChange != null) {
      widget.onAnimatedChange!(newValue, diff, currentIndex, nextInddex);
    }
    setState(() {});
  }
}
