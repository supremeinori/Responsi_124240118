import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/local_db_service.dart';
import 'services/news_api_service.dart';
import 'services/session_service.dart';
import 'state/app_scope.dart';
import 'state/auth_controller.dart';
import 'state/bookmark_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/state_views.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sessionService = SessionService();
  final authDatabase = LocalDbService();
  final apiService = NewsApiService();
  final authController = AuthController(
    database: authDatabase,
    sessionService: sessionService,
  );
  final bookmarkController = BookmarkController(
    dbService: authDatabase,
  );

  await authController.restoreSession();
  await bookmarkController.syncForUser(authController.currentUser?.username);

  runApp(
    SpaceNewsApp(
      authController: authController,
      bookmarkController: bookmarkController,
      apiService: apiService,
    ),
  );
}

class SpaceNewsApp extends StatefulWidget {
  const SpaceNewsApp({
    super.key,
    required this.authController,
    required this.bookmarkController,
    required this.apiService,
  });

  final AuthController authController;
  final BookmarkController bookmarkController;
  final NewsApiService apiService;

  @override
  State<SpaceNewsApp> createState() => _SpaceNewsAppState();
}

class _SpaceNewsAppState extends State<SpaceNewsApp> {
  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    widget.bookmarkController.syncForUser(
      widget.authController.currentUser?.username,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      authController: widget.authController,
      bookmarkController: widget.bookmarkController,
      apiService: widget.apiService,
      child: MaterialApp(
        title: 'SpaceNews Explorer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: ListenableBuilder(
          listenable: widget.authController,
          builder: (context, _) {
            if (!widget.authController.isInitialized) {
              return const Scaffold(
                body: LoadingView(message: 'Memeriksa sesi...'),
              );
            }
            if (!widget.authController.isLoggedIn) {
              return const LoginScreen();
            }
            return const HomeScreen();
          },
        ),
      ),
    );
  }
}
