class Stamp {
  final String id;
  final String filePath;
  final String locationName;
  final DateTime dateTime;

  Stamp({
    required this.id,
    required this.filePath,
    required this.locationName,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'locationName': locationName,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory Stamp.fromJson(Map<String, dynamic> json) {
    return Stamp(
      id: json['id'],
      filePath: json['filePath'],
      locationName: json['locationName'],
      dateTime: DateTime.parse(json['dateTime']),
    );
  }
}
