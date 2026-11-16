import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/article_model.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class LocalDbService {
  LocalDbService({this.usePrefs = false, SharedPreferences? prefs}) {
    if (prefs != null) {
      _prefs = prefs;
    }
  }

  final bool usePrefs;

  static const String _dbName = 'spacenews_explorer.db';
  static const String _tableUsers = 'users';
  static const String _tableBookmarks = 'bookmarks';
  static const String _webUsersKey = 'local_db_users_v1';
  static const String _webBookmarksKey = 'local_db_bookmarks_v1';

  Database? _database;
  SharedPreferences? _prefs;

  bool get _isPrefsMode => kIsWeb || usePrefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Database> _getDb() async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableUsers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            username TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $_tableBookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            article_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            url TEXT NOT NULL,
            image_url TEXT NOT NULL,
            news_site TEXT NOT NULL,
            summary TEXT NOT NULL,
            published_at TEXT NOT NULL,
            authors TEXT NOT NULL,
            UNIQUE(username, article_id)
          )
        ''');
      },
    );
    return _database!;
  }

  String _normalizeUsername(String username) => username.trim().toLowerCase();

  String _hashPassword(String normalizedUsername, String password) {
    final bytes = utf8.encode('$normalizedUsername:$password');
    return sha256.convert(bytes).toString();
  }

  // Auth Operations
  Future<UserModel> registerUser({
    required String name,
    required String username,
    required String password,
  }) async {
    final cleanName = name.trim();
    final normalizedUsername = _normalizeUsername(username);
    if (cleanName.isEmpty || normalizedUsername.isEmpty || password.isEmpty) {
      throw const AuthException('Semua kolom wajib diisi.');
    }

    final passwordHash = _hashPassword(normalizedUsername, password);
    final createdAt = DateTime.now().toIso8601String();

    if (_isPrefsMode) {
      final prefs = await _getPrefs();
      final users = _readWebUsers(prefs);
      final exists = users.any((u) => u['username'] == normalizedUsername);
      if (exists) {
        throw const AuthException(
          'Username sudah terdaftar. Gunakan username lain.',
        );
      }
      final nextId = users.isEmpty
          ? 1
          : users
                  .map((u) => (u['id'] as num?)?.toInt() ?? 0)
                  .reduce((a, b) => a > b ? a : b) +
              1;
      final newUser = <String, dynamic>{
        'id': nextId,
        'name': cleanName,
        'username': normalizedUsername,
        'password_hash': passwordHash,
        'created_at': createdAt,
      };
      users.add(newUser);
      await prefs.setString(_webUsersKey, jsonEncode(users));
      return UserModel(
        id: nextId,
        name: cleanName,
        username: normalizedUsername,
      );
    }

    final db = await _getDb();
    final existing = await db.query(
      _tableUsers,
      columns: ['id'],
      where: 'username = ?',
      whereArgs: [normalizedUsername],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw const AuthException(
        'Username sudah terdaftar. Gunakan username lain.',
      );
    }

    final id = await db.insert(_tableUsers, {
      'name': cleanName,
      'username': normalizedUsername,
      'password_hash': passwordHash,
      'created_at': createdAt,
    });

    return UserModel(id: id, name: cleanName, username: normalizedUsername);
  }

  Future<UserModel?> authenticateUser({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = _normalizeUsername(username);
    if (normalizedUsername.isEmpty || password.isEmpty) {
      return null;
    }

    final passwordHash = _hashPassword(normalizedUsername, password);

    if (_isPrefsMode) {
      final prefs = await _getPrefs();
      final users = _readWebUsers(prefs);
      for (final user in users) {
        if (user['username'] == normalizedUsername &&
            user['password_hash'] == passwordHash) {
          return UserModel.fromMap(user);
        }
      }
      return null;
    }

    final db = await _getDb();
    final rows = await db.query(
      _tableUsers,
      columns: ['id', 'name', 'username'],
      where: 'username = ? AND password_hash = ?',
      whereArgs: [normalizedUsername, passwordHash],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  // Bookmark Operations (Local Database)
  Future<void> addBookmark(String username, ArticleModel article) async {
    final normalized = _normalizeUsername(username);
    if (_isPrefsMode) {
      final prefs = await _getPrefs();
      final bookmarks = _readWebBookmarks(prefs, normalized);
      bookmarks.removeWhere((b) => b.id == article.id);
      bookmarks.insert(0, article);
      await _writeWebBookmarks(prefs, normalized, bookmarks);
      return;
    }

    final db = await _getDb();
    await db.insert(
      _tableBookmarks,
      {
        'username': normalized,
        'article_id': article.id,
        'title': article.title,
        'url': article.url,
        'image_url': article.imageUrl,
        'news_site': article.newsSite,
        'summary': article.summary,
        'published_at': article.publishedAt,
        'authors': jsonEncode(article.authors),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeBookmark(String username, int articleId) async {
    final normalized = _normalizeUsername(username);
    if (_isPrefsMode) {
      final prefs = await _getPrefs();
      final bookmarks = _readWebBookmarks(prefs, normalized);
      bookmarks.removeWhere((b) => b.id == articleId);
      await _writeWebBookmarks(prefs, normalized, bookmarks);
      return;
    }

    final db = await _getDb();
    await db.delete(
      _tableBookmarks,
      where: 'username = ? AND article_id = ?',
      whereArgs: [normalized, articleId],
    );
  }

  Future<List<ArticleModel>> getBookmarks(String username) async {
    final normalized = _normalizeUsername(username);
    if (_isPrefsMode) {
      final prefs = await _getPrefs();
      return _readWebBookmarks(prefs, normalized);
    }

    final db = await _getDb();
    final rows = await db.query(
      _tableBookmarks,
      where: 'username = ?',
      whereArgs: [normalized],
      orderBy: 'id DESC',
    );

    return rows.map((r) {
      List<String> authorsList = [];
      try {
        final decoded = jsonDecode(r['authors'] as String);
        if (decoded is List) {
          authorsList = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}

      return ArticleModel(
        id: (r['article_id'] as num).toInt(),
        title: (r['title'] ?? '').toString(),
        url: (r['url'] ?? '').toString(),
        imageUrl: (r['image_url'] ?? '').toString(),
        newsSite: (r['news_site'] ?? '').toString(),
        summary: (r['summary'] ?? '').toString(),
        publishedAt: (r['published_at'] ?? '').toString(),
        authors: authorsList,
      );
    }).toList();
  }

  List<Map<String, dynamic>> _readWebUsers(SharedPreferences prefs) {
    final raw = prefs.getString(_webUsersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((i) => Map<String, dynamic>.from(i))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<ArticleModel> _readWebBookmarks(
    SharedPreferences prefs,
    String username,
  ) {
    final raw = prefs.getString('${_webBookmarksKey}_$username');
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((i) => ArticleModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeWebBookmarks(
    SharedPreferences prefs,
    String username,
    List<ArticleModel> list,
  ) async {
    final raw = jsonEncode(list.map((a) => a.toJson()).toList());
    await prefs.setString('${_webBookmarksKey}_$username', raw);
  }
}
