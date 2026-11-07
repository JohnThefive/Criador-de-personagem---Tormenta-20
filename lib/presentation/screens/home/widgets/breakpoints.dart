import 'package:flutter/material.dart';

/// Classes de tamanho de janela baseadas nas diretrizes do Material 3.
///
/// - [compact]: Largura < 600 dp (maioria dos smartphones em modo retrato).
/// - [medium]: Largura entre 600 dp e 839 dp (tablets pequenos, dobráveis, smartphones em paisagem).
/// - [expanded]: Largura >= 840 dp (tablets grandes, desktops, monitores).
enum WindowSizeClass {
  compact,
  medium,
  expanded;

  static WindowSizeClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      return WindowSizeClass.compact;
    } else if (width < 840) {
      return WindowSizeClass.medium;
    } else {
      return WindowSizeClass.expanded;
    }
  }

  bool get isCompact => this == WindowSizeClass.compact;
  bool get isMedium => this == WindowSizeClass.medium;
  bool get isExpanded => this == WindowSizeClass.expanded;
}
