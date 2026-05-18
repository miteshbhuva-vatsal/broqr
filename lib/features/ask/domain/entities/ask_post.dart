import 'package:equatable/equatable.dart';

/// A community post in the Ask tab. Authored by any verified broker, visible
/// to all signed-in users. Can be text-only or text + image; images are stored
/// at a 4:5 portrait ratio (1080x1350 max).
class AskPost extends Equatable {
  const AskPost({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.text,
    required this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    this.isBold = false,
    this.textAlign = 'left',
    this.backgroundColorHex,
    this.fontSize = 'regular',
    this.imageAspectRatio,
  });

  final String id;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;

  /// Optional 4:5 image URL on Firebase Storage. Null = text-only post.
  final String? imageUrl;

  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  /// Whether the post body text is rendered bold.
  final bool isBold;

  /// Text alignment: 'left' | 'center' | 'right'.
  final String textAlign;

  /// Background for text cards. Solid: '#RRGGBB'. Gradient: '#start,#end'.
  /// When set and no image is present the post renders as a coloured card.
  final String? backgroundColorHex;

  /// Font size key: 'regular' (14px) | 'medium' (18px) | 'large' (24px).
  final String fontSize;

  /// Width / height ratio of the image. Null for text-only posts and for
  /// older posts that pre-date this field.
  final double? imageAspectRatio;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasBackground =>
      backgroundColorHex != null && backgroundColorHex!.isNotEmpty;

  AskPost copyWith({
    String? text,
    String? imageUrl,
    int? likesCount,
    int? commentsCount,
    bool? isBold,
    String? textAlign,
    String? backgroundColorHex,
    String? fontSize,
    double? imageAspectRatio,
    bool clearImage = false,
    bool clearBackground = false,
  }) {
    return AskPost(
      id: id,
      authorUid: authorUid,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      text: text ?? this.text,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt,
      isBold: isBold ?? this.isBold,
      textAlign: textAlign ?? this.textAlign,
      backgroundColorHex: clearBackground ? null : (backgroundColorHex ?? this.backgroundColorHex),
      fontSize: fontSize ?? this.fontSize,
      imageAspectRatio: imageAspectRatio ?? this.imageAspectRatio,
    );
  }

  @override
  List<Object?> get props => [
        id,
        authorUid,
        authorName,
        authorPhotoUrl,
        text,
        imageUrl,
        likesCount,
        commentsCount,
        createdAt,
        isBold,
        textAlign,
        backgroundColorHex,
        fontSize,
        imageAspectRatio,
      ];
}
