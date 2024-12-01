class GPSData {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  GPSData({required this.latitude, required this.longitude, required this.timestamp});

  factory GPSData.fromJson(Map<String, dynamic> json) {
    return GPSData(
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
