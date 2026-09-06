import 'package:flutter/material.dart';

import '../motion/motion_tokens.dart';
import '../motion/press_scale.dart';
import '../theme/app_palette.dart';

/// Persistent tab bar under the AppBar with an animated indicator.
class AnimatedTabBar extends StatelessWidget {
  const AnimatedTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onChanged,
  });
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabs.length;
          return SizedBox(
            height: 46,
            child: Stack(
              children: [
                AnimatedPositionedDirectional(
                  duration: effectiveDuration(context, MotionTokens.medium),
                  curve: MotionTokens.emphasized,
                  start: tabWidth * currentIndex,
                  width: tabWidth,
                  bottom: 0,
                  height: 3,
                  child: Center(
                    child: Container(
                      width: tabWidth * 0.55,
                      height: 3,
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (int i = 0; i < tabs.length; i++)
                      Expanded(
                        child: PressScale(
                          onTap: () => onChanged(i),
                          child: SizedBox(
                            height: 46,
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: effectiveDuration(
                                    context, MotionTokens.short),
                                curve: MotionTokens.standard,
                                style: TextStyle(
                                  color: currentIndex == i ? c.primary : c.ink2,
                                  fontSize: 13,
                                  fontWeight: currentIndex == i
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                                child: Text(tabs[i]),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
