import 'package:equatable/equatable.dart';

/// User domain entity.
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final bool isActive;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, email, name, phone, role, isActive];
}
