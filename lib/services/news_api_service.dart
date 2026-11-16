import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/article_model.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NewsApiService {
  NewsApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl =
      'https://api.spaceflightnewsapi.net/v4/articles';
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  Future<List<ArticleModel>> fetchArticles({
    String? newsSite,
    String? search,
  }) async {
    final queryParams = <String, String>{'limit': '30'};

    if (newsSite != null &&
        newsSite.isNotEmpty &&
        newsSite.toLowerCase() != 'all') {
      queryParams['news_site'] = newsSite;
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

    try {
      final res = await _client.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final rawList = decoded is Map ? decoded['results'] : decoded;
        if (rawList is List) {
          return rawList
              .whereType<Map>()
              .map(
                (item) =>
                    ArticleModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
        }
        return [];
      }
      throw ApiException(
        'Gagal memuat berita dari server (kode ${res.statusCode}).',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Koneksi habis waktu. Periksa jaringan Anda lalu coba lagi.',
      );
    } catch (_) {
      throw const ApiException('Gagal terhubung ke server SpaceNews.');
    }
  }
}
