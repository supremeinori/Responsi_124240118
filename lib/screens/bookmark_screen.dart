import 'package:flutter/material.dart';

import '../models/article_model.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/article_card.dart';
import '../widgets/state_views.dart';
import 'article_detail_screen.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  void _openDetail(BuildContext context, ArticleModel article) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArticleDetailScreen(article: article),
      ),
    );
  }

  Future<void> _removeBookmark(
    BuildContext context,
    ArticleModel article,
  ) async {
    final bookmarks = AppScope.of(context).bookmarkController;
    await bookmarks.removeBookmark(article.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Berita dihapus dari bookmark'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkController = AppScope.of(context).bookmarkController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmark Berita'),
      ),
      body: ListenableBuilder(
        listenable: bookmarkController,
        builder: (context, _) {
          final bookmarks = bookmarkController.bookmarks;

          if (bookmarks.isEmpty) {
            return EmptyView(
              icon: Icons.bookmark_border,
              title: 'Belum Ada Bookmark',
              subtitle: 'Berita yang kamu simpan akan muncul di sini.',
              actionLabel: 'Jelajahi Berita',
              onAction: () => Navigator.of(context).pop(),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: AppTheme.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.swipe_left_outlined,
                      size: 18,
                      color: AppTheme.mutedInk,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Geser ke kiri untuk menghapus bookmark',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.border),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookmarks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final article = bookmarks[index];
                    return Dismissible(
                      key: ValueKey('bm_${article.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Hapus',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (_) => _removeBookmark(context, article),
                      child: ArticleCard(
                        article: article,
                        onTap: () => _openDetail(context, article),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
