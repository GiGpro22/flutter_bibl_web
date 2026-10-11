import 'package:flutter/material.dart';

enum ScreenSize { compact, medium, expanded, extraLarge }

class Breakpoints {
  static const double compact = 600;
  static const double medium = 1100;
  static const double expanded = 1600;
  static const double contentMaxWidth = 1240;
}

bool isCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < Breakpoints.compact;

bool isMedium(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width >= Breakpoints.compact && width < Breakpoints.expanded;
}

bool isExpanded(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= Breakpoints.expanded;

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < Breakpoints.compact) return ScreenSize.compact;
  if (width < Breakpoints.medium) return ScreenSize.medium;
  if (width < Breakpoints.expanded) return ScreenSize.expanded;
  return ScreenSize.extraLarge;
}

T byScreen<T>(
  BuildContext context, {
  required T compact,
  T? medium,
  T? expanded,
  T? extraLarge,
}) {
  return switch (screenSizeOf(context)) {
    ScreenSize.compact => compact,
    ScreenSize.medium => medium ?? compact,
    ScreenSize.expanded => expanded ?? medium ?? compact,
    ScreenSize.extraLarge => extraLarge ?? expanded ?? medium ?? compact,
  };
}
