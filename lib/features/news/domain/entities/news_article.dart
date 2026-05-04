import 'package:flutter/material.dart';

enum NewsCategory {
  national,
  state,
  local,
  vernacular;

  String get label => switch (this) {
        NewsCategory.national => 'National',
        NewsCategory.state => 'State',
        NewsCategory.local => 'Local',
        NewsCategory.vernacular => 'Vernacular',
      };

  IconData get icon => switch (this) {
        NewsCategory.national => Icons.public_rounded,
        NewsCategory.state => Icons.location_on_outlined,
        NewsCategory.local => Icons.home_work_outlined,
        NewsCategory.vernacular => Icons.translate_rounded,
      };
}

class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    this.description,
    required this.link,
    this.imageUrl,
    required this.sourceName,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String link;
  final String? imageUrl;
  final String sourceName;
  final DateTime? publishedAt;
}
