import 'package:flutter/material.dart';

class CommonStatusPrompt extends StatelessWidget {
  const CommonStatusPrompt({
    super.key,
    required this.icon,
    required this.titleText,
    this.subtitleText,
    this.subtitle,
    required this.buttonText,
    required this.onTapButton,
  });
  final IconData icon;
  final String titleText;
  final String? subtitleText;
  final Widget? subtitle;
  final String buttonText;
  final void Function() onTapButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 30, 0),
            child: Icon(icon),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titleText,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                if (subtitleText != null)
                  Text(
                    subtitleText!,
                    style: TextStyle(
                        fontSize: 14, color: Theme.of(context).hintColor),
                  ),
                if (subtitle != null) subtitle!,
                const SizedBox(height: 10),
                ElevatedButton(onPressed: onTapButton, child: Text(buttonText))
              ],
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}
