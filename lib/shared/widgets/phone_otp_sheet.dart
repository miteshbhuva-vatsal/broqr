import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';

/// Two-step OTP bottom sheet backed by MSG91.
/// Step 1 — user enters 10-digit mobile number → OTP sent via MSG91.
/// Step 2 — user enters 6-digit OTP → verified, Firestore updated, [onVerified] called.
class PhoneOtpSheet extends ConsumerStatefulWidget {
  const PhoneOtpSheet({
    super.key,
    this.initialPhone,
    required this.onVerified,
  });

  final String? initialPhone;
  final VoidCallback onVerified;

  @override
  ConsumerState<PhoneOtpSheet> createState() => _PhoneOtpSheetState();
}

class _PhoneOtpSheetState extends ConsumerState<PhoneOtpSheet> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();
  final _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  bool _otpSent = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null) {
      _phoneCtrl.text = widget.initialPhone!.replaceAll(RegExp(r'[^0-9]'), '');
    }
  }

  @override
  void dispose() {
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
        _verifyOtp();
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10) {
      setState(() => _error = AppLocalizations.of(context).enterValidMobile);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/otp/send',
        data: {'mobile': phone},
      );
      if (res.data?['ok'] == true) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _otpSent = true;
        });
        Future.delayed(
          const Duration(milliseconds: 100),
          () => _otpFocus.requestFocus(),
        );
        _startSmsAutoRead();
      } else {
        _setError(res.data?['error'] as String? ?? 'Failed to send OTP.');
      }
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error']?.toString();
      _setError(msg ?? 'Failed to send OTP. Check your number.');
    } catch (_) {
      _setError('Something went wrong. Please try again.');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = AppLocalizations.of(context).enterSixDigitOtp);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/otp/verify',
        data: {'mobile': _phoneCtrl.text.trim(), 'otp': otp},
      );
      if (res.data?['ok'] == true) {
        await _complete(_phoneCtrl.text.trim());
      } else {
        _setError(
          res.data?['error'] as String? ?? 'Incorrect OTP. Please try again.',
        );
      }
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['error']?.toString();
      _setError(msg ?? 'Incorrect OTP. Please try again.');
    } catch (_) {
      _setError('Something went wrong. Please try again.');
    }
  }

  Future<void> _complete(String phone) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'mobile': phone,
          'isPhoneVerified': true,
        });
      }
      if (mounted) {
        ref.read(sessionPhoneVerifiedProvider.notifier).state = true;
        Navigator.of(context).pop();
        widget.onVerified();
      }
    } catch (_) {
      if (mounted) _setError('Could not save verification. Please try again.');
    }
  }

  void _setError(String msg) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Icon + title
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.gold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _otpSent ? l.enterOtp : l.verifyMobile,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark ? AppColors.white : AppColors.navyDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _otpSent
                          ? '${l.sentTo}${_phoneCtrl.text}'
                          : l.requiredForContact,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (!_otpSent) ...[
              // Phone input
              Text(
                l.mobileLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
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
              // OTP input
              Text(
                l.otpLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
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
                  letterSpacing: 8,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  hintText: '• • • • • •',
                  hintStyle: TextStyle(letterSpacing: 8),
                ),
                onFieldSubmitted: (_) => _verifyOtp(),
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
                  l.changeNumber,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gold,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.gold,
                  ),
                ),
              ),
            ],

            // Error
            if (_error != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                  disabledBackgroundColor:
                      AppColors.gold.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.navyDark,
                        ),
                      )
                    : Text(
                        _otpSent ? l.verifyOtp : l.sendOtp,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.navyDark,
                          fontWeight: FontWeight.w700,
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
