import 'package:flutter/foundation.dart';

enum JobStatus {
  pending,
  accepted,
  inProgress,
  onHold,
  completed,
  declined,
}

class Job {
  final String id;
  final String jobName;
  final String description;
  final JobStatus status;
  final DateTime createdAt;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? estimatedDuration; // in minutes
  final int? actualDuration;    // in minutes
  final String? assignedMechanicId;
  final String? priority; // e.g. low, medium, high, urgent
  final Customer customer;
  final Vehicle? vehicle;
  final List<String> requestedServices;
  final List<AssignedPart> assignedParts;
  final List<JobNote> notes;
  final DateTime? deadline;
  final String? digitalSignature;
  final List<JobTask> tasks;
  final List<JobTimerEvent> timers;

  Job({
    required this.id,
    required this.jobName,
    required this.description,
    required this.status,
    required this.createdAt,
    this.startTime,
    this.endTime,
    this.estimatedDuration,
    this.actualDuration,
    this.assignedMechanicId,
    this.priority,
    required this.customer,
    this.vehicle,
    required this.requestedServices,
    required this.assignedParts,
    required this.notes,
    this.deadline,
    this.digitalSignature,
    this.tasks = const <JobTask>[],
    this.timers = const <JobTimerEvent>[],
  });
//with this method can do == final job2 = job1.copyWith(status: JobStatus.inProgress); do not need retype everthing
  Job copyWith({
    String? id,
    String? jobName,
    String? description,
    JobStatus? status,
    DateTime? createdAt,
    Customer? customer,
    Vehicle? vehicle,
    List<String>? requestedServices,
    List<AssignedPart>? assignedParts,
    List<JobNote>? notes,
    DateTime? deadline,
    String? digitalSignature,
    List<JobTask>? tasks,
    List<JobTimerEvent>? timers,
  }) {
    return Job(
      id: id ?? this.id,
      jobName: jobName ?? this.jobName,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      customer: customer ?? this.customer,
      vehicle: vehicle ?? this.vehicle,
      requestedServices: requestedServices ?? this.requestedServices,
      assignedParts: assignedParts ?? this.assignedParts,
      notes: notes ?? this.notes,
      deadline: deadline ?? this.deadline,
      digitalSignature: digitalSignature ?? this.digitalSignature,
      tasks: tasks ?? this.tasks,
      timers: timers ?? this.timers,
    );
  }

}

class Customer {
  final String name;
  final String contactNo;
  final String address;

  Customer({
    required this.name,
    required this.contactNo,
    required this.address,
  });
}

class Vehicle {
  final String id;
  final String? brand;
  final String? model;
  final int? year;
  final String? plateNo;

  Vehicle({
    required this.id,
    this.brand,
    this.model,
    this.year,
    this.plateNo,
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
  final String? imagePath; // legacy, keep for compatibility
  final List<NoteFile> files;

  JobNote({
    required this.id,
    required this.content,
    required this.createdAt,
    this.imagePath,
    this.files = const <NoteFile>[],
  });
}

class NoteFile {
  final String id;
  final String noteId;
  final String fileType; // photo | audio | document
  final String filePath; // storage path or public url
  final DateTime? uploadedAt;

  NoteFile({
    required this.id,
    required this.noteId,
    required this.fileType,
    required this.filePath,
    this.uploadedAt,
  });
}

enum JobTaskStatus { pending, inProgress, completed, skipped }

class JobTask {
  final String id;
  final String description;
  final JobTaskStatus status;
  final String? assignedMechanicId;
  final String? tutorialUrl;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? procedureId;
  final String? procedureStepId;
  final int? stepNumber;

  JobTask({
    required this.id,
    required this.description,
    required this.status,
    this.assignedMechanicId,
    this.tutorialUrl,
    this.startTime,
    this.endTime,
    this.procedureId,
    this.procedureStepId,
    this.stepNumber,
  });

  JobTask copyWith({
    String? id,
    String? description,
    JobTaskStatus? status,
    String? assignedMechanicId,
    String? tutorialUrl,
    DateTime? startTime,
    DateTime? endTime,
    String? procedureId,
    String? procedureStepId,
    int? stepNumber,
  }) {
    return JobTask(
      id: id ?? this.id,
      description: description ?? this.description,
      status: status ?? this.status,
      assignedMechanicId: assignedMechanicId ?? this.assignedMechanicId,
      tutorialUrl: tutorialUrl ?? this.tutorialUrl,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      procedureId: procedureId ?? this.procedureId,
      procedureStepId: procedureStepId ?? this.procedureStepId,
      stepNumber: stepNumber ?? this.stepNumber,
    );
  }
}

enum JobTimerAction { start, pause, resume, stop }

class JobTimerEvent {
  final String id;
  final String jobId;
  final JobTimerAction action;
  final DateTime timestamp;
  final String? mechanicId;

  JobTimerEvent({
    required this.id,
    required this.jobId,
    required this.action,
    required this.timestamp,
    this.mechanicId,
  });
}
