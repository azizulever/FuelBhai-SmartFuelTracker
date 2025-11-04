class ServiceRecord {
  final String id;
  final DateTime serviceDate;
  final double odometerReading;
  final double totalCost;
  final String serviceType; // 'Major' or 'Minor'
  final String vehicleType;

  ServiceRecord({
    required this.id,
    required this.serviceDate,
    required this.odometerReading,
    required this.totalCost,
    required this.serviceType,
    required this.vehicleType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceDate': serviceDate.toIso8601String(),
      'odometerReading': odometerReading,
      'totalCost': totalCost,
      'serviceType': serviceType,
      'vehicleType': vehicleType,
    };
  }

  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    return ServiceRecord(
      id: json['id'] as String,
      serviceDate: DateTime.parse(json['serviceDate'] as String),
      odometerReading: (json['odometerReading'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      serviceType: json['serviceType'] as String,
      vehicleType: json['vehicleType'] as String,
    );
  }
}
