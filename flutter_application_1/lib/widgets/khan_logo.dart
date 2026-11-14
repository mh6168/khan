import 'package:flutter/material.dart';

class KhanLogo extends StatelessWidget {
  const KhanLogo({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/khan_logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Khan',
    );
  }
}
