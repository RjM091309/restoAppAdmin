

const String apiBaseUrl = 'http://45.32.119.62:2000';
const String analyticsBaseUrl = 'http://45.32.119.62:2100';

String get loginApiUrl => '$apiBaseUrl/api/login';

// Note: restoAdmin backend has no /api/realtime route.
// Use an existing authenticated endpoint to avoid 404 noise on web.
String get realtimeApiUrl => '$apiBaseUrl/api/dashboard-data';

String get notificationsApiUrl => '$apiBaseUrl/api/notifications';

String notificationsApiUrlWithPagination({int limit = 20, int offset = 0}) =>
    '$apiBaseUrl/api/notifications?limit=$limit&offset=$offset';

String get notificationsMarkAllReadUrl => '$apiBaseUrl/api/notifications/mark-all-read';

String notificationMarkReadUrl(int id) => '$apiBaseUrl/api/notifications/$id';

String notificationHideUrl(int id) => '$apiBaseUrl/api/notifications/$id';

String get socketUrl => apiBaseUrl;

String dailySettlementApiUrl({required String startDate, required String endDate}) =>
    '$apiBaseUrl/api/daily-settlement?start_date=$startDate&end_date=$endDate';

String monthlyAccumulatedApiUrl({required int year, required int month}) =>
    '$apiBaseUrl/api/monthly-accumulated?year=$year&month=$month';

String monthlyRollingCasinoByYearApiUrl(int year) =>
    '$apiBaseUrl/api/monthly-rolling-casino-by-year?year=$year';

String get markerApiUrl => '$apiBaseUrl/api/marker';

String rankingApiUrl({int? year, int? month, int? limit, int? offset}) {
  final now = DateTime.now();
  final y = year ?? now.year;
  final m = month ?? now.month;
  var url = '$apiBaseUrl/api/ranking?year=$y&month=$m';
  if (limit != null) url += '&limit=$limit';
  if (offset != null) url += '&offset=$offset';
  return url;
}
