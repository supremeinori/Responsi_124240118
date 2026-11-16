import 'package:flutter/material.dart';

import 'bookmark_screen.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key, this.onExplorenews});

  final VoidCallback? onExplorenews;

  @override
  Widget build(BuildContext context) {
    return const BookmarkScreen();
  }
}
