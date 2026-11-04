import 'package:flutter/material.dart';

import 'app_lock.dart';
import 'pin_pad.dart';

enum PinMode { create, verify }

class PinFlowPage extends StatefulWidget {
  final PinMode mode;
  final String title;

  const PinFlowPage({super.key, required this.mode, required this.title});

  @override
  State<PinFlowPage> createState() => _PinFlowPageState();
}

class _PinFlowPageState extends State<PinFlowPage> {
  String? _first;
  String _message = '';

  String get _prompt {
    if (widget.mode == PinMode.verify) return 'رمز فعلی را وارد کنید';
    return _first == null
        ? 'یک رمز ۴ رقمی انتخاب کنید'
        : 'رمز را دوباره وارد کنید';
  }

  Future<void> _onPin(String pin) async {
    if (widget.mode == PinMode.verify) {
      final ok = await AppLock.instance.verify(pin);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        setState(() => _message = 'رمز اشتباه است');
      }
      return;
    }

    if (_first == null) {
      setState(() {
        _first = pin;
        _message = '';
      });
      return;
    }
    if (_first == pin) {
      await AppLock.instance.setPin(pin);
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      setState(() {
        _first = null;
        _message = 'دو رمز یکسان نبود. دوباره شروع کنید';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_prompt, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_message, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),
              PinPad(onCompleted: _onPin),
            ],
          ),
        ),
      ),
    );
  }
}
