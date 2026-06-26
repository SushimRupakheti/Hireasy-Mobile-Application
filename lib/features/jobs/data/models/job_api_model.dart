import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';

class JobApiModel {
  final String? id;
  final String? companyId;
  final String roleType;
  final int numberOfWorkers;
  final num pay;
  final String shift;
  final String location;
  final List<String> photos;
  final String description;
  final String status;
  final List<String> appliedWorkers;
  final List<JobApplicationEntity> applications;

  const JobApiModel({
    this.id,
    this.companyId,
    required this.roleType,
    required this.numberOfWorkers,
    required this.pay,
    required this.shift,
    required this.location,
    this.photos = const [],
    required this.description,
    this.status = 'pending',
    this.appliedWorkers = const [],
    this.applications = const [],
  });

  factory JobApiModel.fromJson(Map<String, dynamic> json) {
    final applications = _parseApplications(
      json['applications'] ?? json['appliedWorkers'],
    );
    return JobApiModel(
      id: json['_id']?.toString(),
      companyId: _parseCompanyId(json['companyId']),
      roleType: json['roleType']?.toString() ?? '',
      numberOfWorkers: _parseInt(json['numberOfWorkers']),
      pay: _parseNum(json['pay']),
      shift: json['shift']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      photos: _parseStringList(json['photos']),
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      appliedWorkers: applications
          .map((application) => application.workerId)
          .toList(),
      applications: applications,
    );
  }

  factory JobApiModel.fromEntity(JobEntity entity) {
    return JobApiModel(
      id: entity.id,
      companyId: entity.companyId,
      roleType: entity.roleType,
      numberOfWorkers: entity.numberOfWorkers,
      pay: entity.pay,
      shift: entity.shift,
      location: entity.location,
      photos: entity.photos,
      description: entity.description,
      status: entity.status,
      appliedWorkers: entity.appliedWorkers,
      applications: entity.applications,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'roleType': roleType,
      'numberOfWorkers': numberOfWorkers,
      'pay': pay,
      'shift': shift,
      'location': location,
      if (photos.isNotEmpty) 'photos': photos,
      'description': description,
      if (status.isNotEmpty) 'status': status,
    };
  }

  JobEntity toEntity() {
    return JobEntity(
      id: id,
      companyId: companyId,
      roleType: roleType,
      numberOfWorkers: numberOfWorkers,
      pay: pay,
      shift: shift,
      location: location,
      photos: photos,
      description: description,
      status: status,
      appliedWorkers: appliedWorkers,
      applications: applications,
    );
  }

  static String? _parseCompanyId(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value['_id']?.toString();
    }
    return value?.toString();
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static num _parseNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) {
          if (item is Map<String, dynamic>) {
            return item['_id']?.toString() ?? '';
          }
          return item.toString();
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<JobApplicationEntity> _parseApplications(dynamic value) {
    if (value is! List) return const [];

    return value
        .map((item) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final workerValue =
                map['workerId'] ??
                map['userId'] ??
                map['worker'] ??
                map['applicant'] ??
                map['_id'];
            final workerId = _parseNestedId(workerValue);
            return JobApplicationEntity(
              workerId: workerId,
              status: (map['applicationStatus'] ?? map['status'] ?? 'pending')
                  .toString()
                  .toLowerCase(),
            );
          }
          return JobApplicationEntity(workerId: item.toString());
        })
        .where((application) => application.workerId.isNotEmpty)
        .toList();
  }

  static String _parseNestedId(dynamic value) {
    if (value is Map) {
      return value['_id']?.toString() ?? value['id']?.toString() ?? '';
    }
    return value?.toString() ?? '';
  }
}
