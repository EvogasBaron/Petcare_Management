import 'dart:io';

import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.fallbackIcon = Icons.pets,
  });

  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    ImageProvider? provider;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        provider = NetworkImage(url);
      } else if (File(url).existsSync()) {
        provider = FileImage(File(url));
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundImage: provider,
      child: provider == null ? Icon(fallbackIcon, size: radius) : null,
    );
  }
}
