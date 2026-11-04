import 'package:flutter/material.dart';

class AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const AmountRow(this.label, this.value,
      {super.key, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : null,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
