import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/ask/domain/entities/ask_comment.dart';

class AskCommentModel extends AskComment {
  const AskCommentModel({
    required super.id,
    required super.postId,
    required super.authorUid,
    required super.authorName,
    required super.authorPhotoUrl,
    required super.text,
    required super.createdAt,
  });

  factory AskCommentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String postId,
  ) {
    final d = doc.data() ?? {};
    return AskCommentModel(
      id: doc.id,
      postId: postId,
      authorUid: (d['authorUid'] as String?) ?? '',
      authorName: (d['authorName'] as String?) ?? '',
      authorPhotoUrl: d['authorPhotoUrl'] as String?,
      text: (d['text'] as String?) ?? '',
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorUid': authorUid,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
