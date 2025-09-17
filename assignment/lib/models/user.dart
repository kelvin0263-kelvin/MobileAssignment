import 'package:flutter/foundation.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? contactNo;
  final String? address;
  final String? state;
  final String? district;
  final String? gender;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.contactNo,
    this.address,
    this.state,
    this.district,
    this.gender,
  });
}
