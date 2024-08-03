import 'package:flutter/material.dart';

class SettingCard extends StatelessWidget {
  const SettingCard(
      {required this.title,
      this.children = const [],
      this.trailing,
      this.titleStyle,
      this.useCard = true,
      this.innerTitleCard = false,
      super.key});
  final String title;
  final TextStyle? titleStyle;
  final List<Widget> children;
  final Widget? trailing;
  final bool useCard;
  final bool innerTitleCard;

  @override
  Widget build(BuildContext context) {
    if (innerTitleCard) {
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleTile(
              context,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            Column(children: children),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleTile(
          context,
          margin: const EdgeInsets.only(top: 20, bottom: 5),
          padding: EdgeInsets.symmetric(horizontal: useCard ? 20 : 16),
        ),
        useCard
            ? Card(child: Column(children: children))
            : Column(children: children),
      ],
    );
  }

  Container _buildTitleTile(
    BuildContext context, {
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      child: Row(
        children: [
          _buildTitle(context),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Text _buildTitle(BuildContext context) {
    return Text(
      title,
      style: titleStyle ??
          Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).primaryColor),
    );
  }
}
