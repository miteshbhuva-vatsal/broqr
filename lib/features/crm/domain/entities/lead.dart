import 'package:equatable/equatable.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum LeadStage {
  newLead,
  contacted,
  viewing,
  negotiating,
  closed,
  lost;

  String get label => switch (this) {
        LeadStage.newLead => 'New',
        LeadStage.contacted => 'Contacted',
        LeadStage.viewing => 'Viewing',
        LeadStage.negotiating => 'Negotiating',
        LeadStage.closed => 'Closed',
        LeadStage.lost => 'Lost',
      };

  /// Key stored in Firestore (avoids Dart reserved-word clash).
  String get firestoreKey => switch (this) {
        LeadStage.newLead => 'new',
        LeadStage.contacted => 'contacted',
        LeadStage.viewing => 'viewing',
        LeadStage.negotiating => 'negotiating',
        LeadStage.closed => 'closed',
        LeadStage.lost => 'lost',
      };

  static LeadStage fromString(String? v) => switch (v) {
        'new' => LeadStage.newLead,
        'contacted' => LeadStage.contacted,
        'viewing' => LeadStage.viewing,
        'negotiating' => LeadStage.negotiating,
        'closed' => LeadStage.closed,
        'lost' => LeadStage.lost,
        _ => LeadStage.newLead,
      };

  Color get color => switch (this) {
        LeadStage.newLead => AppColors.info,
        LeadStage.contacted => AppColors.warning,
        LeadStage.viewing => AppColors.gold,
        LeadStage.negotiating => AppColors.investor,
        LeadStage.closed => AppColors.success,
        LeadStage.lost => AppColors.error,
      };

  bool get isActive =>
      this != LeadStage.closed && this != LeadStage.lost;

  /// Returns the next logical stage (null if terminal).
  LeadStage? get nextStage => switch (this) {
        LeadStage.newLead => LeadStage.contacted,
        LeadStage.contacted => LeadStage.viewing,
        LeadStage.viewing => LeadStage.negotiating,
        LeadStage.negotiating => LeadStage.closed,
        LeadStage.closed => null,
        LeadStage.lost => null,
      };
}

enum LeadPriority {
  low,
  medium,
  high;

  String get label => switch (this) {
        LeadPriority.low => 'Low',
        LeadPriority.medium => 'Medium',
        LeadPriority.high => 'High',
      };

  Color get color => switch (this) {
        LeadPriority.low => AppColors.textSecondary,
        LeadPriority.medium => AppColors.warning,
        LeadPriority.high => AppColors.error,
      };

  static LeadPriority fromString(String? v) => switch (v) {
        'high' => LeadPriority.high,
        'medium' => LeadPriority.medium,
        _ => LeadPriority.low,
      };
}

// ── LeadNote ──────────────────────────────────────────────────────────────────

class LeadNote {
  const LeadNote({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LeadNote.fromMap(Map<String, dynamic> m) => LeadNote(
        id: m['id'] as String,
        text: m['text'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}

// ── Lead ──────────────────────────────────────────────────────────────────────

class Lead extends Equatable {
  const Lead({
    required this.id,
    required this.ownerUid,
    required this.clientName,
    required this.stage,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.clientPhone,
    this.estimatedValue,
    this.linkedListingId,
    this.linkedListingCity,
    this.linkedListingPrice,
    this.notes = const [],
    this.reminderAt,
    this.reminderNote,
  });

  final String id;
  final String ownerUid;
  final String clientName;
  final String? clientPhone;
  final LeadStage stage;
  final LeadPriority priority;
  final double? estimatedValue;
  final String? linkedListingId;
  final String? linkedListingCity;
  final String? linkedListingPrice;
  final List<LeadNote> notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reminderAt;
  final String? reminderNote;

  bool get isReminderOverdue =>
      reminderAt != null && reminderAt!.isBefore(DateTime.now());

  bool get isReminderToday {
    if (reminderAt == null) return false;
    final now = DateTime.now();
    final r = reminderAt!;
    return r.year == now.year && r.month == now.month && r.day == now.day;
  }

  String get displayTitle {
    final suffix = linkedListingCity != null ? ' · $linkedListingCity' : '';
    return '$clientName$suffix';
  }

  String? get latestNote =>
      notes.isNotEmpty ? notes.last.text : null;

  Lead copyWith({
    String? clientName,
    String? clientPhone,
    LeadStage? stage,
    LeadPriority? priority,
    double? estimatedValue,
    bool clearEstimatedValue = false,
    List<LeadNote>? notes,
    DateTime? updatedAt,
    DateTime? reminderAt,
    bool clearReminder = false,
    String? reminderNote,
    bool clearReminderNote = false,
  }) {
    return Lead(
      id: id,
      ownerUid: ownerUid,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      stage: stage ?? this.stage,
      priority: priority ?? this.priority,
      estimatedValue: clearEstimatedValue
          ? null
          : (estimatedValue ?? this.estimatedValue),
      linkedListingId: linkedListingId,
      linkedListingCity: linkedListingCity,
      linkedListingPrice: linkedListingPrice,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      reminderNote: clearReminderNote
          ? null
          : (reminderNote ?? this.reminderNote),
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerUid,
        clientName,
        stage,
        priority,
        updatedAt,
        reminderAt,
      ];
}
