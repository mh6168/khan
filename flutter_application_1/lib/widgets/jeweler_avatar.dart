import 'package:flutter/material.dart';

import '../khan_colors.dart';
import '../models/jeweler_profile.dart';

class JewelerAvatar extends StatelessWidget {
  const JewelerAvatar({
    super.key,
    required this.profile,
    this.size = 64,
  });

  final JewelerProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logoUrl = profile.logoUrl;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: logoUrl == null
            ? _placeholder()
            : Image.network(
                logoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: khanSecondaryDark,
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_outlined,
        color: khanGold,
        size: size * 0.48,
      ),
    );
  }
}
