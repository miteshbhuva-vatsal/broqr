import 'package:flutter/material.dart';
import 'package:cpapp/core/theme/app_colors.dart';

enum LeadActivityType {
  leadCreated,
  callMade,
  messageSent,
  stageChanged,
  priorityChanged,
  leadAssigned,
  callScheduled,
  remarkAdded,
  noteAdded;

  String get firestoreKey => switch (this) {
        LeadActivityType.leadCreated => 'lead_created',
        LeadActivityType.callMade => 'call_made',
        LeadActivityType.messageSent => 'message_sent',
        LeadActivityType.stageChanged => 'stage_changed',
        LeadActivityType.priorityChanged => 'priority_changed',
        LeadActivityType.leadAssigned => 'lead_assigned',
        LeadActivityType.callScheduled => 'call_scheduled',
        LeadActivityType.remarkAdded => 'remark_added',
        LeadActivityType.noteAdded => 'note_added',
      };

  static LeadActivityType fromString(String? v) => switch (v) {
        'lead_created' => LeadActivityType.leadCreated,
        'call_made' => LeadActivityType.callMade,
        'message_sent' => LeadActivityType.messageSent,
        'stage_changed' => LeadActivityType.stageChanged,
        'priority_changed' => LeadActivityType.priorityChanged,
        'lead_assigned' => LeadActivityType.leadAssigned,
        'call_scheduled' => LeadActivityType.callScheduled,
        'remark_added' => LeadActivityType.remarkAdded,
        _ => LeadActivityType.noteAdded,
      };

  IconData get icon => switch (this) {
        LeadActivityType.leadCreated => Icons.add_circle_outline_rounded,
        LeadActivityType.callMade => Icons.phone_rounded,
        LeadActivityType.messageSent => Icons.chat_rounded,
        LeadActivityType.stageChanged => Icons.swap_horiz_rounded,
        LeadActivityType.priorityChanged => Icons.flag_rounded,
        LeadActivityType.leadAssigned => Icons.person_add_alt_1_rounded,
        LeadActivityType.callScheduled => Icons.alarm_rounded,
        LeadActivityType.remarkAdded => Icons.format_quote_rounded,
        LeadActivityType.noteAdded => Icons.sticky_note_2_outlined,
      };

  Color get color => switch (this) {
        LeadActivityType.leadCreated => AppColors.navyMid,
        LeadActivityType.callMade => AppColors.success,
        LeadActivityType.messageSent => const Color(0xFF25D366),
        LeadActivityType.stageChanged => AppColors.info,
        LeadActivityType.priorityChanged => AppColors.warning,
        LeadActivityType.leadAssigned => const Color(0xFF7C3AED),
        LeadActivityType.callScheduled => AppColors.warning,
        LeadActivityType.remarkAdded => AppColors.gold,
        LeadActivityType.noteAdded => AppColors.textSecondary,
      };
}

class LeadActivity {
  const LeadActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.createdAt,
    this.actorName,
    this.metadata,
  });

  final String id;
  final LeadActivityType type;
  final String description;
  final String? actorName;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  int? get leadScore => metadata?['leadScore'] as int?;
  int? get scoreDelta => metadata?['scoreDelta'] as int?;
}
