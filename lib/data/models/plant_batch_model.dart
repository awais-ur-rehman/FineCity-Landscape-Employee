import '../../domain/entities/plant_batch.dart';

/// Plant batch data model with JSON serialization.
class PlantBatchModel extends PlantBatch {
  const PlantBatchModel({
    required super.id,
    required super.name,
    required super.plantType,
    super.scientificName,
    super.category,
    super.quantity,
    super.zone,
    super.location,
    super.imageUrl,
    super.notes,
    super.status,
  });

  factory PlantBatchModel.fromJson(Map<String, dynamic> json) {
    return PlantBatchModel(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      plantType: json['plantType'] as String,
      scientificName: json['scientificName'] as String?,
      category: json['category'] as String?,
      quantity: json['quantity'] as int?,
      zone: json['zone'] as String?,
      location: json['location'] as String?,
      imageUrl: json['imageUrl'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plantType': plantType,
      'scientificName': scientificName,
      'category': category,
      'quantity': quantity,
      'zone': zone,
      'location': location,
      'imageUrl': imageUrl,
      'notes': notes,
      'status': status,
    };
  }
}
