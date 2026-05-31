import 'package:expand_widget/expand_widget.dart';
import 'package:flutter/material.dart';

/// Default expand animation duration.
const _kExpandDuration = Duration(milliseconds: 300);

/// 基于 [ExpandText] 修改
///
/// 将 `expandOnGesture` 改为 [expandOnTap] 避免滚动时触发展开/折叠，仅响应点击操作
///
/// This widget is used to show parcial text,
/// if the text is too big for the parent size.
/// You can specify the [maxLines] parameter. If the text is short enough,
/// no 'expand indicator' widget will be shown.
class ExpandableText extends StatefulWidget {
  /// Text that will be displayed.
  final String data;

  /// How long the expanding animation takes. Default is 300ms.
  final Duration animationDuration;

  /// Maximun number of lines the widget shows when it's minimized.
  ///
  /// Default is 8.
  final int maxLines;

  /// Corresponds to the style parameter of the text view.
  final TextStyle? style;

  /// Corresponds to the aling parameter of the text view.
  final TextAlign textAlign;

  /// Corresponds to the overflow parameter of the text view. Default is 'fade'.
  final TextOverflow overflow;

  /// Related to the width the widget should occupy.
  /// If 'true' it will stretch out, using all the available horizontal space.
  /// Otherwise the text widget will be centered inside its parent widget.
  /// Default is false.
  final bool expandWidth;

  /// Wheter the text view should expand/retract if the user drags on it. Default is 'true'.
  final bool expandOnTap;

  /// Ability to hide indicator from display when content is expanded.
  /// Defaults to `false`.
  final bool hideIndicatorOnExpand;

  /// Method to override the [ExpandIndicator] widget for expanding the content.
  final IndicatorBuilder? indicatorBuilder;

  /// Defines indicator rendering style.
  final ExpandIndicatorStyle expandIndicatorStyle;

  /// Message used as a tooltip when the widget is minimized.
  /// Default value set
  /// to [MaterialLocalizations.of(context).collapsedIconTapHint].
  final String? indicatorCollapsedHint;

  /// Message used as a tooltip when the widget is maximazed.
  /// Default value set
  /// to [MaterialLocalizations.of(context).expandedIconTapHint].
  final String? indicatorExpandedHint;

  /// Defines indicator padding value.
  ///
  /// Default value if this widget's icon-only: [EdgeInsets.all(4)].
  /// If text is shown: [EdgeInsets.all(8)].
  final EdgeInsets? indicatorPadding;

  /// Defines indicator icon's color. Defaults to the caption text style color.
  final Color? indicatorIconColor;

  /// Defines icon's size. Default is [24].
  final double? indicatorIconSize;

  /// Icon that will be used for the indicator.
  /// Default is [Icons.expand_more].
  final IconData? indicatorIcon;

  /// Style of the displayed message.
  final TextStyle? indicatorHintTextStyle;

  /// Autocapitalise tooltip text. Defaults to `true`.
  final bool capitalizeIndicatorHintText;

  /// Adjust horizontal alignment of the indicator.
  final Alignment? indicatorAlignment;

  const ExpandableText(
    this.data, {
    super.key,
    this.animationDuration = _kExpandDuration,
    this.maxLines = 8,
    this.style,
    this.textAlign = TextAlign.justify,
    this.overflow = TextOverflow.fade,
    this.expandWidth = false,
    this.expandOnTap = false,
    this.hideIndicatorOnExpand = false,
    this.indicatorBuilder,
    this.expandIndicatorStyle = ExpandIndicatorStyle.icon,
    this.indicatorCollapsedHint,
    this.indicatorExpandedHint,
    this.indicatorPadding,
    this.indicatorIconColor,
    this.indicatorIconSize,
    this.indicatorIcon,
    this.indicatorHintTextStyle,
    this.capitalizeIndicatorHintText = true,
    this.indicatorAlignment,
  });

