import 'package:dio/dio.dart';
import '../models/holiday_model.dart';

// fetches public holidays from nager.date api with memory caching
class HolidayService {
  final Dio _dio;
  final Map<String, List<Holiday>> _cache = {};

  HolidayService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://date.nager.at/api/v3',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  // fetch holidays for a given year and country (default US)
  Future<List<Holiday>> getHolidays({int? year, String countryCode = 'US'}) async {
    final targetYear = year ?? DateTime.now().year;
    final cacheKey = '${targetYear}_$countryCode';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await _dio.get('/PublicHolidays/$targetYear/$countryCode');
      if (response.statusCode == 200 && response.data is List) {
        final list = (response.data as List)
            .map((item) => Holiday.fromJson(item as Map<String, dynamic>))
            .toList();
        _cache[cacheKey] = list;
        return list;
      }
      return [];
    } catch (_) {
      // return empty on network failure
      return [];
    }
  }

  // checks if a specific date falls on a public holiday
  Future<Holiday?> checkHoliday(DateTime date, {String countryCode = 'US'}) async {
    final holidays = await getHolidays(year: date.year, countryCode: countryCode);
    try {
      return holidays.firstWhere(
        (h) =>
            h.date.year == date.year &&
            h.date.month == date.month &&
            h.date.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }
}
