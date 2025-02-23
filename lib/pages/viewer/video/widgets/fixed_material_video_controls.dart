/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animetrace/utils/extensions/color.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';

import 'package:media_kit_video/media_kit_video_controls/src/controls/methods/video_state.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/extensions/duration.dart';
import 'package:media_kit_video/media_kit_video_controls/src/controls/widgets/video_controls_theme_data_injector.dart';

/// {@template material_video_controls}
///
/// [Video] controls which use Material design.
///
/// {@endtemplate}
Widget MaterialVideoControls(VideoState state) {
  return const VideoControlsThemeDataInjector(
    child: _MaterialVideoControls(),
  );
}

/// [MaterialVideoControlsThemeData] available in this [context].
MaterialVideoControlsThemeData _theme(BuildContext context) =>
    FullscreenInheritedWidget.maybeOf(context) == null
        ? MaterialVideoControlsTheme.maybeOf(context)?.normal ??
            kDefaultMaterialVideoControlsThemeData
        : MaterialVideoControlsTheme.maybeOf(context)?.fullscreen ??
            kDefaultMaterialVideoControlsThemeDataFullscreen;

/// Default [MaterialVideoControlsThemeData].
const kDefaultMaterialVideoControlsThemeData = MaterialVideoControlsThemeData();

/// Default [MaterialVideoControlsThemeData] for fullscreen.
const kDefaultMaterialVideoControlsThemeDataFullscreen =
    MaterialVideoControlsThemeData(
  displaySeekBar: true,
  automaticallyImplySkipNextButton: true,
  automaticallyImplySkipPreviousButton: true,
  volumeGesture: true,
  brightnessGesture: true,
  seekOnDoubleTap: true,
  visibleOnMount: false,
  backdropColor: Color(0x66000000),
  padding: null,
  controlsHoverDuration: Duration(seconds: 3),
  controlsTransitionDuration: Duration(milliseconds: 300),
  bufferingIndicatorBuilder: null,
  primaryButtonBar: [
    Spacer(flex: 2),
    MaterialSkipPreviousButton(),
    Spacer(),
    MaterialPlayOrPauseButton(iconSize: 56.0),
    Spacer(),
    MaterialSkipNextButton(),
    Spacer(flex: 2),
  ],
  topButtonBar: [],
  topButtonBarMargin: EdgeInsets.symmetric(
    horizontal: 16.0,
  ),
  bottomButtonBar: [
    MaterialPositionIndicator(),
    Spacer(),
    MaterialFullscreenButton(),
  ],
  bottomButtonBarMargin: EdgeInsets.only(
    left: 16.0,
    right: 8.0,
    bottom: 42.0,
  ),
  buttonBarHeight: 56.0,
  buttonBarButtonSize: 24.0,
  buttonBarButtonColor: Color(0xFFFFFFFF),
  seekBarMargin: EdgeInsets.only(
    left: 16.0,
    right: 16.0,
    bottom: 42.0,
  ),
  seekBarHeight: 2.4,
  seekBarContainerHeight: 36.0,
  seekBarColor: Color(0x3DFFFFFF),
  seekBarPositionColor: Color(0xFFFF0000),
  seekBarBufferColor: Color(0x3DFFFFFF),
  seekBarThumbSize: 12.8,
  seekBarThumbColor: Color(0xFFFF0000),
  seekBarAlignment: Alignment.bottomCenter,
  shiftSubtitlesOnControlsVisibilityChange: false,
);

/// {@template material_video_controls_theme_data}
///
/// Theming related data for [MaterialVideoControls]. These values are used to theme the descendant [MaterialVideoControls].
///
/// {@endtemplate}
class MaterialVideoControlsThemeData {
  // BEHAVIOR

  /// Whether to display seek bar.
  final bool displaySeekBar;

  /// Whether a skip next button should be displayed if there are more than one videos in the playlist.
  final bool automaticallyImplySkipNextButton;

  /// Whether a skip previous button should be displayed if there are more than one videos in the playlist.
  final bool automaticallyImplySkipPreviousButton;

  /// Whether to modify volume on vertical drag gesture on the right side of the screen.
  final bool volumeGesture;

  /// Whether to modify screen brightness on vertical drag gesture on the left side of the screen.
  final bool brightnessGesture;

  /// Whether to enable double tap to seek on left or right side of the screen.
  final bool seekOnDoubleTap;

  /// Whether the controls are initially visible.
  final bool visibleOnMount;

  /// Color of backdrop that comes up when controls are visible.
  final Color? backdropColor;

  // GENERIC

  /// Padding around the controls.
  ///
  /// * Default: `EdgeInsets.zero`
  /// * Fullscreen: `MediaQuery.of(context).padding`
  final EdgeInsets? padding;

  /// [Duration] after which the controls will be hidden when there is no mouse movement.
  final Duration controlsHoverDuration;

  /// [Duration] for which the controls will be animated when shown or hidden.
  final Duration controlsTransitionDuration;

  /// Builder for the buffering indicator.
  final Widget Function(BuildContext)? bufferingIndicatorBuilder;

  /// Custom builder for volume indicator.
  final Widget Function(BuildContext, double)? volumeIndicatorBuilder;

  /// Custom builder for brightness indicator.
  final Widget Function(BuildContext, double)? brightnessIndicatorBuilder;

  // BUTTON BAR

  /// Buttons to be displayed in the primary button bar.
  final List<Widget> primaryButtonBar;

  /// Buttons to be displayed in the top button bar.
  final List<Widget> topButtonBar;

  /// Margin around the top button bar.
  final EdgeInsets topButtonBarMargin;

  /// Buttons to be displayed in the bottom button bar.
  final List<Widget> bottomButtonBar;

  /// Margin around the button bar.
  final EdgeInsets bottomButtonBarMargin;

