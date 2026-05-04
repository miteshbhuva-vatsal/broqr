import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import 'package:cpapp/features/news/domain/entities/news_article.dart';

class _Source {
  const _Source(this.url, this.name);
  final String url;
  final String name;
}

// Verified working national RSS feeds (200 OK with items)
const _nationalSources = [
  _Source(
    'https://housing.com/news/feed/',
    'Housing.com',
  ),
  _Source(
    'https://www.magicbricks.com/blog/feed',
    'Magicbricks',
  ),
  _Source(
    'https://www.hindustantimes.com/feeds/rss/real-estate/rssfeed.xml',
    'Hindustan Times',
  ),
];

const _vernacularSources = [
  _Source(
    'https://www.amarujala.com/rss/business.xml',
    'Amar Ujala',
  ),
];

class NewsService {
  NewsService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 12),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Accept': 'application/rss+xml, application/xml, text/xml, */*',
              'User-Agent': 'Mozilla/5.0 (Linux; Android 12) CPApp/1.0',
            },
          ),
        );

  final Dio _dio;
  static const _weekAgo = Duration(days: 7);

  // ── Public unified fetch ───────────────────────────────────────────────────

  /// Fetches a deduplicated, priority-ordered feed:
  /// city news → state/regional news → national → govt → vernacular
  Future<List<NewsArticle>> fetchUnified({required String city}) async {
    final hasCity = city.trim().isNotEmpty;

    final futures = <Future<List<NewsArticle>>>[
      // 1. City-specific property news (highest priority)
      if (hasCity)
        _googleNews('property real estate $city flats apartments RERA'),
      // 2. State/regional (city used as regional proxy)
      if (hasCity)
        _googleNews('real estate housing $city construction builder'),
      // 3. National property news
      _googleNews('real estate property India RERA housing apartments buy sell'),
      // 4. Government/policy notifications
      _googleNews('RERA government housing policy notification India real estate'),
      // 5. Dedicated RSS sources
      _mergeFeeds(_nationalSources),
      // 6. Vernacular
      _googleNews('रियल एस्टेट संपत्ति RERA आवास भारत', lang: 'hi'),
      _mergeFeeds(_vernacularSources),
    ];

    final results = await Future.wait(
      futures.map((f) => f.catchError((_) => <NewsArticle>[])),
    );

    // Merge with priority order, deduplicate by link
    final seen = <String>{};
    final cutoff = DateTime.now().subtract(_weekAgo);
    final merged = <NewsArticle>[];

    for (final batch in results) {
      for (final article in batch) {
        if (!seen.add(article.link)) continue;
        // Filter to 1 week
        final pub = article.publishedAt;
        if (pub != null && pub.isBefore(cutoff)) continue;
        merged.add(article);
      }
    }

    // Sort by date descending
    merged.sort(
      (a, b) => (b.publishedAt ?? DateTime(0))
          .compareTo(a.publishedAt ?? DateTime(0)),
    );

    return merged.take(80).toList();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<List<NewsArticle>> _googleNews(String query, {String lang = 'en'}) {
    final q = Uri.encodeQueryComponent(query);
    final hl = lang == 'hi' ? 'hi' : 'en-IN';
    final ceid = lang == 'hi' ? 'IN:hi' : 'IN:en';
    final url =
        'https://news.google.com/rss/search?q=$q&hl=$hl&gl=IN&ceid=$ceid';
    return _fetchFeed(url, 'Google News');
  }

  Future<List<NewsArticle>> _mergeFeeds(List<_Source> sources) async {
    final results = await Future.wait(
      sources.map((s) => _fetchFeed(s.url, s.name).catchError((_) => <NewsArticle>[])),
    );
    return results.expand((l) => l).toList();
  }

  Future<List<NewsArticle>> _fetchFeed(
    String url,
    String defaultSource,
  ) async {
    try {
      final response = await _dio.get<String>(url);
      final body = response.data;
      if (body == null || body.isEmpty) return [];
      return _parseRss(body, defaultSource);
    } catch (_) {
      return [];
    }
  }

  List<NewsArticle> _parseRss(String xmlString, String defaultSource) {
    try {
      final doc = XmlDocument.parse(xmlString);
      return doc
          .findAllElements('item')
          .map((item) => _parseItem(item, defaultSource))
          .where((a) => a.title.isNotEmpty && a.link.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  NewsArticle _parseItem(XmlElement item, String defaultSource) {
    final title = _text(item, 'title');
    final link = _link(item);
    final description = _text(item, 'description');
    final pubDate = _parseDate(_text(item, 'pubDate'));
    final source =
        item.findElements('source').firstOrNull?.innerText.trim();

    return NewsArticle(
      id: link.isNotEmpty ? link : title,
      title: _stripHtml(title),
      description: _stripHtml(description).isNotEmpty
          ? _stripHtml(description)
          : null,
      link: link,
      imageUrl: _extractImage(item, description),
      sourceName:
          (source != null && source.isNotEmpty) ? source : defaultSource,
      publishedAt: pubDate,
    );
  }

  // ── Field extractors ───────────────────────────────────────────────────────

  String _text(XmlElement el, String tag) =>
      el.findElements(tag).firstOrNull?.innerText.trim() ?? '';

  String _link(XmlElement item) {
    final linkEl = item.findElements('link').firstOrNull;
    if (linkEl != null) {
      final href = linkEl.getAttribute('href') ?? '';
      if (href.startsWith('http')) return href;
      final text = linkEl.innerText.trim();
      if (text.startsWith('http')) return text;
    }
    final guid = item.findElements('guid').firstOrNull;
    if (guid != null) {
      final text = guid.innerText.trim();
      if (text.startsWith('http')) return text;
    }
    return '';
  }

  String? _extractImage(XmlElement item, String description) {
    // 1. <enclosure type="image/...">
    for (final el in item.findElements('enclosure')) {
      final type = el.getAttribute('type') ?? '';
      final url = el.getAttribute('url') ?? '';
      if (type.startsWith('image/') && url.startsWith('http')) return url;
    }
    // 2. Any element with name 'content' or 'thumbnail' + url attribute
    for (final el in item.descendants.whereType<XmlElement>()) {
      if (el.localName == 'content' || el.localName == 'thumbnail') {
        final url = el.getAttribute('url') ?? '';
        if (url.startsWith('http')) return url;
      }
    }
    // 3. <img src="..."> in CDATA description
    final imgMatch =
        RegExp(r'<img[^>]+src="([^"]+)"').firstMatch(description);
    final imgUrl = imgMatch?.group(1);
    if (imgUrl != null && imgUrl.startsWith('http')) return imgUrl;
    return null;
  }

  // ── Date & text utilities ─────────────────────────────────────────────────

  String _stripHtml(String html) => html
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static const _months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
    'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
    'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {}
    try {
      final m = RegExp(
        r'(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})',
      ).firstMatch(s);
      if (m != null) {
        return DateTime.utc(
          int.parse(m.group(3)!),
          _months[m.group(2)] ?? 1,
          int.parse(m.group(1)!),
          int.parse(m.group(4)!),
          int.parse(m.group(5)!),
          int.parse(m.group(6)!),
        );
      }
    } catch (_) {}
    return null;
  }
}
