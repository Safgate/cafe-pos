import 'package:cafe_pos/core/utils/date_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateRange.today', () {
    test('starts at local midnight and ends at the next midnight', () {
      final range = DateRange.today(DateTime(2026, 8, 13, 14, 32));

      expect(range.from, DateTime(2026, 8, 13));
      expect(range.to, DateTime(2026, 8, 14));
    });

    test('an 11:59pm sale still belongs to that day', () {
      final range = DateRange.today(DateTime(2026, 8, 13, 9));
      final lateSale = DateTime(2026, 8, 13, 23, 59, 59);

      expect(range.contains(lateSale), isTrue);
    });

    test('a sale one minute after midnight belongs to the next day', () {
      final range = DateRange.today(DateTime(2026, 8, 13, 9));

      expect(range.contains(DateTime(2026, 8, 14, 0, 1)), isFalse);
    });

    test('the end of the range is exclusive', () {
      final range = DateRange.today(DateTime(2026, 8, 13));

      expect(range.contains(range.to), isFalse);
      expect(range.contains(range.from), isTrue);
    });
  });

  group('DateRange.thisWeek', () {
    test('starts on Monday when today is mid-week', () {
      // 13 Aug 2026 is a Thursday.
      final range = DateRange.thisWeek(DateTime(2026, 8, 13, 10));

      expect(range.from, DateTime(2026, 8, 10)); // Monday
      expect(range.to, DateTime(2026, 8, 17)); // following Monday
      expect(range.dayCount, 7);
    });

    test('a Sunday belongs to the week that started the Monday before', () {
      // 16 Aug 2026 is a Sunday.
      final range = DateRange.thisWeek(DateTime(2026, 8, 16, 23, 30));

      expect(range.from, DateTime(2026, 8, 10));
      expect(range.contains(DateTime(2026, 8, 16, 23, 30)), isTrue);
    });

    test('a Monday is the first day of its own week', () {
      final range = DateRange.thisWeek(DateTime(2026, 8, 10, 6));

      expect(range.from, DateTime(2026, 8, 10));
    });
  });

  group('DateRange.thisMonth', () {
    test('covers the whole calendar month', () {
      final range = DateRange.thisMonth(DateTime(2026, 8, 13));

      expect(range.from, DateTime(2026, 8, 1));
      expect(range.to, DateTime(2026, 9, 1));
      expect(range.dayCount, 31);
    });

    test('rolls over into the next year in December', () {
      final range = DateRange.thisMonth(DateTime(2026, 12, 20));

      expect(range.from, DateTime(2026, 12, 1));
      expect(range.to, DateTime(2027, 1, 1));
    });

    test('handles a leap February', () {
      final range = DateRange.thisMonth(DateTime(2028, 2, 10));

      expect(range.dayCount, 29);
    });
  });

  group('days', () {
    test('lists every local midnight in the range', () {
      final range = DateRange.thisWeek(DateTime(2026, 8, 13));

      expect(range.days.length, 7);
      expect(range.days.first, DateTime(2026, 8, 10));
      expect(range.days.last, DateTime(2026, 8, 16));
      expect(range.days.every((d) => d.hour == 0 && d.minute == 0), isTrue);
    });
  });

  group('DateRange.custom', () {
    test('includes the whole of the last day', () {
      final range =
          DateRange.custom(DateTime(2026, 8, 1), DateTime(2026, 8, 3));

      expect(range.from, DateTime(2026, 8, 1));
      expect(range.to, DateTime(2026, 8, 4));
      expect(range.contains(DateTime(2026, 8, 3, 23, 59)), isTrue);
    });
  });
}
