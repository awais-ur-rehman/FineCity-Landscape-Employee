import 'package:equatable/equatable.dart';

/// Care type enum matching backend values.
enum CareType {
  watering,
  fertilizer,
  pruning,
  repotting,
  general;

  static CareType fromString(String value) {
    return CareType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CareType.general,
    );
  }
}

/// Task status enum matching backend values.
enum TaskStatus {
  pending,
  completed,
  missed,
  skipped;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskStatus.pending,
    );
  }
}

/// Care task domain entity.
class CareTask extends Equatable {
  final String id;
  final String scheduleId;
  final String batchId;
  final CareType careType;
  final DateTime scheduledAt;
  final TaskStatus status;
  final List<String> assignedTo;
  final String? completedBy;
  final DateTime? completedAt;
  final String? notes;

  // Populated fields from backend
  final String? batchName;
  final String? plantType;
  final String? zone;
  final String? location;
  final String? instructions;
  final String? batchImageUrl;
  final String? scientificName;

  const CareTask({
    required this.id,
    required this.scheduleId,
    required this.batchId,
    required this.careType,
    required this.scheduledAt,
    required this.status,
    this.assignedTo = const [],
    this.completedBy,
    this.completedAt,
    this.notes,
    this.batchName,
    this.plantType,
    this.zone,
    this.location,
    this.instructions,
    this.batchImageUrl,
    this.scientificName,
  });

  /// Whether this task is currently due (within 2 hours of scheduled time).
  bool get isDue {
    if (status != TaskStatus.pending) return false;
    final now = DateTime.now();
    return scheduledAt.isBefore(now) ||
        scheduledAt.difference(now).inMinutes <= 30;
  }

  /// Whether this task is overdue.
  bool get isOverdue {
    if (status != TaskStatus.pending) return false;
    return scheduledAt.isBefore(DateTime.now());
  }

  @override
  List<Object?> get props => [id, status, completedAt, notes];
}
