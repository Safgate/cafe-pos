import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../domain/entities/product_variant.dart';

class _VariantRow {
  final TextEditingController label;
  final TextEditingController price;

  _VariantRow({String label = '', double? price})
      : label = TextEditingController(text: label),
        price = TextEditingController(
            text: price == null ? '' : price.toStringAsFixed(2));

  void dispose() {
    label.dispose();
    price.dispose();
  }
}

/// Repeatable "Sizes" editor for a menu item.
///
/// Leave it empty for items that have no sizes (a croissant); add rows for
/// items that do (Small / Medium / Large). The fields are `TextFormField`s so
/// they take part in the enclosing [Form]'s validation.
///
/// Read the result through a `GlobalKey<VariantEditorState>`:
/// `_sizesKey.currentState!.variants`.
class VariantEditor extends StatefulWidget {
  final List<ProductVariant> initial;

  const VariantEditor({super.key, this.initial = const []});

  @override
  VariantEditorState createState() => VariantEditorState();
}

class VariantEditorState extends State<VariantEditor> {
  late final List<_VariantRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.initial
        .map((v) => _VariantRow(label: v.label, price: v.price))
        .toList();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  /// The sizes currently entered, ignoring rows left completely blank.
  List<ProductVariant> get variants => _rows
      .where((r) => r.label.text.trim().isNotEmpty)
      .map((r) => ProductVariant(
            label: r.label.text.trim(),
            price: double.tryParse(r.price.text.trim()) ?? 0,
          ))
      .toList();

  /// Duplicate size names would make two cart lines indistinguishable on the
  /// receipt and in reports, so the caller checks for them before saving.
  String? get duplicateLabel {
    final seen = <String>{};
    for (final v in variants) {
      final key = v.label.toLowerCase();
      if (!seen.add(key)) return v.label;
    }
    return null;
  }

  void _addRow() => setState(() => _rows.add(_VariantRow()));

  void _removeRow(int index) {
    setState(() {
      _rows.removeAt(index).dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _rows[i].label,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Small'),
                    validator: (_) {
                      final label = _rows[i].label.text.trim();
                      final price = _rows[i].price.text.trim();
                      if (label.isEmpty && price.isNotEmpty) {
                        return 'Name this size';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _rows[i].price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '${currencySymbol()} ',
                    ),
                    validator: (_) {
                      final label = _rows[i].label.text.trim();
                      final price = _rows[i].price.text.trim();
                      if (label.isEmpty) return null;
                      if (price.isEmpty) return 'Price?';
                      final parsed = double.tryParse(price);
                      if (parsed == null) return 'Invalid';
                      if (parsed <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () => _removeRow(i),
                  tooltip: 'Remove size',
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add, size: 18),
            label: Text(_rows.isEmpty ? 'Add a size' : 'Add another size'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        if (_rows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'No sizes — the item sells at the price above.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
