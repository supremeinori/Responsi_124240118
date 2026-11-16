import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article_model.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';

class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({super.key, required this.article});

  final ArticleModel article;

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan artikel tidak valid.')),
      );
      return;
    }

    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka tautan di browser.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka browser.')),
        );
      }
    }
  }

  Future<void> _toggleBookmark(BuildContext context) async {
    final bookmarks = AppScope.of(context).bookmarkController;
    final added = await bookmarks.toggleBookmark(article);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added
                ? 'Berita berhasil ditambahkan ke bookmark'
                : 'Berita dihapus dari bookmark',
          ),
          backgroundColor: added ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkController = AppScope.of(context).bookmarkController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Berita'),
        actions: [
          ListenableBuilder(
            listenable: bookmarkController,
            builder: (context, _) {
              final isBookmarked = bookmarkController.isBookmarked(article.id);
              return IconButton(
                onPressed: () => _toggleBookmark(context),
                tooltip: isBookmarked ? 'Hapus bookmark' : 'Tambah bookmark',
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? Colors.amber[700] : AppTheme.ink,
                  size: 26,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: article.imageUrl.isNotEmpty
                        ? Image.network(
                            article.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: AppTheme.border,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: AppTheme.mutedInk,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.border,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.newspaper_outlined,
                              size: 48,
                              color: AppTheme.mutedInk,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.source_outlined,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.newsSite,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: AppTheme.mutedInk,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.formattedDate,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.mutedInk,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppTheme.mutedInk,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.authorsText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.mutedInk,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 28, color: AppTheme.border),
                const Text(
                  'Ringkasan Berita',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  article.summary,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.6,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _launchUrl(context, article.url),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Read Full Article'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
