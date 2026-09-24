import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

enum _OtpStep { enterPhone, enterCode }

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  _OtpStep _step = _OtpStep.enterPhone;
  Timer? _resendTimer;
  int _resendSecondsLeft = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSecondsLeft = AppConstants.otpResendSeconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSecondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _resendSecondsLeft--);
      }
    });
  }

  void _requestOtp() {
    if (!_phoneFormKey.currentState!.validate()) return;
    final phone = '+91${_phoneController.text.trim()}'; // India default; adjust per market
    ref.read(otpAuthControllerProvider.notifier).requestOtp(phone).then((_) {
      final controller = ref.read(otpAuthControllerProvider.notifier);
      if (controller.verificationId != null && mounted) {
        setState(() => _step = _OtpStep.enterCode);
        _startResendTimer();
      }
    });
  }

  void _confirmOtp() {
    if (_otpController.text.trim().length != AppConstants.otpLength) return;
    ref.read(otpAuthControllerProvider.notifier).confirmOtp(_otpController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(otpAuthControllerProvider);

    ref.listen(otpAuthControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString()), backgroundColor: AppColors.error),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with OTP')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _step == _OtpStep.enterPhone
                  ? _buildPhoneStep(authState.isLoading)
                  : _buildCodeStep(authState.isLoading),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep(bool isLoading) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter your mobile number', style: AppTextStyles.headingLarge),
          const SizedBox(height: 4),
          Text("We'll send a one-time code to verify it's you.",
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
          AppTextField(
            controller: _phoneController,
            label: 'Mobile number',
            hint: '10-digit number',
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined),
            validator: Validators.mobileNumber,
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Send OTP', isLoading: isLoading, onPressed: _requestOtp),
        ],
      ),
    );
  }

  Widget _buildCodeStep(bool isLoading) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 52,
      textStyle: AppTextStyles.headingSmall,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter the code', style: AppTextStyles.headingLarge),
        const SizedBox(height: 4),
        Text('Sent to +91 ${_phoneController.text.trim()}', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 24),
        Center(
          child: Pinput(
            length: AppConstants.otpLength,
            controller: _otpController,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyDecorationWith(
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            onCompleted: (_) => _confirmOtp(),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Verify & continue', isLoading: isLoading, onPressed: _confirmOtp),
        const SizedBox(height: 16),
        Center(
          child: _resendSecondsLeft > 0
              ? Text('Resend code in ${_resendSecondsLeft}s', style: AppTextStyles.bodySmall)
              : TextButton(onPressed: _requestOtp, child: const Text('Resend code')),
        ),
      ],
    );
  }
}
