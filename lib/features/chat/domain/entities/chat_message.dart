import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.read = false,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool read;

  @override
  List<Object?> get props => [id, senderId, text, timestamp, read];
}
