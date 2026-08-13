import 'package:flutter/material.dart';

/// Logo Talaga Coffee yang selalu mempertahankan rasio asli aset.
class TalagaLogo extends StatelessWidget {
  const TalagaLogo({super.key, required this.size});

  static const assetPath = 'assets/images/talaga_logo.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'Logo Talaga Coffee',
      ),
    );
  }
}
