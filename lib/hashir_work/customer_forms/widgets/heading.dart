import 'package:flutter/material.dart';

import '../theme/customer_theme.dart';

class Heading extends StatelessWidget {
  const Heading(this.title, {super.key, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18, top: 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: green,
                  letterSpacing: -.7,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(color: muted, height: 1.5),
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
