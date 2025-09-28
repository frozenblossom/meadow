import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meadow/widgets/shared/tasks_tab_icon.dart';

class MenuItem {
  final String title;
  final IconData icon;
  final Widget content;
  final List<MenuItem> subTabs;
  final Widget Function()? customIconBuilder;
  int selectedSubTabIndex = 0;

  Widget contentWidget() {
    return subTabs.isNotEmpty ? subTabs[selectedSubTabIndex].content : content;
  }

  Widget getIconWidget({Color? color, double size = 28}) {
    if (customIconBuilder != null) {
      if (title == 'Tasks') {
        return TasksTabIcon(color: color, size: size);
      }
      return customIconBuilder!();
    }
    return Icon(icon, color: color, size: size);
  }

  MenuItem({
    required this.title,
    required this.icon,
    required this.content,
    this.subTabs = const <MenuItem>[],
    this.customIconBuilder,
  });
}
