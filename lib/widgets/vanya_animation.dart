import 'package:flutter/material.dart';
import 'vanya_expression.dart';

/// Backward-compatible wrapper around [VanyaCharacter]. Every existing
/// call site across the app just wants Vanya's default idle/wave pose --
/// those keep working completely unchanged. A new call site that knows
/// what Vanya should actually be feeling in that moment (listening,
/// thinking, proud, protecting, ...) should use [VanyaCharacter] directly
/// with a real [VanyaExpression] instead of growing this wrapper further.
class VanyaAnimation extends StatelessWidget {
  final double width;
  final double height;

  const VanyaAnimation({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return VanyaCharacter(expression: VanyaExpression.idle, width: width, height: height);
  }
}
