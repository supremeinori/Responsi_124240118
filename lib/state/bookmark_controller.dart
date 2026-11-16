import 'package:flutter/foundation.dart';

import '../models/article_model.dart';
import '../services/local_db_service.dart';

class BookmarkController extends ChangeNotifier {
  BookmarkController({required this.dbService});

  final LocalDbService dbService;

  final List<ArticleModel> _bookmarks = [];
  String? _activeUsername;

  List<ArticleModel> get bookmarks => List.unmodifiable(_bookmarks);
  int get count => _bookmarks.length;

  List<ArticleModel> get favorites => bookmarks;
  bool isFavorite(int articleId) => isBookmarked(articleId);
  Future<bool> toggleFavorite(ArticleModel article) => toggleBookmark(article);
  Future<void> removeFavorite(int articleId) => removeBookmark(articleId);

  bool isBookmarked(int articleId) {
    return _bookmarks.any((a) => a.id == articleId);
  }

  Future<void> syncForUser(String? username) async {
    if (username == null || username.isEmpty) {
      _activeUsername = null;
      _bookmarks.clear();
      notifyListeners();
      return;
    }

    if (_activeUsername == username) return;

    _activeUsername = username;
    final loaded = await dbService.getBookmarks(username);
    _bookmarks
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  Future<bool> toggleBookmark(ArticleModel article) async {
    final user = _activeUsername;
    if (user == null || user.isEmpty) return false;

    final existingIndex = _bookmarks.indexWhere((a) => a.id == article.id);
    late final bool added;

    if (existingIndex >= 0) {
      _bookmarks.removeAt(existingIndex);
      added = false;
      notifyListeners();
      await dbService.removeBookmark(user, article.id);
    } else {
      _bookmarks.insert(0, article);
      added = true;
      notifyListeners();
      await dbService.addBookmark(user, article);
    }

    return added;
  }

  Future<void> removeBookmark(int articleId) async {
    final user = _activeUsername;
    if (user == null || user.isEmpty) return;

    final beforeLength = _bookmarks.length;
    _bookmarks.removeWhere((a) => a.id == articleId);
    if (_bookmarks.length != beforeLength) {
      notifyListeners();
      await dbService.removeBookmark(user, articleId);
    }
  }
}
