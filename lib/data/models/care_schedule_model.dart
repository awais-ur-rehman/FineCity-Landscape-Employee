import '../../domain/entities/care_task.dart';
import '../../domain/entities/care_schedule.dart';

/// Care schedule data model with JSON serialization.
class CareScheduleModel extends CareSchedule {
  const CareScheduleModel({
    required super.id,
    required super.batchId,
    required super.careType,
    required super.frequencyDays,
    required super.scheduledTime,
    super.assignedTo,
    super.instructions,
    required super.startDate,
    super.isActive,
    super.batchName,
  });

  factory CareScheduleModel.fromJson(Map<String, dynamic> json) {
    // Handle populated batchId
    String batchId;
    String? batchName;
    final batchField = json['batchId'];
    if (batchField is Map<String, dynamic>) {
      batchId = batchField['_id'] as String? ?? batchField['id'] as String;
      batchName = batchField['name'] as String?;
    } else {
      batchId = batchField as String;
    }

    final assignedToRaw = json['assignedTo'] as List<dynamic>? ?? [];
    final assignedTo = assignedToRaw.map((e) {
      if (e is Map<String, dynamic>) return e['_id'] as String? ?? '';
      return e as String;
    }).toList();

    return CareScheduleModel(
      id: json['_id'] as String? ?? json['id'] as String,
      batchId: batchId,
      careType: CareType.fromString(json['careType'] as String),
      frequencyDays: json['frequencyDays'] as int,
      scheduledTime: json['scheduledTime'] as String,
      assignedTo: assignedTo,
      instructions: json['instructions'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      batchName: batchName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchId': batchId,
      'careType': careType.name,
      'frequencyDays': frequencyDays,
      'scheduledTime': scheduledTime,
      'assignedTo': assignedTo,
      'instructions': instructions,
      'startDate': startDate.toIso8601String(),
      'isActive': isActive,
    };
  }
}
