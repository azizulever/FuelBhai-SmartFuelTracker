class TripCostEntry {
  final String id;
  final double amount;
  final String description;
  final DateTime timestamp;

  TripCostEntry({
    required this.id,
    required this.amount,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TripCostEntry.fromJson(Map<String, dynamic> json) {
    return TripCostEntry(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class TripRecord {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final List<TripCostEntry> costEntries;
  final String vehicleType;
  final bool isActive;

  TripRecord({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.costEntries,
    required this.vehicleType,
    this.isActive = false,
  });

  double get totalCost {
    return costEntries.fold(0.0, (sum, entry) => sum + entry.amount);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration.inSeconds,
      'costEntries': costEntries.map((e) => e.toJson()).toList(),
      'vehicleType': vehicleType,
      'isActive': isActive,
    };
  }

  factory TripRecord.fromJson(Map<String, dynamic> json) {
    return TripRecord(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime:
          json['endTime'] != null
              ? DateTime.parse(json['endTime'] as String)
              : null,
      duration: Duration(seconds: json['duration'] as int),
      costEntries:
          (json['costEntries'] as List)
              .map((e) => TripCostEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
      vehicleType: json['vehicleType'] as String,
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}
