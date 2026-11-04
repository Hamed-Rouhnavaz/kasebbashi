import 'package:flutter/material.dart';

class PinPad extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final Widget? bottomLeft;

  const PinPad({super.key, required this.onCompleted, this.bottomLeft});

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  static const int _length = 4;
  String _pin = '';

  void _add(String digit) {
    if (_pin.length >= _length) return;
    setState(() => _pin += digit);
    if (_pin.length == _length) {
      final done = _pin;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        setState(() => _pin = '');
        widget.onCompleted(done);
      });
    }
  }

  void _backspace() {
    if (_pin.isEmpty || _pin.length >= _length) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Widget _key(Widget child, VoidCallback? onTap) => Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          width: 72,
          height: 72,
          child: TextButton(
            style: TextButton.styleFrom(shape: const CircleBorder()),
            onPressed: onTap,
            child: child,
          ),
        ),
      );

  Widget _digit(String d) =>
      _key(Text(d, style: const TextStyle(fontSize: 26)), () => _add(d));

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _length; i++)
                Container(
                  margin: const EdgeInsets.all(8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? primary : null,
                    border: Border.all(color: primary, width: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (final d in row) _digit(d)],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 84, height: 84, child: widget.bottomLeft),
              _digit('0'),
              _key(const Icon(Icons.backspace_outlined), _backspace),
            ],
          ),
        ],
      ),
    );
  }
}
