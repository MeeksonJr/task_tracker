import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/holiday_model.dart';
import '../services/holiday_service.dart';

// singleton holiday service provider
final holidayServiceProvider = Provider<HolidayService>((ref) {
  return HolidayService();
});

// fetches holidays for a specific year
final holidaysForYearProvider =
    FutureProvider.family<List<Holiday>, int>((ref, year) async {
  final service = ref.watch(holidayServiceProvider);
  return service.getHolidays(year: year);
});

// checks if a specific date is a holiday
final holidayForDateProvider =
    FutureProvider.family<Holiday?, DateTime>((ref, date) async {
  final service = ref.watch(holidayServiceProvider);
  return service.checkHoliday(date);
});
