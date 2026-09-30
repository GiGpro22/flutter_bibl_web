import 'package:flutter/widgets.dart';

class Breakpoints {
  static const double compact = 600;
  static const double medium = 900;
  static const double expanded = 1200;
}

bool isCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < Breakpoints.compact;
