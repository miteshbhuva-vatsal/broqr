import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/news/domain/entities/news_article.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key, required this.article});

  final NewsArticle article;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _loadProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A1628))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _loadProgress = p);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.article.link));
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.article.link);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.article.sourceName,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.article.publishedAt != null)
              Text(
                _formatDate(widget.article.publishedAt!),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Share',
            onPressed: () => Share.share(
              widget.article.link,
              subject: widget.article.title,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded, size: 20),
            tooltip: 'Open in browser',
            onPressed: _openInBrowser,
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadProgress > 0 ? _loadProgress / 100 : null,
                  backgroundColor: AppColors.navyMid,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    return '${local.day} ${months[local.month - 1]} ${local.year}  $h:$m $ampm';
  }
}
