import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/ask/domain/entities/ask_post.dart';

class AskPostModel extends AskPost {
  const AskPostModel({
    required super.id,
    required super.authorUid,
    required super.authorName,
    required super.authorPhotoUrl,
    required super.text,
    required super.imageUrl,
    required super.likesCount,
    required super.commentsCount,
    required super.createdAt,
    super.isBold = false,
    super.textAlign = 'left',
    super.backgroundColorHex,
    super.fontSize = 'regular',
    super.imageAspectRatio,
  });

  factory AskPostModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return AskPostModel(
      id: doc.id,
      authorUid: (d['authorUid'] as String?) ?? '',
      authorName: (d['authorName'] as String?) ?? '',
      authorPhotoUrl: d['authorPhotoUrl'] as String?,
      text: (d['text'] as String?) ?? '',
      imageUrl: d['imageUrl'] as String?,
      likesCount: (d['likesCount'] as int?) ?? 0,
      commentsCount: (d['commentsCount'] as int?) ?? 0,
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isBold: (d['isBold'] as bool?) ?? false,
      textAlign: (d['textAlign'] as String?) ?? 'left',
      backgroundColorHex: d['backgroundColorHex'] as String?,
      fontSize: (d['fontSize'] as String?) ?? 'regular',
      imageAspectRatio: (d['imageAspectRatio'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorUid': authorUid,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'text': text,
        'imageUrl': imageUrl,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'isBold': isBold,
        'textAlign': textAlign,
        'backgroundColorHex': backgroundColorHex,
        'fontSize': fontSize,
        if (imageAspectRatio != null) 'imageAspectRatio': imageAspectRatio,
      };
}
