import 'package:uuid/uuid.dart';

enum EventType {
  dailyGathering,
  weeklyBash,
  custom
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.dailyGathering:
        return 'Daily Gathering';
      case EventType.weeklyBash:
        return 'Weekly Bash';
      case EventType.custom:
        return 'Custom Event';
    }
  }

  int get defaultPoints {
    switch (this) {
      case EventType.dailyGathering:
        return 5;
      case EventType.weeklyBash:
        return 10;
      case EventType.custom:
        return 0; // Custom points will be set during creation
    }
  }
}

class Event {
  final String id;
  final String title; // Changed from 'name' to 'title'
  final EventType type;
  final DateTime date;
  final int pointValue;
  final String? description;
  final DateTime createdAt;
  final bool isActive;

  Event({
    String? id,
    required this.title, // Changed from 'name' to 'title'
    required this.type,
    required this.date,
    required this.pointValue,
    this.description,
    DateTime? createdAt,
    this.isActive = true,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();

  factory Event.dailyGathering(DateTime date) {
    return Event(
      title: 'Daily Gathering - ${date.day}/${date.month}/${date.year}', // Changed from 'name' to 'title'
      type: EventType.dailyGathering,
      date: date,
      pointValue: EventType.dailyGathering.defaultPoints,
    );
  }

  factory Event.weeklyBash(int number, DateTime date) {
    return Event(
      title: 'Weekly Bash - $number', // Changed from 'name' to 'title'
      type: EventType.weeklyBash,
      date: date,
      pointValue: EventType.weeklyBash.defaultPoints,
    );
  }

  factory Event.custom({
    required String title, // Changed from 'name' to 'title'
    required DateTime date,
    required int pointValue,
    String? description,
  }) {
    return Event(
      title: title, // Changed from 'name' to 'title'
      type: EventType.custom,
      date: date,
      pointValue: pointValue,
      description: description,
    );
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'], // Changed from 'name' to 'title'
      type: EventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => EventType.custom,
      ),
      date: DateTime.parse(json['date']),
      pointValue: json['point_value'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title, // Changed from 'name' to 'title'
      'leading_clan':{"name": "bashers", "score": 0, "avatar": "/placeholder.svg?height=50&width=50"},
      'venue': 'Bashers Community Hall',
      'time':"9:00",
      'agenda':[],
      'type': type.toString().split('.').last,
      'date': date.toIso8601String(),
      'point_value': pointValue,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  Event copyWith({
    String? id,
    String? title, // Changed from 'name' to 'title'
    EventType? type,
    DateTime? date,
    int? pointValue,
    String? description,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title, // Changed from 'name' to 'title'
      type: type ?? this.type,
      date: date ?? this.date,
      pointValue: pointValue ?? this.pointValue,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
