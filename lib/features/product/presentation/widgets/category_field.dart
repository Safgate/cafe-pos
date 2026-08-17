import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Free-text category input with one-tap chips for categories already in use,
/// so a café doesn't end up with "Coffee", "coffee" and "Coffees".
class CategoryField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> suggestions;

  const CategoryField({
    super.key,
    required this.controller,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Coffee'),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: suggestions
                .map((c) => ActionChip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      onPressed: () => controller.text = c,
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.08),
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
