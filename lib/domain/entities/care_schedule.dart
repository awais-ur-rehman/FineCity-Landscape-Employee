import 'package:equatable/equatable.dart';
import 'care_task.dart';

/// Care schedule domain entity.
class CareSchedule extends Equatable {
  final String id;
  final String batchId;
  final CareType careType;
  final int frequencyDays;
  final String scheduledTime;
  final List<String> assignedTo;
  final String? instructions;
  final DateTime startDate;
  final bool isActive;

  // Populated fields
  final String? batchName;

  const CareSchedule({
    required this.id,
    required this.batchId,
    required this.careType,
    required this.frequencyDays,
    required this.scheduledTime,
    this.assignedTo = const [],
    this.instructions,
    required this.startDate,
    this.isActive = true,
    this.batchName,
  });

  @override
  List<Object?> get props => [id, batchId, careType, frequencyDays, isActive];
}
