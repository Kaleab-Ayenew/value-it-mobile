import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.body,
    this.navigation,
    this.title,
  });

  final Widget body;
  final Widget? navigation;
  final String? title;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600;

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context) && navigation != null;
    if (!wide) {
      return Scaffold(
        appBar: title != null ? AppBar(title: Text(title!)) : null,
        body: body,
      );
    }
    return Scaffold(
      body: Row(
        children: [
          navigation!,
          Expanded(child: body),
        ],
      ),
    );
  }
}
