import 'package:flutter/material.dart';

import 'app_lock.dart';
import 'pin_pad.dart';

class LockScreen extends StatefulWidget {
  final Future<void> Function() onBiometric;
  final VoidCallback onUnlocked;

  const LockScreen({
    super.key,
    required this.onBiometric,
    required this.onUnlocked,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _message = 'رمز ۴ رقمی را وارد کنید';
  bool _error = false;
  int _fails = 0;
  DateTime? _blockedUntil;

  Future<void> _onPin(String pin) async {
    final until = _blockedUntil;
    if (until != null && DateTime.now().isBefore(until)) {
      final s = until.difference(DateTime.now()).inSeconds + 1;
      setState(() {
        _error = true;
        _message = 'لطفاً $s ثانیه دیگر تلاش کنید';
      });
      return;
    }
    final ok = await AppLock.instance.verify(pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      widget.onUnlocked();
      return;
    }
    _fails++;
    if (_fails >= 5) {
      _fails = 0;
      _blockedUntil = DateTime.now().add(const Duration(seconds: 30));
      setState(() {
        _error = true;
        _message = 'تلاش‌های زیاد؛ ۳۰ ثانیه صبر کنید';
      });
    } else {
      setState(() {
        _error = true;
        _message = 'رمز اشتباه است';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 48),
                  const SizedBox(height: 8),
                  Text('کاسب‌باشی',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    _message,
                    style: TextStyle(color: _error ? Colors.red : null),
                  ),
                  const SizedBox(height: 24),
                  PinPad(
                    onCompleted: _onPin,
                    bottomLeft: AppLock.instance.biometric
                        ? IconButton(
                            icon: const Icon(Icons.fingerprint, size: 36),
                            onPressed: widget.onBiometric,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
