import 'dart:math';
import 'package:cpapp/features/crm/domain/entities/lead.dart';

/// Computes a conversion-likelihood score from 0–100 based on the lead's
/// current state. Uses only fields stored on the lead document so no
/// subcollection reads are required.
///
/// Categories (max points):
///   Stage progression   35
///   Engagement velocity 25
///   Priority signal     15
///   Follow-up compliance 15
///   Lead quality        10
int computeLeadScore(Lead lead) {
  if (lead.stage == LeadStage.closed) return 100;
  if (lead.stage == LeadStage.lost) return 0;

  // ── Category 1: Stage progression (35 pts) ──────────────────────────────
  final stageScore = switch (lead.stage) {
    LeadStage.newLead => 0,
    LeadStage.contacted => 8,
    LeadStage.viewing => 18,
    LeadStage.negotiating => 28,
    LeadStage.closed => 35,
    LeadStage.lost => 0,
  };

  // ── Category 2: Engagement velocity (25 pts) ────────────────────────────
  final touchpoints = lead.touchpointCount;
  final recencyDays = lead.lastActivityAt != null
      ? DateTime.now().difference(lead.lastActivityAt!).inDays
      : 999;

  int velocityScore;
  if (touchpoints >= 5 && recencyDays <= 3) {
    velocityScore = 25;
  } else if (touchpoints >= 3 && recencyDays <= 7) {
    velocityScore = 18;
  } else if (touchpoints >= 2 && recencyDays <= 14) {
    velocityScore = 12;
  } else if (touchpoints >= 1) {
    velocityScore = 6;
  } else {
    velocityScore = 0;
  }
  if (recencyDays > 30) velocityScore = max(0, velocityScore - 5);

  // ── Category 3: Priority signal (15 pts) ────────────────────────────────
  final priorityScore = switch (lead.priority) {
    LeadPriority.high => 15,
    LeadPriority.medium => 8,
    LeadPriority.low => 2,
  };

  // ── Category 4: Follow-up compliance (15 pts) ───────────────────────────
  int reminderScore;
  if (lead.reminderAt == null) {
    reminderScore = 3;
  } else if (lead.isReminderOverdue) {
    reminderScore = 0;
  } else {
    reminderScore = 10;
  }

  // ── Category 5: Lead quality signals (10 pts) ───────────────────────────
  int qualityScore = 0;
  if (lead.clientPhone != null && lead.clientPhone!.isNotEmpty) qualityScore += 4;
  if (lead.linkedListingId != null) qualityScore += 3;
  if (lead.estimatedValue != null && lead.estimatedValue! > 0) qualityScore += 3;
  if (lead.source == LeadSource.contacted) qualityScore += 2;

  // ── Visit bonus: more property visits = higher conversion probability ───
  final visits = lead.visitCount;
  int visitBonus = 0;
  if (visits >= 5) {
    visitBonus = 12;
  } else if (visits >= 3) {
    visitBonus = 8;
  } else if (visits >= 2) {
    visitBonus = 5;
  } else if (visits == 1) {
    visitBonus = 2;
  }

  return min(100, stageScore + velocityScore + priorityScore + reminderScore + qualityScore + visitBonus);
}

/// Returns the band label for a score.
String scoreBandLabel(int score) {
  if (score >= 85) return 'Hot';
  if (score >= 65) return 'Warm';
  if (score >= 40) return 'Active';
  if (score >= 20) return 'Cold';
  return 'Dead';
}
