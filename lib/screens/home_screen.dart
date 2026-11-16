import 'dart:async';

import 'package:flutter/material.dart';

import '../models/article_model.dart';
import '../services/news_api_service.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/article_card.dart';
import '../widgets/state_views.dart';
import 'article_detail_screen.dart';
import 'bookmark_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  final List<ArticleModel> _articles = [];
  String _selectedSite = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;
  bool _initialized = false;
  Timer? _debounce;

  static const List<String> _popularSites = [
    'All',
    'NASA',
    'SpaceNews',
    'Spaceflight Now',
    'Arstechnica',
    'European Spaceflight',
    'ESA',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadArticles();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = AppScope.of(context).apiService;
      final results = await api.fetchArticles(
        newsSite: _selectedSite == 'All' ? null : _selectedSite,
        search: _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _articles
          ..clear()
          ..addAll(results);
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat berita. Silakan coba lagi.';
        _isLoading = false;
      });
    }
  }

  void _onSiteSelected(String site) {
    if (_selectedSite == site) return;
    setState(() => _selectedSite = site);
    _loadArticles();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final trimmed = value.trim();
      if (trimmed == _searchQuery) return;
      setState(() => _searchQuery = trimmed);
      _loadArticles();
    });
    setState(() {});
  }

  void _resetFilter() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _selectedSite = 'All';
      _searchQuery = '';
    });
    _loadArticles();
  }

  void _openDetail(ArticleModel article) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArticleDetailScreen(article: article),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AppScope.of(context).authController.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final username =
        AppScope.of(context).authController.currentUser?.username ?? 'SpaceNews';

    return Scaffold(
      appBar: AppBar(
        title: Text(username),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BookmarkScreen(),
                ),
              );
            },
            tooltip: 'Bookmark',
            icon: const Icon(Icons.bookmark),
          ),
          IconButton(
            onPressed: _confirmLogout,
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari judul atau topik...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            tooltip: 'Hapus',
                            icon: const Icon(Icons.close),
                          )
                        : null,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _popularSites.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final site = _popularSites[index];
                      final selected = _selectedSite == site;
                      return ChoiceChip(
                        label: Text(site),
                        selected: selected,
                        onSelected: (_) => _onSiteSelected(site),
                        selectedColor: AppTheme.primary.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? AppTheme.primary : AppTheme.ink,
                        ),
                        side: BorderSide(
                          color: selected ? AppTheme.primary : AppTheme.border,
                        ),
                        showCheckmark: false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingView(message: 'Memuat berita antariksa...');
    }

    if (_errorMessage != null && _articles.isEmpty) {
      return ErrorView(message: _errorMessage!, onRetry: _loadArticles);
    }

    if (_articles.isEmpty) {
      final hasFilter = _selectedSite != 'All' || _searchQuery.isNotEmpty;
      return EmptyView(
        icon: Icons.newspaper_outlined,
        title: 'Berita tidak ditemukan',
        subtitle: hasFilter
            ? 'Tidak ada berita yang cocok dengan filter atau pencarian.'
            : 'Belum ada berita yang tersedia.',
        actionLabel: hasFilter ? 'Reset Filter' : 'Muat Ulang',
        onAction: hasFilter ? _resetFilter : _loadArticles,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArticles,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _articles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final article = _articles[index];
          return ArticleCard(
            article: article,
            onTap: () => _openDetail(article),
          );
        },
      ),
    );
  }
}