  /// Height of the button bar.
  final double buttonBarHeight;

  /// Size of the button bar buttons.
  final double buttonBarButtonSize;

  /// Color of the button bar buttons.
  final Color buttonBarButtonColor;

  // SEEK BAR

  /// Margin around the seek bar.
  final EdgeInsets seekBarMargin;

  /// Height of the seek bar.
  final double seekBarHeight;

  /// Height of the seek bar [Container].
  final double seekBarContainerHeight;

  /// [Color] of the seek bar.
  final Color seekBarColor;

  /// [Color] of the playback position section in the seek bar.
  final Color seekBarPositionColor;

  /// [Color] of the playback buffer section in the seek bar.
  final Color seekBarBufferColor;

  /// Size of the seek bar thumb.
  final double seekBarThumbSize;

  /// [Color] of the seek bar thumb.
  final Color seekBarThumbColor;

  /// [Alignment] of seek bar inside the seek bar container.
  final Alignment seekBarAlignment;

  // SUBTITLE

  /// Whether to shift the subtitles upwards when the controls are visible.
  final bool shiftSubtitlesOnControlsVisibilityChange;

  /// {@macro material_video_controls_theme_data}
  const MaterialVideoControlsThemeData({
    this.displaySeekBar = true,
    this.automaticallyImplySkipNextButton = true,
    this.automaticallyImplySkipPreviousButton = true,
    this.volumeGesture = false,
    this.brightnessGesture = false,
    this.seekOnDoubleTap = true,
    this.visibleOnMount = false,
    this.backdropColor = const Color(0x66000000),
    this.padding,
    this.controlsHoverDuration = const Duration(seconds: 3),
    this.controlsTransitionDuration = const Duration(milliseconds: 300),
    this.bufferingIndicatorBuilder,
    this.volumeIndicatorBuilder,
    this.brightnessIndicatorBuilder,
    this.primaryButtonBar = const [
      Spacer(flex: 2),
      MaterialSkipPreviousButton(),
      Spacer(),
      MaterialPlayOrPauseButton(iconSize: 48.0),
      Spacer(),
      MaterialSkipNextButton(),
      Spacer(flex: 2),
    ],
    this.topButtonBar = const [],
    this.topButtonBarMargin = const EdgeInsets.symmetric(horizontal: 16.0),
    this.bottomButtonBar = const [
      MaterialPositionIndicator(),
      Spacer(),
      MaterialFullscreenButton(),
    ],
    this.bottomButtonBarMargin = const EdgeInsets.only(left: 16.0, right: 8.0),
    this.buttonBarHeight = 56.0,
    this.buttonBarButtonSize = 24.0,
    this.buttonBarButtonColor = const Color(0xFFFFFFFF),
    this.seekBarMargin = EdgeInsets.zero,
    this.seekBarHeight = 2.4,
    this.seekBarContainerHeight = 36.0,
    this.seekBarColor = const Color(0x3DFFFFFF),
    this.seekBarPositionColor = const Color(0xFFFF0000),
    this.seekBarBufferColor = const Color(0x3DFFFFFF),
    this.seekBarThumbSize = 12.8,
    this.seekBarThumbColor = const Color(0xFFFF0000),
    this.seekBarAlignment = Alignment.bottomCenter,
    this.shiftSubtitlesOnControlsVisibilityChange = false,
  });

  /// Creates a copy of this [MaterialVideoControlsThemeData] with the given fields replaced by the non-null parameter values.
  MaterialVideoControlsThemeData copyWith({
    bool? displaySeekBar,
    bool? automaticallyImplySkipNextButton,
    bool? automaticallyImplySkipPreviousButton,
    bool? volumeGesture,
    bool? brightnessGesture,
    bool? seekOnDoubleTap,
    bool? visibleOnMount,
    Color? backdropColor,
    Duration? controlsHoverDuration,
    Duration? controlsTransitionDuration,
    Widget Function(BuildContext)? bufferingIndicatorBuilder,
    Widget Function(BuildContext, double)? volumeIndicatorBuilder,
    Widget Function(BuildContext, double)? brightnessIndicatorBuilder,
    List<Widget>? primaryButtonBar,
    List<Widget>? topButtonBar,
    EdgeInsets? topButtonBarMargin,
    List<Widget>? bottomButtonBar,
    EdgeInsets? bottomButtonBarMargin,
    double? buttonBarHeight,
    double? buttonBarButtonSize,
    Color? buttonBarButtonColor,
    EdgeInsets? seekBarMargin,
    double? seekBarHeight,
    double? seekBarContainerHeight,
    Color? seekBarColor,
    Color? seekBarPositionColor,
    Color? seekBarBufferColor,
    double? seekBarThumbSize,
    Color? seekBarThumbColor,
    Alignment? seekBarAlignment,
    bool? shiftSubtitlesOnControlsVisibilityChange,
  }) {
    return MaterialVideoControlsThemeData(
      displaySeekBar: displaySeekBar ?? this.displaySeekBar,
      automaticallyImplySkipNextButton: automaticallyImplySkipNextButton ??
          this.automaticallyImplySkipNextButton,
      automaticallyImplySkipPreviousButton:
          automaticallyImplySkipPreviousButton ??
              this.automaticallyImplySkipPreviousButton,
      volumeGesture: volumeGesture ?? this.volumeGesture,
      brightnessGesture: brightnessGesture ?? this.brightnessGesture,
      seekOnDoubleTap: seekOnDoubleTap ?? this.seekOnDoubleTap,
      visibleOnMount: visibleOnMount ?? this.visibleOnMount,
      backdropColor: backdropColor ?? this.backdropColor,
      controlsHoverDuration:
          controlsHoverDuration ?? this.controlsHoverDuration,
      controlsTransitionDuration:
          controlsTransitionDuration ?? this.controlsTransitionDuration,
      bufferingIndicatorBuilder:
          bufferingIndicatorBuilder ?? this.bufferingIndicatorBuilder,
      volumeIndicatorBuilder:
          volumeIndicatorBuilder ?? this.volumeIndicatorBuilder,
      brightnessIndicatorBuilder:
          brightnessIndicatorBuilder ?? this.brightnessIndicatorBuilder,
      primaryButtonBar: primaryButtonBar ?? this.primaryButtonBar,
      topButtonBar: topButtonBar ?? this.topButtonBar,
      topButtonBarMargin: topButtonBarMargin ?? this.topButtonBarMargin,
      bottomButtonBar: bottomButtonBar ?? this.bottomButtonBar,
      bottomButtonBarMargin:
          bottomButtonBarMargin ?? this.bottomButtonBarMargin,
      buttonBarHeight: buttonBarHeight ?? this.buttonBarHeight,
      buttonBarButtonSize: buttonBarButtonSize ?? this.buttonBarButtonSize,
      buttonBarButtonColor: buttonBarButtonColor ?? this.buttonBarButtonColor,
      seekBarMargin: seekBarMargin ?? this.seekBarMargin,
      seekBarHeight: seekBarHeight ?? this.seekBarHeight,
      seekBarContainerHeight:
          seekBarContainerHeight ?? this.seekBarContainerHeight,
      seekBarColor: seekBarColor ?? this.seekBarColor,
      seekBarPositionColor: seekBarPositionColor ?? this.seekBarPositionColor,
      seekBarBufferColor: seekBarBufferColor ?? this.seekBarBufferColor,
      seekBarThumbSize: seekBarThumbSize ?? this.seekBarThumbSize,
      seekBarThumbColor: seekBarThumbColor ?? this.seekBarThumbColor,
      seekBarAlignment: seekBarAlignment ?? this.seekBarAlignment,
      shiftSubtitlesOnControlsVisibilityChange:
          shiftSubtitlesOnControlsVisibilityChange ??
              this.shiftSubtitlesOnControlsVisibilityChange,
    );
  }
}

