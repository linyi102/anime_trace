import 'package:flutter/material.dart';

class EmptyDefaultPage extends StatelessWidget {
  const EmptyDefaultPage({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.buttonText,
    required this.onPressed,
  });
  final String title;
  final String subtitle;
  final String buttonText;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: onPressed, child: Text(buttonText)),
      ],
    );
  }

  // ignore: unused_element
  Container _buildStyle1(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
          ),
          if (subtitle.isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 16, color: Theme.of(context).hintColor),
                )
              ],
            ),
          const SizedBox(height: 15),
          OutlinedButton(onPressed: onPressed, child: Text(buttonText)),
        ],
      ),
    );
  }
}
