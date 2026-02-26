import '../../domain/entities/care_task.dart';

/// Care task data model with JSON serialization.
class CareTaskModel extends CareTask {
  const CareTaskModel({
    required super.id,
    required super.scheduleId,
    required super.batchId,
    required super.careType,
    required super.scheduledAt,
    required super.status,
    super.assignedTo,
    super.completedBy,
    super.completedAt,
    super.notes,
    super.batchName,
    super.plantType,
    super.zone,
    super.location,
    super.instructions,
    super.batchImageUrl,
    super.scientificName,
  });

  factory CareTaskModel.fromJson(Map<String, dynamic> json) {
    // Handle populated batchId (object) or plain string
    String batchId;
    String? batchName;
    String? plantType;
    String? zone;
    String? location;
    String? batchImageUrl;
    String? scientificName;

    final batchField = json['batchId'];
    if (batchField is Map<String, dynamic>) {
      batchId = batchField['_id'] as String? ?? batchField['id'] as String;
      batchName = batchField['name'] as String?;
      plantType = batchField['plantType'] as String?;
      zone = batchField['zone'] as String?;
      location = batchField['location'] as String?;
      batchImageUrl = batchField['imageUrl'] as String?;
      scientificName = batchField['scientificName'] as String?;
    } else {
      batchId = batchField as String;
    }

    // Handle populated scheduleId (object) or plain string
    String scheduleId;
    String? instructions;

    final scheduleField = json['scheduleId'];
    if (scheduleField is Map<String, dynamic>) {
      scheduleId =
          scheduleField['_id'] as String? ?? scheduleField['id'] as String;
      instructions = scheduleField['instructions'] as String?;
    } else {
      scheduleId = scheduleField as String;
    }

    // Handle completedBy — could be object or string
    String? completedBy;
    final completedByField = json['completedBy'];
    if (completedByField is Map<String, dynamic>) {
      completedBy = completedByField['name'] as String? ??
          completedByField['_id'] as String?;
    } else {
      completedBy = completedByField as String?;
    }

    // Handle assignedTo — list of strings or objects
    final assignedToRaw = json['assignedTo'] as List<dynamic>? ?? [];
    final assignedTo = assignedToRaw.map((e) {
      if (e is Map<String, dynamic>) return e['_id'] as String? ?? '';
      return e as String;
    }).toList();

    return CareTaskModel(
      id: json['_id'] as String? ?? json['id'] as String,
      scheduleId: scheduleId,
      batchId: batchId,
      careType: CareType.fromString(json['careType'] as String),
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      status: TaskStatus.fromString(json['status'] as String),
      assignedTo: assignedTo,
      completedBy: completedBy,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      notes: json['notes'] as String?,
      batchName: batchName,
      plantType: plantType,
      zone: zone,
      location: location,
      instructions: instructions,
      batchImageUrl: batchImageUrl,
      scientificName: scientificName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduleId': scheduleId,
      'batchId': batchId,
      'careType': careType.name,
      'scheduledAt': scheduledAt.toIso8601String(),
      'status': status.name,
      'assignedTo': assignedTo,
      'completedBy': completedBy,
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }
}