/// {@template material_video_controls_theme}
///
/// Inherited widget which provides [MaterialVideoControlsThemeData] to descendant widgets.
///
/// {@endtemplate}
class MaterialVideoControlsTheme extends InheritedWidget {
  final MaterialVideoControlsThemeData normal;
  final MaterialVideoControlsThemeData fullscreen;
  const MaterialVideoControlsTheme({
    super.key,
    required this.normal,
    required this.fullscreen,
    required super.child,
  });

  static MaterialVideoControlsTheme? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MaterialVideoControlsTheme>();
  }

  static MaterialVideoControlsTheme of(BuildContext context) {
    final MaterialVideoControlsTheme? result = maybeOf(context);
    assert(
      result != null,
      'No [MaterialVideoControlsTheme] found in [context]',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(MaterialVideoControlsTheme oldWidget) =>
      identical(normal, oldWidget.normal) &&
      identical(fullscreen, oldWidget.fullscreen);
}

/// {@macro material_video_controls}
class _MaterialVideoControls extends StatefulWidget {
  const _MaterialVideoControls();

  @override
  State<_MaterialVideoControls> createState() => _MaterialVideoControlsState();
}

/// {@macro material_video_controls}
class _MaterialVideoControlsState extends State<_MaterialVideoControls> {
  late bool mount = _theme(context).visibleOnMount;
  late bool visible = _theme(context).visibleOnMount;

  Timer? _timer;

  double _brightnessValue = 0.0;
  bool _brightnessIndicator = false;
  Timer? _brightnessTimer;

  double _volumeValue = 0.0;
  bool _volumeIndicator = false;
  Timer? _volumeTimer;
  // The default event stream in package:volume_controller is buggy.
  bool _volumeInterceptEventStream = false;

  late /* private */ var playlist = controller(context).player.state.playlist;
  late bool buffering = controller(context).player.state.buffering;

  bool _mountSeekBackwardButton = false;
  bool _mountSeekForwardButton = false;
  bool _hideSeekBackwardButton = false;
  bool _hideSeekForwardButton = false;

  final ValueNotifier<Duration> _seekBarDeltaValueNotifier =
      ValueNotifier<Duration>(Duration.zero);

  final List<StreamSubscription> subscriptions = [];

  double get subtitleVerticalShiftOffset =>
      (_theme(context).padding?.bottom ?? 0.0) +
      (_theme(context).bottomButtonBarMargin.vertical) +
      (_theme(context).bottomButtonBar.isNotEmpty
          ? _theme(context).buttonBarHeight
          : 0.0);

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (subscriptions.isEmpty) {
      subscriptions.addAll(
        [
          controller(context).player.stream.playlist.listen(
            (event) {
              setState(() {
                playlist = event;
              });
            },
          ),
          controller(context).player.stream.buffering.listen(
            (event) {
              setState(() {
                buffering = event;
              });
            },
          ),
        ],
      );

      if (_theme(context).visibleOnMount) {
        _timer = Timer(
          _theme(context).controlsHoverDuration,
          () {
            if (mounted) {
              setState(() {
                visible = false;
              });
              unshiftSubtitle();
            }
          },
        );
      }
    }
  }

  @override
  void dispose() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    // --------------------------------------------------
    // package:screen_brightness
    Future.microtask(() async {
      try {
        await ScreenBrightness().resetScreenBrightness();
      } catch (_) {}
    });
    // --------------------------------------------------
    super.dispose();
  }

  void shiftSubtitle() {
    if (_theme(context).shiftSubtitlesOnControlsVisibilityChange) {
      state(context).setSubtitleViewPadding(
        state(context).widget.subtitleViewConfiguration.padding +
            EdgeInsets.fromLTRB(
              0.0,
              0.0,
              0.0,
              subtitleVerticalShiftOffset,
            ),
      );
    }
  }

  void unshiftSubtitle() {
    if (_theme(context).shiftSubtitlesOnControlsVisibilityChange) {
      state(context).setSubtitleViewPadding(
        state(context).widget.subtitleViewConfiguration.padding,
      );
    }
  }

  void onTap({TapUpDetails? details}) {
    if (!visible) {
      setState(() {
        mount = true;
        visible = true;
      });
      shiftSubtitle();
      _timer?.cancel();
      _timer = Timer(_theme(context).controlsHoverDuration, () {
        if (mounted) {
          setState(() {
            visible = false;
          });
          unshiftSubtitle();
        }
      });
    } else {
      // linyi/fix: 避免点击顶部栏和底部栏隐藏
      if (details != null) {
        final wholeHeight = MediaQuery.of(context).size.height;
        final dy = details.globalPosition.dy;
        if (dy < 60 || dy > wholeHeight - 80) {
          return;
        }
      }

      setState(() {
        visible = false;
      });
      unshiftSubtitle();
      _timer?.cancel();
    }
  }

  void onDoubleTapSeekBackward() {
    setState(() {
      _mountSeekBackwardButton = true;
    });
  }

  void onDoubleTapSeekForward() {
    setState(() {
      _mountSeekForwardButton = true;
    });
  }

  @override
  void initState() {
    super.initState();
    // --------------------------------------------------
    // package:volume_controller
    Future.microtask(() async {
      try {
        VolumeController().showSystemUI = false;
        _volumeValue = await VolumeController().getVolume();
        VolumeController().listener((value) {
          if (mounted && !_volumeInterceptEventStream) {
            setState(() {
              _volumeValue = value;
            });
          }
        });
      } catch (_) {}
    });
    // --------------------------------------------------
    // --------------------------------------------------
    // package:screen_brightness
    Future.microtask(() async {
      try {
        _brightnessValue = await ScreenBrightness().current;
        ScreenBrightness().onCurrentBrightnessChanged.listen((value) {
          if (mounted) {
            setState(() {
              _brightnessValue = value;
            });
          }
        });
      } catch (_) {}
    });
    // --------------------------------------------------
  }

  Future<void> setVolume(double value) async {
    // --------------------------------------------------
    // package:volume_controller
    try {
      VolumeController().setVolume(value);
    } catch (_) {}
    setState(() {
      _volumeValue = value;
      _volumeIndicator = true;
      _volumeInterceptEventStream = true;
    });
    // --------------------------------------------------
  }

  void hideVolumeIndicator() {
    _volumeTimer?.cancel();
    _volumeTimer = Timer(const Duration(milliseconds: 0), () {
      if (mounted) {
        setState(() {
          _volumeIndicator = false;
          _volumeInterceptEventStream = false;
        });
      }
    });
  }

  Future<void> setBrightness(double value) async {
    // --------------------------------------------------
    // package:screen_brightness
    try {
      await ScreenBrightness().setScreenBrightness(value);
    } catch (_) {}
    setState(() {
      _brightnessIndicator = true;
    });

    // --------------------------------------------------
  }

  void hideBrightnessIndicator() {
    _brightnessTimer?.cancel();
    // linyi/feat: 避免调整亮度值后，消失过快
    _brightnessTimer = Timer(const Duration(milliseconds: 0), () {
      if (mounted) {
        setState(() {
          _brightnessIndicator = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        focusColor: const Color(0x00000000),
        hoverColor: const Color(0x00000000),
        splashColor: const Color(0x00000000),
        highlightColor: const Color(0x00000000),
      ),
      child: Focus(
        autofocus: true,
        child: Material(
          elevation: 0.0,
          borderOnForeground: false,
          animationDuration: Duration.zero,
          color: const Color(0x00000000),
          shadowColor: const Color(0x00000000),
          surfaceTintColor: const Color(0x00000000),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Volume Indicator.
              AnimatedOpacity(
                curve: Curves.easeInOut,
                opacity:
                    // linyi/fix: mount时，改变音量也显示进度器
                    //  !mount &&
                    _volumeIndicator ? 1.0 : 0.0,
                duration: _theme(context).controlsTransitionDuration,
                child: _theme(context)
                        .volumeIndicatorBuilder
                        ?.call(context, _volumeValue) ??
                    Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0x88000000),
                        borderRadius: BorderRadius.circular(64.0),
                      ),
                      height: 52.0,
                      width: 108.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: 52.0,
                            width: 42.0,
                            alignment: Alignment.centerRight,
                            child: Icon(
                              _volumeValue == 0.0
                                  ? Icons.volume_off
                                  : _volumeValue < 0.5
                                      ? Icons.volume_down
                                      : Icons.volume_up,
                              color: const Color(0xFFFFFFFF),
                              size: 24.0,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              '${(_volumeValue * 100.0).round()}%',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                        ],
                      ),
                    ),
              ),
              // Brightness Indicator.
              AnimatedOpacity(
                curve: Curves.easeInOut,
                opacity:
                    // linyi/fix: mount时，改变亮度也显示进度器
                    //  !mount &&
                    _brightnessIndicator ? 1.0 : 0.0,
                duration: _theme(context).controlsTransitionDuration,
                child: _theme(context)
                        .brightnessIndicatorBuilder
                        // linyi/fix: 回调传入亮度值而不是音量值
                        ?.call(context, _brightnessValue) ??
                    Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0x88000000),
                        borderRadius: BorderRadius.circular(64.0),
                      ),
                      height: 52.0,
                      width: 108.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: 52.0,
                            width: 42.0,
                            alignment: Alignment.centerRight,
                            child: Icon(
                              _brightnessValue < 1.0 / 3.0
                                  ? Icons.brightness_low
                                  : _brightnessValue < 2.0 / 3.0
                                      ? Icons.brightness_medium
                                      : Icons.brightness_high,
                              color: const Color(0xFFFFFFFF),
                              size: 24.0,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              '${(_brightnessValue * 100.0).round()}%',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                        ],
                      ),
                    ),
              ),
              // Controls:
              AnimatedOpacity(
                curve: Curves.easeInOut,
                opacity: visible ? 1.0 : 0.0,
                duration: _theme(context).controlsTransitionDuration,
                onEnd: () {
                  setState(() {
                    if (!visible) {
                      mount = false;
                    }
                  });
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // linyi/feat: 顶部栏和底部栏添加渐变阴影
                    Positioned(
                      top: 0,
                      child: Container(
                        height: 120,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacityFactor(0.5),
                                Colors.transparent,
                              ]),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Container(
                        height: 120,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacityFactor(0.5),
                                Colors.transparent,
                              ]),
                        ),
                      ),
                    ),
                    // We are adding 16.0 boundary around the actual controls (which contain the vertical drag gesture detectors).
                    // This will make the hit-test on edges (e.g. swiping to: show status-bar, show navigation-bar, go back in navigation) not activate the swipe gesture annoyingly.
                    Positioned.fill(
                      left: 16.0,
                      top: 16.0,
                      right: 16.0,
                      bottom: 16.0,
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTapUp: (e) => onTap(details: e),
                              onDoubleTap:
                                  !mount && _theme(context).seekOnDoubleTap
                                      ? onDoubleTapSeekBackward
                                      : () {},
                              onVerticalDragUpdate:
                                  // linyi/fix: 移除mount判断，修复显示顶部栏和底部栏时无法改变音量或亮度
                                  // !mount &&
                                  _theme(context).brightnessGesture
                                      ? (e) async {
                                          final delta = e.delta.dy;
                                          final brightness =
                                              _brightnessValue - delta / 200.0;
                                          final result =
                                              brightness.clamp(0.0, 1.0);
                                          setBrightness(result);
                                        }
                                      : null,
                              onVerticalDragEnd: (details) =>
                                  hideBrightnessIndicator(),
                              child: Container(
                                color: const Color(0x00000000),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTapUp: (e) => onTap(details: e),
                              onDoubleTap:
                                  !mount && _theme(context).seekOnDoubleTap
                                      ? onDoubleTapSeekForward
                                      : () {},
                              onVerticalDragUpdate:
                                  // linyi/fix: 移除mount判断，修复显示顶部栏和底部栏时无法改变音量或亮度
                                  // !mount &&
                                  _theme(context).volumeGesture
                                      ? (e) async {
                                          final delta = e.delta.dy;
                                          final volume =
                                              _volumeValue - delta / 200.0;
                                          final result = volume.clamp(0.0, 1.0);
                                          setVolume(result);
                                        }
                                      : null,
                              onVerticalDragEnd: (details) =>
                                  hideVolumeIndicator(),
                              child: Container(
                                color: const Color(0x00000000),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (mount)
                      Padding(
                        padding: _theme(context).padding ??
                            (
                                // Add padding in fullscreen!
                                isFullscreen(context)
                                    ? MediaQuery.of(context).padding
                                    : EdgeInsets.zero),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              height: _theme(context).buttonBarHeight,
                              margin: _theme(context).topButtonBarMargin,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: _theme(context).topButtonBar,
                              ),
                            ),
                            // Only display [primaryButtonBar] if [buffering] is false.
                            Expanded(
                              child: AnimatedOpacity(
                                curve: Curves.easeInOut,
                                opacity: buffering ? 0.0 : 1.0,
                                duration:
                                    _theme(context).controlsTransitionDuration,
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: _theme(context).primaryButtonBar,
                                  ),
                                ),
                              ),
                            ),
                            Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                if (_theme(context).displaySeekBar)
                                  MaterialSeekBar(
                                    onSeekStart: () {
                                      _timer?.cancel();
                                    },
                                    onSeekEnd: () {
                                      _timer = Timer(
                                        _theme(context).controlsHoverDuration,
                                        () {
                                          if (mounted) {
                                            setState(() {
                                              visible = false;
                                            });
                                            unshiftSubtitle();
                                          }
                                        },
                                      );
                                    },
                                  ),
                                Container(
                                  height: _theme(context).buttonBarHeight,
                                  margin: _theme(context).bottomButtonBarMargin,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: _theme(context).bottomButtonBar,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Double-Tap Seek Seek-Bar:
              if (!mount)
                if (_mountSeekBackwardButton || _mountSeekForwardButton)
                  Column(
                    children: [
                      const Spacer(),
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          if (_theme(context).displaySeekBar)
                            MaterialSeekBar(
                              delta: _seekBarDeltaValueNotifier,
                            ),
                          Container(
                            height: _theme(context).buttonBarHeight,
                            margin: _theme(context).bottomButtonBarMargin,
                          ),
                        ],
                      ),
                    ],
                  ),
              // Buffering Indicator.
              IgnorePointer(
                child: Padding(
                  padding: _theme(context).padding ??
                      (
                          // Add padding in fullscreen!
                          isFullscreen(context)
                              ? MediaQuery.of(context).padding
                              : EdgeInsets.zero),
                  child: Column(
                    children: [
                      Container(
                        height: _theme(context).buttonBarHeight,
                        margin: _theme(context).topButtonBarMargin,
                      ),
                      Expanded(
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0.0,
                              end: buffering ? 1.0 : 0.0,
                            ),
                            duration:
                                _theme(context).controlsTransitionDuration,
                            builder: (context, value, child) {
                              // Only mount the buffering indicator if the opacity is greater than 0.0.
                              // This has been done to prevent redundant resource usage in [CircularProgressIndicator].
                              if (value > 0.0) {
                                return Opacity(
                                  opacity: value,
                                  child: _theme(context)
                                          .bufferingIndicatorBuilder
                                          ?.call(context) ??
                                      child!,
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            child: const CircularProgressIndicator(
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: _theme(context).buttonBarHeight,
                        margin: _theme(context).bottomButtonBarMargin,
                      ),
                    ],
                  ),
                ),
              ),
              // Double-Tap Seek Button(s):
              if (!mount)
                if (_mountSeekBackwardButton || _mountSeekForwardButton)
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: _mountSeekBackwardButton
                              ? TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    begin: 0.0,
                                    end: _hideSeekBackwardButton ? 0.0 : 1.0,
                                  ),
                                  duration: const Duration(milliseconds: 200),
                                  builder: (context, value, child) => Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                  onEnd: () {
                                    if (_hideSeekBackwardButton) {
                                      setState(() {
                                        _hideSeekBackwardButton = false;
                                        _mountSeekBackwardButton = false;
                                      });
                                    }
                                  },
                                  child: _BackwardSeekIndicator(
                                    onChanged: (value) {
                                      _seekBarDeltaValueNotifier.value = -value;
                                    },
                                    onSubmitted: (value) {
                                      setState(() {
                                        _hideSeekBackwardButton = true;
                                      });
                                      var result = controller(context)
                                              .player
                                              .state
                                              .position -
                                          value;
                                      result = result.clamp(
                                        Duration.zero,
                                        controller(context)
                                            .player
                                            .state
                                            .duration,
                                      );
                                      controller(context).player.seek(result);
                                    },
                                  ),
                                )
                              : const SizedBox(),
                        ),
                        Expanded(
                          child: _mountSeekForwardButton
                              ? TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    begin: 0.0,
                                    end: _hideSeekForwardButton ? 0.0 : 1.0,
                                  ),
                                  duration: const Duration(milliseconds: 200),
                                  builder: (context, value, child) => Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                  onEnd: () {
                                    if (_hideSeekForwardButton) {
                                      setState(() {
                                        _hideSeekForwardButton = false;
                                        _mountSeekForwardButton = false;
                                      });
                                    }
                                  },
                                  child: _ForwardSeekIndicator(
                                    onChanged: (value) {
                                      _seekBarDeltaValueNotifier.value = value;
                                    },
                                    onSubmitted: (value) {
                                      setState(() {
                                        _hideSeekForwardButton = true;
                                      });
                                      var result = controller(context)
                                              .player
                                              .state
                                              .position +
                                          value;
                                      result = result.clamp(
                                        Duration.zero,
                                        controller(context)
                                            .player
                                            .state
                                            .duration,
                                      );
                                      controller(context).player.seek(result);
                                    },
                                  ),
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// SEEK BAR