  @override
  State<StatefulWidget> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText>
    with SingleTickerProviderStateMixin {
  /// Custom animation curve for indicator icon controll.
  static final _easeInCurve = CurveTween(curve: Curves.easeInOutCubic);

  /// Controlls the rotation of the indicator icon widget.
  static final _halfTurn = Tween<double>(begin: 0, end: 0.5);

  /// General animation controller.
  late AnimationController _controller;

  /// Animations for height control.
  late Animation<double> _heightFactor;

  /// Animations for indicator icon's rotation control.
  late Animation<double> _iconTurns;

  /// Auxiliary variable to controll expand status.
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    // Initializing the animation controller with the [duration] parameter
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Initializing the animation, depending on the [_easeInCurve] curve
    _heightFactor = _controller.drive(_easeInCurve);
    _iconTurns = _controller.drive(_halfTurn.chain(_easeInCurve));
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  /// Method called when the user clicks on the expand indicator,
  /// clicks or drags on the child text view.
  void _handleTap([DragEndDetails? dragDetails]) => setState(() {
        // If the user dragged the content
        if (dragDetails != null) {
          // If the drag finishes with some velocity
          // If not, no text expansion will be performed
          if (dragDetails.primaryVelocity != 0) {
            _isExpanded = dragDetails.primaryVelocity! > 0;
            dragDetails.primaryVelocity! > 0
                ? _controller.forward()
                : _controller.reverse();
          }
        } else {
          _isExpanded = !_isExpanded;
          _isExpanded ? _controller.forward() : _controller.reverse();
        }
      });

  /// Builds the widget itself. If the [_isExpanded] parameter is 'true',
  /// the [child] parameter will contain the child information, passed to
  /// this instance of the object.
  Widget _buildChildren(BuildContext context, Widget? child) {
    if (child == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, size) {
        final defaultTextStyle = (child as DefaultTextStyle).style;

        final textPainter = TextPainter(
          text: TextSpan(
            text: widget.data,
            style: defaultTextStyle,
          ),
          textDirection: TextDirection.ltr,
          maxLines: widget.maxLines,
        )..layout(maxWidth: size.maxWidth);

        return textPainter.didExceedMaxLines
            ? Column(
                crossAxisAlignment: widget.expandWidth
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSize(
                    duration: widget.animationDuration,
                    alignment: Alignment.topCenter,
                    curve: Curves.easeInOutCubic,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(),
                      child: GestureDetector(
                        onTap: widget.expandOnTap ? _handleTap : null,
                        child: child,
                      ),
                    ),
                  ),
                  ClipRect(
                    child: Align(
                      alignment: widget.indicatorAlignment ?? Alignment.center,
                      heightFactor: widget.hideIndicatorOnExpand
                          ? 1 - _heightFactor.value
                          : 1,
                      child: widget.indicatorBuilder != null
                          ? widget.indicatorBuilder!(
                              context,
                              _handleTap,
                              _isExpanded,
                            )
                          : ExpandIndicator(
                              animation: _iconTurns,
                              expandIndicatorStyle: widget.expandIndicatorStyle,
                              collapsedHint: widget.indicatorCollapsedHint,
                              onTap: _handleTap,
                              expandedHint: widget.indicatorExpandedHint,
                              padding: widget.indicatorPadding,
                              iconColor: widget.indicatorIconColor,
                              iconSize: widget.indicatorIconSize,
                              icon: widget.indicatorIcon,
                              hintTextStyle: widget.indicatorHintTextStyle,
                              capitalizeHintText:
                                  widget.capitalizeIndicatorHintText,
                            ),
                    ),
                  ),
                ],
              )
            : child;
      },
    );
  }

  /// Returns the actual maximun number of allowed lines,
  /// depending on [_isExpanded].
  /// If `overflow` is set to ellipsis, it must not return null,
  /// otherwise the entire app could explode :)
  int? get _maxLines {
    if (_isExpanded) {
      return (widget.overflow == TextOverflow.ellipsis) ? 2 ^ 64 : null;
    }

    return widget.maxLines;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildChildren,
      child: DefaultTextStyle(
        style: Theme.of(context)
            .textTheme
            .bodyMedium!
            .copyWith(color: Theme.of(context).textTheme.bodySmall?.color)
            .merge(widget.style),
        child: Text(
          widget.data,
          textAlign: widget.textAlign,
          overflow: widget.overflow,
          style: widget.style,
          maxLines: _maxLines,
        ),
      ),
    );
  }
}
