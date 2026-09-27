import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';
import '../main.dart' show authRepositoryProvider;

/// M-PIN Setup Screen
/// Shown after onboarding is complete
/// Vendor sets a 4-digit M-PIN for future logins
class MpinSetupScreen extends ConsumerStatefulWidget {
  final VoidCallback onMpinSet;

  const MpinSetupScreen({required this.onMpinSet, Key? key}) : super(key: key);

  @override
  ConsumerState<MpinSetupScreen> createState() => _MpinSetupScreenState();
}

class _MpinSetupScreenState extends ConsumerState<MpinSetupScreen> {
  final _createController = TextEditingController();
  final _confirmController = TextEditingController();

  String _createdPin = '';
  String _confirmedPin = '';
  bool _showConfirm = false;
  bool _submitting = false;
  bool _obscureCreate = true;
  bool _obscureConfirm = true;

  void _onCreateChanged(String pin) {
    _createdPin = pin;
    if (pin.length == 4 && !_showConfirm) {
      setState(() => _showConfirm = true);
    }
  }

  Future<void> _onConfirmChanged(String pin) async {
    _confirmedPin = pin;
    if (pin.length != 4 || _submitting) return;

    if (_confirmedPin != _createdPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PINs don't match - try again"), backgroundColor: Colors.red),
      );
      _confirmController.clear();
      _createController.clear();
      setState(() {
        _createdPin = '';
        _confirmedPin = '';
        _showConfirm = false;
      });
      return;
    }

    setState(() => _submitting = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.setMpin(_createdPin);

      if (!mounted) return;

      if (result is AuthSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('M-PIN set successfully!'), backgroundColor: Colors.green),
        );
        widget.onMpinSet();
      } else if (result is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting M-PIN: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
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
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.lock_outline, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              const Text('Create Your M-PIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                "You'll use this 4-digit PIN to log in next time instead of an OTP.",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 32),
              const Text('Create PIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              TextField(
                controller: _createController,
                obscureText: _obscureCreate,
                keyboardType: TextInputType.number,
                maxLength: 4,
                enabled: !_showConfirm,
                onChanged: _onCreateChanged,
                decoration: InputDecoration(
                  hintText: '••••',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCreate ? Icons.visibility_off : Icons.visibility),
                    tooltip: _obscureCreate ? 'Show M-PIN' : 'Hide M-PIN',
                    onPressed: () => setState(() => _obscureCreate = !_obscureCreate),
                  ),
                ),
              ),
              if (_showConfirm) ...[
                const SizedBox(height: 24),
                const Text('Confirm PIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  onChanged: _onConfirmChanged,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    hintText: '••••',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      tooltip: _obscureConfirm ? 'Show M-PIN' : 'Hide M-PIN',
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                if (_submitting)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _createController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
