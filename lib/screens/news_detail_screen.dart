import 'package:flutter/material.dart';

import '../models/article_model.dart';
import 'article_detail_screen.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.news});

  final ArticleModel news;

  @override
  Widget build(BuildContext context) {
    return ArticleDetailScreen(article: news);
  }
}
