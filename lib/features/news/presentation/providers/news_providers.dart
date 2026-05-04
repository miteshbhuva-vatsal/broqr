import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/news/data/services/news_service.dart';
import 'package:cpapp/features/news/domain/entities/news_article.dart';

// ── Service ───────────────────────────────────────────────────────────────────

final newsServiceProvider = Provider<NewsService>((ref) => NewsService());

// ── State ─────────────────────────────────────────────────────────────────────

class NewsState {
  const NewsState({
    this.articles = const [],
    this.isLoading = false,
    this.error,
    this.lastFetched,
  });

  final List<NewsArticle> articles;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetched;

  NewsState copyWith({
    List<NewsArticle>? articles,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? lastFetched,
  }) =>
      NewsState(
        articles: articles ?? this.articles,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        lastFetched: lastFetched ?? this.lastFetched,
      );
}

// ── Notifier (auto-refreshes every hour) ─────────────────────────────────────

class NewsNotifier extends StateNotifier<NewsState> {
  NewsNotifier(this._service, this._city)
      : super(const NewsState(isLoading: true)) {
    _load();
    _timer = Timer.periodic(const Duration(hours: 1), (_) => _load());
  }

  final NewsService _service;
  final String _city;
  Timer? _timer;

  Future<void> _load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final articles = await _service.fetchUnified(city: _city);
      if (mounted) {
        state = NewsState(
          articles: articles,
          lastFetched: DateTime.now(),
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> refresh() => _load();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final newsProvider =
    StateNotifierProvider<NewsNotifier, NewsState>((ref) {
  final city =
      ref.watch(authStateChangesProvider).valueOrNull?.city ?? '';
  return NewsNotifier(ref.read(newsServiceProvider), city);
});
