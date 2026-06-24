import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../config/style/theme_extensions.dart';
import 'util/semantic_label.dart';

@UseCase(name: 'Default', type: CircleButton)
Widget wbcircleButton(BuildContext context) {
  return const Center(
      child: CircleButton(
    radius: 25,
    icon: Icons.add,
  ));
}

class CircleButton extends StatelessWidget {
  const CircleButton(
      {super.key,
      this.radius = 15,
      this.icon,
      this.onPressed,
      this.label,
      this.color,
      this.iconColor});
  final double radius;
  final Function? onPressed;
  final IconData? icon;

  /// Screen-reader label for this icon-only button.
  final String? label;
  final Color? color;
  final Color? iconColor;
  @override
  Widget build(BuildContext context) {
    var shadows = Theme.of(context).extension<ShadowSettings>();
    return Semantics(
        button: true,
        enabled: onPressed != null,
        label: resolveButtonSemanticLabel(label),
        child: Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle, boxShadow: shadows?.shadows),
          clipBehavior: Clip.antiAlias,
          child: ClipOval(
            child: Material(
              color: color ?? Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(radius),
              child: InkWell(
                splashColor: Theme.of(context)
                    .colorScheme
                    .onSecondaryContainer, // Splash color
                onTap: onPressed == null
                    ? null
                    : () {
                        onPressed?.call();
                      },
                child: SizedBox(
                    width: radius * 2,
                    height: radius * 2,
                    child: icon != null
                        ? Align(
                            alignment: Alignment.center,
                            child: Icon(
                              color: iconColor ??
                                  Theme.of(context).colorScheme.secondary,
                              icon,
                              size: radius,
                            ))
                        : null),
              ),
            ),
          ),
        ));
  }
}
