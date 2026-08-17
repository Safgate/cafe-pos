import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Numeric PIN entry. Fires [onCompleted] as soon as [length] digits are in,
/// then clears itself ready for the next attempt.
class PinPad extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final String? errorText;
  final bool busy;

  const PinPad({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.errorText,
    this.busy = false,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _entered = '';

  void _press(String digit) {
    if (widget.busy || _entered.length >= widget.length) return;
    setState(() => _entered += digit);

    if (_entered.length == widget.length) {
      final pin = _entered;
      // Clear before handing off so a failed attempt leaves an empty pad.
      setState(() => _entered = '');
      widget.onCompleted(pin);
    }
  }

  void _backspace() {
    if (widget.busy || _entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (i) {
            final filled = i < _entered.length;
            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppTheme.primaryColor : Colors.transparent,
                border: Border.all(
                  color: filled ? AppTheme.primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 24,
          child: widget.busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(
                  widget.errorText ?? '',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
        ),
        const SizedBox(height: 8),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map(_digitButton).toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 84),
            _digitButton('0'),
            SizedBox(
              width: 84,
              height: 72,
              child: IconButton(
                icon: const Icon(Icons.backspace_outlined),
                color: Colors.grey[600],
                onPressed: _backspace,
                tooltip: 'Delete',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _digitButton(String digit) {
    return SizedBox(
      width: 84,
      height: 72,
      child: TextButton(
        onPressed: () => _press(digit),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
