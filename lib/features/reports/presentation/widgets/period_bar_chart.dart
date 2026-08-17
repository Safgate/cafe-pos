import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../domain/entities/report_summary.dart';

/// Revenue per day, drawn with plain widgets.
///
/// Seven or thirty-one bars does not justify a charting dependency — and the
/// fewer packages this offline app pulls in, the fewer ways its build can
/// break.
class PeriodBarChart extends StatelessWidget {
  final List<DayBucket> buckets;
  final ValueChanged<DayBucket>? onBarTap;

  const PeriodBarChart({
    super.key,
    required this.buckets,
    this.onBarTap,
  });

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) return const SizedBox.shrink();

    final maxRevenue = buckets
        .map((b) => b.revenue)
        .fold<double>(0, (max, value) => value > max ? value : max);

    // A flat zero-revenue period would otherwise divide by zero.
    final scale = maxRevenue <= 0 ? 1.0 : maxRevenue;

    // Dense months get initials only; a week has room for day names.
    final labelEvery = buckets.length > 10 ? (buckets.length / 6).ceil() : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(buckets.length, (index) {
              final bucket = buckets[index];
              final fraction = bucket.revenue / scale;
              final showLabel = index % labelEvery == 0;

              return Expanded(
                child: GestureDetector(
                  onTap: onBarTap == null ? null : () => onBarTap!(bucket),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (bucket.revenue > 0 && buckets.length <= 10)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              bucket.revenue.toStringAsFixed(0),
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey),
                            ),
                          ),
                        Container(
                          height: (110 * fraction).clamp(2.0, 110.0),
                          decoration: BoxDecoration(
                            color: bucket.revenue > 0
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 14,
                          child: showLabel
                              ? Text(
                                  _label(bucket.day, buckets.length),
                                  style: const TextStyle(
                                      fontSize: 9, color: Colors.grey),
                                  overflow: TextOverflow.clip,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (onBarTap != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Peak day ${money(maxRevenue)} · tap a bar for that day',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  static String _label(DateTime day, int bucketCount) {
    if (bucketCount <= 7) return DateFormat('E').format(day).substring(0, 1);
    return '${day.day}';
  }
}
