import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
class AppTheme {
  static ThemeData get dark => ThemeData(
    scaffoldBackgroundColor: CupertinoColors.darkBackgroundGray,
    primaryColor: Color.fromARGB(255, 54, 54, 54),
  );
}


class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}