/// Material design seek bar.
class MaterialSeekBar extends StatefulWidget {
  final ValueNotifier<Duration>? delta;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;

  const MaterialSeekBar({
    Key? key,
    this.delta,
    this.onSeekStart,
    this.onSeekEnd,
  }) : super(key: key);

  @override
  MaterialSeekBarState createState() => MaterialSeekBarState();
}

class MaterialSeekBarState extends State<MaterialSeekBar> {
  bool tapped = false;
  double slider = 0.0;

  late bool playing = controller(context).player.state.playing;
  late Duration position = controller(context).player.state.position;
  late Duration duration = controller(context).player.state.duration;
  late Duration buffer = controller(context).player.state.buffer;

  final List<StreamSubscription> subscriptions = [];

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void listener() {
    setState(() {
      final delta = widget.delta?.value ?? Duration.zero;
      position = controller(context).player.state.position + delta;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.delta?.addListener(listener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (subscriptions.isEmpty && widget.delta == null) {
      subscriptions.addAll(
        [
          controller(context).player.stream.playing.listen((event) {
            setState(() {
              playing = event;
            });
          }),
          controller(context).player.stream.completed.listen((event) {
            setState(() {
              position = Duration.zero;
            });
          }),
          controller(context).player.stream.position.listen((event) {
            setState(() {
              if (!tapped) {
                position = event;
              }
            });
          }),
          controller(context).player.stream.duration.listen((event) {
            setState(() {
              duration = event;
            });
          }),
          controller(context).player.stream.buffer.listen((event) {
            setState(() {
              buffer = event;
            });
          }),
        ],
      );
    }
  }

  @override
  void dispose() {
    widget.delta?.removeListener(listener);
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void onPointerMove(PointerMoveEvent e, BoxConstraints constraints) {
    final percent = e.localPosition.dx / constraints.maxWidth;
    setState(() {
      tapped = true;
      slider = percent.clamp(0.0, 1.0);
    });
  }

  void onPointerDown() {
    widget.onSeekStart?.call();
    setState(() {
      tapped = true;
    });
  }

  void onPointerUp() {
    widget.onSeekEnd?.call();
    setState(() {
      tapped = false;
    });
    controller(context).player.seek(duration * slider);
    setState(() {
      // Explicitly set the position to prevent the slider from jumping.
      position = duration * slider;
    });
  }

  void onPanStart(DragStartDetails e, BoxConstraints constraints) {
    final percent = e.localPosition.dx / constraints.maxWidth;
    setState(() {
      tapped = true;
      slider = percent.clamp(0.0, 1.0);
    });
  }

  void onPanDown(DragDownDetails e, BoxConstraints constraints) {
    final percent = e.localPosition.dx / constraints.maxWidth;
    setState(() {
      tapped = true;
      slider = percent.clamp(0.0, 1.0);
    });
  }

  void onPanUpdate(DragUpdateDetails e, BoxConstraints constraints) {
    final percent = e.localPosition.dx / constraints.maxWidth;
    setState(() {
      tapped = true;
      slider = percent.clamp(0.0, 1.0);
    });
  }

  /// Returns the current playback position in percentage.
  double get positionPercent {
    if (position == Duration.zero || duration == Duration.zero) {
      return 0.0;
    } else {
      final value = position.inMilliseconds / duration.inMilliseconds;
      return value.clamp(0.0, 1.0);
    }
  }

  /// Returns the current playback buffer position in percentage.
  double get bufferPercent {
    if (buffer == Duration.zero || duration == Duration.zero) {
      return 0.0;
    } else {
      final value = buffer.inMilliseconds / duration.inMilliseconds;
      return value.clamp(0.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.none,
      margin: _theme(context).seekBarMargin,
      child: LayoutBuilder(
        builder: (context, constraints) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onHorizontalDragUpdate: (_) {},
            onPanStart: (e) => onPanStart(e, constraints),
            onPanDown: (e) => onPanDown(e, constraints),
            onPanUpdate: (e) => onPanUpdate(e, constraints),
            child: Listener(
              onPointerMove: (e) => onPointerMove(e, constraints),
              onPointerDown: (e) => onPointerDown(),
              onPointerUp: (e) => onPointerUp(),
              child: Container(
                color: Colors.transparent,
                width: constraints.maxWidth,
                alignment: _theme(context).seekBarAlignment,
                height: _theme(context).seekBarContainerHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: constraints.maxWidth,
                      height: _theme(context).seekBarHeight,
                      alignment: Alignment.bottomLeft,
                      decoration: BoxDecoration(
                        color: _theme(context).seekBarColor,
                        // linyi/ui: 进度条圆角
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomLeft,
                        children: [
                          Container(
                            width: constraints.maxWidth * bufferPercent,
                            decoration: BoxDecoration(
                              color: _theme(context).seekBarBufferColor,
                              // linyi/ui: 进度条圆角
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          Container(
                            width: tapped
                                ? constraints.maxWidth * slider
                                : constraints.maxWidth * positionPercent,
                            decoration: BoxDecoration(
                              color: _theme(context).seekBarPositionColor,
                              // linyi/ui: 进度条圆角
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: tapped
                          ? (constraints.maxWidth -
                                  _theme(context).seekBarThumbSize / 2) *
                              slider
                          : (constraints.maxWidth -
                                  _theme(context).seekBarThumbSize / 2) *
                              positionPercent,
                      bottom: -1.0 * _theme(context).seekBarThumbSize / 2 +
                          _theme(context).seekBarHeight / 2,
                      child: Container(
                        width: _theme(context).seekBarThumbSize,
                        height: _theme(context).seekBarThumbSize,
                        decoration: BoxDecoration(
                          color: _theme(context).seekBarThumbColor,
                          borderRadius: BorderRadius.circular(
                            _theme(context).seekBarThumbSize / 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// BUTTON: PLAY/PAUSE

/// A material design play/pause button.
class MaterialPlayOrPauseButton extends StatefulWidget {
  /// Overriden icon size for [MaterialSkipPreviousButton].
  final double? iconSize;

  /// Overriden icon color for [MaterialSkipPreviousButton].
  final Color? iconColor;

  const MaterialPlayOrPauseButton({
    super.key,
    this.iconSize,
    this.iconColor,
  });

  @override
  MaterialPlayOrPauseButtonState createState() =>
      MaterialPlayOrPauseButtonState();
}

class MaterialPlayOrPauseButtonState extends State<MaterialPlayOrPauseButton>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    value: controller(context).player.state.playing ? 1 : 0,
    duration: const Duration(milliseconds: 200),
  );

  StreamSubscription<bool>? subscription;

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    subscription ??= controller(context).player.stream.playing.listen((event) {
      if (event) {
        animation.forward();
      } else {
        animation.reverse();
      }
    });
  }

  @override
  void dispose() {
    animation.dispose();
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: controller(context).player.playOrPause,
      iconSize: widget.iconSize ?? _theme(context).buttonBarButtonSize,
      color: widget.iconColor ?? _theme(context).buttonBarButtonColor,
      icon: AnimatedIcon(
        progress: animation,
        icon: AnimatedIcons.play_pause,
        size: widget.iconSize ?? _theme(context).buttonBarButtonSize,
        color: widget.iconColor ?? _theme(context).buttonBarButtonColor,
      ),
    );
  }
}

// BUTTON: SKIP NEXT

/// Material design skip next button.
class MaterialSkipNextButton extends StatelessWidget {
  /// Icon for [MaterialSkipNextButton].
  final Widget? icon;

  /// Overriden icon size for [MaterialSkipNextButton].
  final double? iconSize;

  /// Overriden icon color for [MaterialSkipNextButton].
  final Color? iconColor;

  const MaterialSkipNextButton({
    Key? key,
    this.icon,
    this.iconSize,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!_theme(context).automaticallyImplySkipNextButton ||
        (controller(context).player.state.playlist.medias.length > 1 &&
            _theme(context).automaticallyImplySkipNextButton)) {
      return IconButton(
        onPressed: controller(context).player.next,
        icon: icon ?? const Icon(Icons.skip_next),
        iconSize: iconSize ?? _theme(context).buttonBarButtonSize,
        color: iconColor ?? _theme(context).buttonBarButtonColor,
      );
    }
    return const SizedBox.shrink();
  }
}

// BUTTON: SKIP PREVIOUS

/// Material design skip previous button.
class MaterialSkipPreviousButton extends StatelessWidget {
  /// Icon for [MaterialSkipPreviousButton].
  final Widget? icon;

  /// Overriden icon size for [MaterialSkipPreviousButton].
  final double? iconSize;

  /// Overriden icon color for [MaterialSkipPreviousButton].
  final Color? iconColor;

  const MaterialSkipPreviousButton({
    Key? key,
    this.icon,
    this.iconSize,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!_theme(context).automaticallyImplySkipPreviousButton ||
        (controller(context).player.state.playlist.medias.length > 1 &&
            _theme(context).automaticallyImplySkipPreviousButton)) {
      return IconButton(
        onPressed: controller(context).player.previous,
        icon: icon ?? const Icon(Icons.skip_previous),
        iconSize: iconSize ?? _theme(context).buttonBarButtonSize,
        color: iconColor ?? _theme(context).buttonBarButtonColor,
      );
    }
    return const SizedBox.shrink();
  }
}

// BUTTON: FULL SCREEN

/// Material design fullscreen button.
class MaterialFullscreenButton extends StatelessWidget {
  /// Icon for [MaterialFullscreenButton].
  final Widget? icon;

  /// Overriden icon size for [MaterialFullscreenButton].
  final double? iconSize;

  /// Overriden icon color for [MaterialFullscreenButton].
  final Color? iconColor;

  const MaterialFullscreenButton({
    Key? key,
    this.icon,
    this.iconSize,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => toggleFullscreen(context),
      icon: icon ??
          (isFullscreen(context)
              ? const Icon(Icons.fullscreen_exit)
              : const Icon(Icons.fullscreen)),
      iconSize: iconSize ?? _theme(context).buttonBarButtonSize,
      color: iconColor ?? _theme(context).buttonBarButtonColor,
    );
  }
}

// BUTTON: CUSTOM

/// Material design custom button.
class MaterialCustomButton extends StatelessWidget {
  /// Icon for [MaterialCustomButton].
  final Widget? icon;

  /// Icon size for [MaterialCustomButton].
  final double? iconSize;

  /// Icon color for [MaterialCustomButton].
  final Color? iconColor;

  /// The callback that is called when the button is tapped or otherwise activated.
  final VoidCallback onPressed;

  const MaterialCustomButton({
    Key? key,
    this.icon,
    this.iconSize,
    this.iconColor,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: icon ?? const Icon(Icons.settings),
      padding: EdgeInsets.zero,
      iconSize: iconSize ?? _theme(context).buttonBarButtonSize,
      color: iconColor ?? _theme(context).buttonBarButtonColor,
    );
  }
}

// POSITION INDICATOR

/// Material design position indicator.
class MaterialPositionIndicator extends StatefulWidget {
  /// Overriden [TextStyle] for the [MaterialPositionIndicator].
  final TextStyle? style;
  const MaterialPositionIndicator({super.key, this.style});

  @override
  MaterialPositionIndicatorState createState() =>
      MaterialPositionIndicatorState();
}

class MaterialPositionIndicatorState extends State<MaterialPositionIndicator> {
  late Duration position = controller(context).player.state.position;
  late Duration duration = controller(context).player.state.duration;

  final List<StreamSubscription> subscriptions = [];

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (subscriptions.isEmpty) {
      subscriptions.addAll(
        [
          controller(context).player.stream.position.listen((event) {
            setState(() {
              position = event;
            });
          }),
          controller(context).player.stream.duration.listen((event) {
            setState(() {
              duration = event;
            });
          }),
        ],
      );
    }
  }

  @override
  void dispose() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${position.label(reference: duration)} / ${duration.label(reference: duration)}',
      style: widget.style ??
          TextStyle(
            height: 1.0,
            fontSize: 12.0,
            color: _theme(context).buttonBarButtonColor,
          ),
    );
  }
}

class _BackwardSeekIndicator extends StatefulWidget {
  final void Function(Duration) onChanged;
  final void Function(Duration) onSubmitted;
  const _BackwardSeekIndicator({
    Key? key,
    required this.onChanged,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  State<_BackwardSeekIndicator> createState() => _BackwardSeekIndicatorState();
}

class _BackwardSeekIndicatorState extends State<_BackwardSeekIndicator> {
  Duration value = const Duration(seconds: 10);

  Timer? timer;

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 400), () {
      widget.onSubmitted.call(value);
    });
  }

  void increment() {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 400), () {
      widget.onSubmitted.call(value);
    });
    widget.onChanged.call(value);
    setState(() {
      value += const Duration(seconds: 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x88767676),
            Color(0x00767676),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: InkWell(
        splashColor: const Color(0x44767676),
        onTap: increment,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.fast_rewind,
                size: 24.0,
                color: Color(0xFFFFFFFF),
              ),
              const SizedBox(height: 8.0),
              Text(
                '${value.inSeconds} seconds',
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForwardSeekIndicator extends StatefulWidget {
  final void Function(Duration) onChanged;
  final void Function(Duration) onSubmitted;
  const _ForwardSeekIndicator({
    Key? key,
    required this.onChanged,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  State<_ForwardSeekIndicator> createState() => _ForwardSeekIndicatorState();
}

class _ForwardSeekIndicatorState extends State<_ForwardSeekIndicator> {
  Duration value = const Duration(seconds: 10);

  Timer? timer;

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 400), () {
      widget.onSubmitted.call(value);
    });
  }

  void increment() {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 400), () {
      widget.onSubmitted.call(value);
    });
    widget.onChanged.call(value);
    setState(() {
      value += const Duration(seconds: 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x00767676),
            Color(0x88767676),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: InkWell(
        splashColor: const Color(0x44767676),
        onTap: increment,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.fast_forward,
                size: 24.0,
                color: Color(0xFFFFFFFF),
              ),
              const SizedBox(height: 8.0),
              Text(
                '${value.inSeconds} seconds',
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
