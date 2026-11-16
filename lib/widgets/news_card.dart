import 'package:flutter/material.dart';

import '../models/article_model.dart';
import 'article_card.dart';

class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  final ArticleModel article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ArticleCard(article: article, onTap: onTap);
  }
}
