class ArticleModel {
  const ArticleModel({
    required this.id,
    required this.title,
    required this.url,
    required this.imageUrl,
    required this.newsSite,
    required this.summary,
    required this.publishedAt,
    required this.authors,
  });

  final int id;
  final String title;
  final String url;
  final String imageUrl;
  final String newsSite;
  final String summary;
  final String publishedAt;
  final List<String> authors;

  String get authorsText => authors.isEmpty ? '-' : authors.join(', ');

  String get formattedDate {
    try {
      final dt = DateTime.parse(publishedAt).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return publishedAt;
    }
  }

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final rawAuthors = json['authors'];
    final authorsList = <String>[];
    if (rawAuthors is List) {
      for (final a in rawAuthors) {
        if (a is Map && a['name'] != null) {
          authorsList.add(a['name'].toString());
        } else if (a is String) {
          authorsList.add(a);
        }
      }
    }

    return ArticleModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? 'Untitled Article').toString(),
      url: (json['url'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? json['imageUrl'] ?? '').toString(),
      newsSite: (json['news_site'] ?? json['newsSite'] ?? '-').toString(),
      summary: (json['summary'] ?? '-').toString(),
      publishedAt: (json['published_at'] ?? json['publishedAt'] ?? '-').toString(),
      authors: authorsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'image_url': imageUrl,
      'news_site': newsSite,
      'summary': summary,
      'published_at': publishedAt,
      'authors': authors,
    };
  }
}
