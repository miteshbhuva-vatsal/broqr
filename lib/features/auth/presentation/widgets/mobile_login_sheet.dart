import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/providers/navigation_overrides.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';

/// Two-step mobile OTP login sheet backed by MSG91 + Firebase custom token.
///
/// Step 1 — enter 10-digit mobile → OTP sent via MSG91.
/// Step 2 — enter 6-digit OTP → verified, Firebase custom token issued,
///           any pending org invite auto-accepted, sheet dismissed.
///
/// After the sheet pops the router takes over: it routes the user to
/// /persona-selection, /profile-setup, /onboarding, or /feed depending
/// on their profile completeness — no navigation logic lives here.
class MobileLoginSheet extends ConsumerStatefulWidget {
  const MobileLoginSheet({super.key});

  @override
  ConsumerState<MobileLoginSheet> createState() => _MobileLoginSheetState();
}

class _MobileLoginSheetState extends ConsumerState<MobileLoginSheet> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus   = FocusNode();
  final _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  bool _otpSent   = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    // Do NOT clear mobileAuthFlowPendingProvider here.
    // The router listener owns this flag and clears it via microtask once
    // authStateChangesProvider fully resolves. Clearing here is unreliable:
    // StreamProvider preserves the previous AsyncData(null) value while
    // asyncMap is still running, so isLoading is false before Firestore
    // responds — premature clearing unblocks the router while user == null,
    // causing a login-screen flash between OTP success and persona selection.
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    SmartAuth.instance.removeUserConsentApiListener();
    super.dispose();
  }

  void _startSmsAutoRead() {
    SmartAuth.instance
        .getSmsWithUserConsentApi(matcher: r'\d{6}')
        .then((result) {
      if (!mounted) return;
      if (result.hasData && result.data?.code != null) {
        _otpCtrl.text = result.data!.code!;
        _verifyAndLogin();
      }
    });
  }

  static String? _extractError(dynamic data) {
    if (data is Map) return data['error']?.toString();
    return null;
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await _dio.post<dynamic>('/api/otp/send', data: {'mobile': phone});
      final data = res.data;
      if (data is Map && data['ok'] == true) {
        if (!mounted) return;
        setState(() { _isLoading = false; _otpSent = true; });
        Future.delayed(
          const Duration(milliseconds: 100),
          () => _otpFocus.requestFocus(),
        );
        _startSmsAutoRead();
      } else {
        _setError(_extractError(data) ?? 'Failed to send OTP.');
      }
    } on DioException catch (e) {
      _setError(_extractError(e.response?.data) ?? 'Failed to send OTP. Check your number.');
    } catch (_) {
      _setError('Something went wrong. Please try again.');
    }
  }

  Future<void> _verifyAndLogin() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await _dio.post<dynamic>(
        '/api/otp/login',
        data: {'mobile': _phoneCtrl.text.trim(), 'otp': otp},
      );
      final data = res.data;
      if (data is Map && data['ok'] == true) {
        final token = data['token'] as String;

        // Block router redirects while we finish the post-auth sequence.
        ref.read(mobileAuthFlowPendingProvider.notifier).state = true;
        await FirebaseAuth.instance.signInWithCustomToken(token);
        if (!mounted) return;

        // Auto-accept any mobile-verified pending org invite.
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (uid.isNotEmpty) {
          final welcome = await ref
              .read(orgActionsProvider.notifier)
              .acceptInviteByMobile(
                mobile: _phoneCtrl.text.trim(),
                brokerUid: uid,
              );
          if (!mounted) return;
          if (welcome != null) {
            await _showWelcomeDialog(welcome.orgName, welcome.adminName);
            if (!mounted) return;
          }
        }

        // Done — router now owns all navigation decisions (persona, profile, feed).
        Navigator.of(context).pop();
      } else {
        _setError(_extractError(data) ?? 'Incorrect OTP. Please try again.');
      }
    } on DioException catch (e) {
      _setError(_extractError(e.response?.data) ?? 'Incorrect OTP. Please try again.');
    } catch (_) {
      _setError('Something went wrong. Please try again.');
    }
  }

  Future<void> _showWelcomeDialog(String orgName, String adminName) {
    final displayOrg = orgName.isNotEmpty ? orgName : 'your organisation';
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navyDark, AppColors.navyMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.domain_rounded, color: AppColors.gold, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    orgName.isNotEmpty ? orgName : 'Welcome',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.white, fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (adminName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Invited by $adminName',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  Text(
                    'Welcome aboard!',
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You've successfully joined $displayOrg. "
                    'Explore the team feed, manage leads, and collaborate with your team.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navyDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Get Started',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w700, color: AppColors.navyDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setError(String msg) {
    if (mounted) setState(() { _isLoading = false; _error = msg; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.navyMid : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_android_outlined, color: AppColors.gold, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _otpSent ? 'Enter OTP' : 'Sign in with Mobile',
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark ? AppColors.white : AppColors.navyDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _otpSent
                          ? 'Sent to +91 ${_phoneCtrl.text}'
                          : "We'll send you a one-time password",
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (!_otpSent) ...[
              Text(
                'Mobile Number',
                style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                focusNode: _phoneFocus,
                autofocus: true,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  hintText: '9876543210',
                  prefixText: '+91  ',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                onFieldSubmitted: (_) => _sendOtp(),
              ),
            ] else ...[
              Text(
                'One-Time Password',
                style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _otpCtrl,
                focusNode: _otpFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  letterSpacing: 8, fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  hintText: '• • • • • •',
                  hintStyle: TextStyle(letterSpacing: 8),
                ),
                onFieldSubmitted: (_) => _verifyAndLogin(),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : () => setState(() {
                          _otpSent = false;
                          _otpCtrl.clear();
                          _error = null;
                        }),
                child: Text(
                  'Change number',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gold,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.gold,
                  ),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_otpSent ? _verifyAndLogin : _sendOtp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                  disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyDark),
                      )
                    : Text(
                        _otpSent ? 'Verify & Sign In' : 'Send OTP',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.navyDark, fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
