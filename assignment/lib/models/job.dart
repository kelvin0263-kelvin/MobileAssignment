import 'package:flutter/foundation.dart';

enum JobStatus {
  pending,
  accepted,
  inProgress,
  onHold,
  completed,
}

class Job {
  final String id;
  final String jobName;
  final String description;
  final JobStatus status;
  final DateTime createdAt;
  final Customer customer;
  final List<String> requestedServices;
  final List<AssignedPart> assignedParts;
  final List<JobNote> notes;

  Job({
    required this.id,
    required this.jobName,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.customer,
    required this.requestedServices,
    required this.assignedParts,
    required this.notes,
  });

  Job copyWith({
    String? id,
    String? jobName,
    String? description,
    JobStatus? status,
    DateTime? createdAt,
    Customer? customer,
    List<String>? requestedServices,
    List<AssignedPart>? assignedParts,
    List<JobNote>? notes,
  }) {
    return Job(
      id: id ?? this.id,
      jobName: jobName ?? this.jobName,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      customer: customer ?? this.customer,
      requestedServices: requestedServices ?? this.requestedServices,
      assignedParts: assignedParts ?? this.assignedParts,
      notes: notes ?? this.notes,
    );
  }

}

class Customer {
  final String name;
  final String contactNo;
  final String address;
  final String plateNo;
  final String equipment;

  Customer({
    required this.name,
    required this.contactNo,
    required this.address,
    required this.plateNo,
    required this.equipment,
  });
}

class AssignedPart {
  final String name;
  final int quantity;
  final String? notes;

  AssignedPart({
    required this.name,
    required this.quantity,
    this.notes,
  });
}

class JobNote {
  final String id;
  final String content;
  final DateTime createdAt;
  final String? imagePath;

  JobNote({
    required this.id,
    required this.content,
    required this.createdAt,
    this.imagePath,
  });
}
