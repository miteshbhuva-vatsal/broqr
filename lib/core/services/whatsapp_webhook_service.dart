import 'package:dio/dio.dart';

/// Fire-and-forget WhatsApp automation via TurboDev.ai generic webhook.
///
/// All public methods are best-effort — they never throw and never block
/// the calling CRM operation. If the webhook is unreachable the CRM still
/// works normally.
class WhatsAppWebhookService {
  WhatsAppWebhookService._();

  static const _webhookUrl =
      'https://v2.api.turbodev.ai/workspace/696df09e9b8010eb2c728088'
      '/integrations/genericWebhook/69ff8a21dbb48312938b9ea8/webhook';

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Normalises an Indian mobile number to the `91XXXXXXXXXX` format expected
  /// by WhatsApp. Returns null if the number is blank or clearly invalid.
  static String? _normalisePhone(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('91') && digits.length == 12) return digits;
    if (digits.length == 10) return '91$digits';
    // Already has country code or unknown format — pass through.
    return digits;
  }

  static Future<void> _post(Map<String, dynamic> payload) async {
    try {
      await _dio.post<void>(_webhookUrl, data: payload);
    } catch (_) {
      // Best-effort; swallow all errors silently.
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Called when a new lead is created in the CRM.
  static Future<void> notifyLeadCreated({
    required String clientName,
    required String? clientPhone,
    required String stage,
    required String priority,
    String? linkedListingCity,
    String? linkedListingPrice,
  }) async {
    final phone = _normalisePhone(clientPhone);
    if (phone == null) return;
    unawaited(_post({
      'phone': phone,
      'name': clientName,
      'event': 'lead_created',
      'stage': stage,
      'priority': priority,
      if (linkedListingCity != null) 'city': linkedListingCity,
      if (linkedListingPrice != null) 'price': linkedListingPrice,
    }),);
  }

  /// Called when a lead's stage changes (e.g. newLead → viewing).
  static Future<void> notifyStageChanged({
    required String clientName,
    required String? clientPhone,
    required String oldStage,
    required String newStage,
  }) async {
    final phone = _normalisePhone(clientPhone);
    if (phone == null) return;
    unawaited(_post({
      'phone': phone,
      'name': clientName,
      'event': 'stage_changed',
      'old_stage': oldStage,
      'new_stage': newStage,
    }),);
  }

  /// Called when a lead is assigned to a team or member.
  static Future<void> notifyLeadAssigned({
    required String clientName,
    required String? clientPhone,
    required String assigneeName,
  }) async {
    final phone = _normalisePhone(clientPhone);
    if (phone == null) return;
    unawaited(_post({
      'phone': phone,
      'name': clientName,
      'event': 'lead_assigned',
      'assignee': assigneeName,
    }),);
  }
}

// Convenience top-level function so callers don't need a package import.
void unawaited(Future<void> future) {}
