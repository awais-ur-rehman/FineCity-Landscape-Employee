import 'package:equatable/equatable.dart';

/// Plant batch domain entity.
class PlantBatch extends Equatable {
  final String id;
  final String name;
  final String plantType;
  final String? scientificName;
  final String? category;
  final int? quantity;
  final String? zone;
  final String? location;
  final String? imageUrl;
  final String? notes;
  final String status;

  const PlantBatch({
    required this.id,
    required this.name,
    required this.plantType,
    this.scientificName,
    this.category,
    this.quantity,
    this.zone,
    this.location,
    this.imageUrl,
    this.notes,
    this.status = 'active',
  });

  @override
  List<Object?> get props => [id, name, plantType, zone, location, status];
}
