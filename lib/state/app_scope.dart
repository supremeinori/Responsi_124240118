import 'package:flutter/widgets.dart';

import '../services/news_api_service.dart';
import 'auth_controller.dart';
import 'bookmark_controller.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.authController,
    required this.bookmarkController,
    required this.apiService,
    required super.child,
  });

  final AuthController authController;
  final BookmarkController bookmarkController;
  final NewsApiService apiService;

  BookmarkController get favoritesController => bookmarkController;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return authController != oldWidget.authController ||
        bookmarkController != oldWidget.bookmarkController ||
        apiService != oldWidget.apiService;
  }
}
