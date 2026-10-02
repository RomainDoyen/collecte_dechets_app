import 'package:flutter/material.dart';

/// Feuille de contenu arrondie sous le header, comme dans les maquettes
/// type Leaderboard / Profile : le header reste droit, le blanc se courbe.
class RoundedSheetBody extends StatelessWidget {
  const RoundedSheetBody({super.key, required this.child});

  final Widget child;

  static const double radius = 28;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );

    return Material(
      color: Colors.white,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
