// public holiday model from nager.date api
class Holiday {
  final DateTime date;
  final String localName;
  final String name;
  final String countryCode;
  final List<String> types;

  const Holiday({
    required this.date,
    required this.localName,
    required this.name,
    required this.countryCode,
    this.types = const [],
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      date: DateTime.parse(json['date'] as String),
      localName: json['localName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? 'US',
      types: (json['types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'localName': localName,
      'name': name,
      'countryCode': countryCode,
      'types': types,
    };
  }
}
