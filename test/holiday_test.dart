import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/holiday_model.dart';
import 'package:task_tracker/models/task_model.dart';

void main() {
  group('Holiday Model Tests', () {
    test('Holiday parses correctly from Nager.Date API JSON', () {
      final json = {
        'date': '2026-12-25',
        'localName': 'Christmas Day',
        'name': 'Christmas Day',
        'countryCode': 'US',
        'fixed': true,
        'global': true,
        'counties': null,
        'launchYear': null,
        'types': ['Public'],
      };

      final holiday = Holiday.fromJson(json);

      expect(holiday.date.year, 2026);
      expect(holiday.date.month, 12);
      expect(holiday.date.day, 25);
      expect(holiday.name, 'Christmas Day');
      expect(holiday.countryCode, 'US');
      expect(holiday.types, contains('Public'));

      final outJson = holiday.toJson();
      expect(outJson['date'], '2026-12-25');
      expect(outJson['name'], 'Christmas Day');
    });

    test('Task correctly recognizes holiday due date', () {
      final holidayTask = Task(
        id: 't_holiday',
        title: 'Christmas Prep',
        description: 'Prepare notes',
        priority: TaskPriority.high,
        status: TaskStatus.todo,
        dueDate: DateTime(2026, 12, 25, 10, 0),
        creatorId: 'u1',
        creatorName: 'User One',
        assigneeId: 'u2',
        assigneeName: 'User Two',
        holidayName: 'Christmas Day',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final normalTask = holidayTask.copyWith(clearHolidayName: true);

      expect(holidayTask.isDueOnHoliday, isTrue);
      expect(holidayTask.holidayName, 'Christmas Day');
      expect(normalTask.isDueOnHoliday, isFalse);
      expect(normalTask.holidayName, isNull);
    });
  });
}
