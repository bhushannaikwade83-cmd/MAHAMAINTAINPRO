import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../main.dart' show authRepositoryProvider;

/// M-PIN Login Screen
/// Shown when user returns to app and chooses to use M-PIN instead of OTP
class MpinLoginScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final VoidCallback onVerificationSuccess;
  final void Function(String phoneNumber) onUseOtpInstead;
  final VoidCallback onBackPress;

  const MpinLoginScreen({
    required this.phoneNumber,
    required this.onVerificationSuccess,
    required this.onUseOtpInstead,
    required this.onBackPress,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<MpinLoginScreen> createState() => _MpinLoginScreenState();
}

class _MpinLoginScreenState extends ConsumerState<MpinLoginScreen> {
  final _pinController = TextEditingController();
  bool _isVerifying = false;
  bool _isRequestingOtp = false;
  bool _obscurePin = true;
  String _enteredPin = '';

  Future<void> _verify(String pin) async {
    if (pin.length != 4 || _isVerifying) return;

    setState(() => _isVerifying = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.verifyMpin(widget.phoneNumber, pin);

      if (!mounted) return;

      if (result is AuthSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('M-PIN verified!'), backgroundColor: Colors.green),
        );
        widget.onVerificationSuccess();
      } else if (result is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
        );
        _pinController.clear();
        setState(() => _enteredPin = '');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _useOtpInstead() async {
    setState(() => _isRequestingOtp = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.sendOtp(widget.phoneNumber);

      if (!mounted) return;

      if (result is AuthSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent to ${widget.phoneNumber}'), backgroundColor: Colors.green),
        );
        widget.onUseOtpInstead(widget.phoneNumber);
      } else if (result is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending OTP: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isRequestingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBackPress,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.lock, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              const Text('Enter Your M-PIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Enter your 4-digit M-PIN to log in',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                widget.phoneNumber,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 4,
                enabled: !_isVerifying,
                onChanged: (value) {
                  _enteredPin = value;
                  if (value.length == 4) {
                    _verify(value);
                  }
                },
                decoration: InputDecoration(
                  hintText: '••••',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                    tooltip: _obscurePin ? 'Show M-PIN' : 'Hide M-PIN',
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
              ),
              if (_isVerifying)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRequestingOtp ? null : _useOtpInstead,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isRequestingOtp
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Use OTP Instead'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
