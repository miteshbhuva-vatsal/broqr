import 'package:equatable/equatable.dart';

/// Flat comment on an [AskPost]. No nested replies.
class AskComment extends Equatable {
  const AskComment({
    required this.id,
    required this.postId,
    required this.authorUid,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;

  @override
  List<Object?> get props =>
      [id, postId, authorUid, authorName, authorPhotoUrl, text, createdAt];
}
