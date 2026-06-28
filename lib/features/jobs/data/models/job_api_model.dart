import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';

class JobApiModel {
  final String? id;
  final String? companyId;
  final String roleType;
  final int numberOfWorkers;
  final num pay;
  final String shift;
  final String location;
  final String jobDate;
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
    this.jobDate = '',
    this.photos = const [],
    required this.description,
    this.status = 'open',
    this.appliedWorkers = const [],
    this.applications = const [],
  });

  factory JobApiModel.fromJson(Map<String, dynamic> json) {
    final applications = _parseApplications(
      json['applications'] ?? json['appliedWorkers'],
    );
    return JobApiModel(
      id: (json['_id'] ?? json['id'])?.toString(),
      companyId: _parseCompanyId(json['companyId']),
      roleType: json['roleType']?.toString() ?? '',
      numberOfWorkers: _parseInt(json['numberOfWorkers']),
      pay: _parseNum(json['pay']),
      shift: json['shift']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      jobDate: (json['job_date'] ?? json['jobDate'])?.toString() ?? '',
      photos: _parseStringList(json['photos']),
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
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
      jobDate: entity.jobDate,
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
      if (jobDate.isNotEmpty) 'job_date': jobDate,
      if (photos.isNotEmpty) 'photos': photos,
      'description': description,
      if (status.isNotEmpty) 'status': status,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      if (roleType.trim().isNotEmpty) 'roleType': roleType.trim(),
      if (numberOfWorkers > 0) 'numberOfWorkers': numberOfWorkers,
      if (pay > 0) 'pay': pay,
      if (shift.trim().isNotEmpty) 'shift': shift.trim(),
      if (location.trim().isNotEmpty) 'location': location.trim(),
      if (jobDate.trim().isNotEmpty) 'job_date': jobDate.trim(),
      'photos': photos,
      if (description.trim().isNotEmpty) 'description': description.trim(),
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
      jobDate: jobDate,
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
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            return (map['url'] ??
                    map['path'] ??
                    map['location'] ??
                    map['secure_url'] ??
                    map['filename'] ??
                    map['fileName'] ??
                    map['key'] ??
                    map['_id'])
                ?.toString() ??
                '';
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
              workerName: _parseWorkerName(workerValue),
              workerProfileImage: _parseWorkerProfileImage(workerValue),
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

  static String? _parseWorkerName(dynamic value) {
    if (value is! Map) return null;
    final firstName = value['firstName']?.toString().trim() ?? '';
    final lastName = value['lastName']?.toString().trim() ?? '';
    final fullName = [firstName, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ')
        .trim();
    if (fullName.isNotEmpty) return fullName;

    final name =
        value['name'] ??
        value['fullName'] ??
        value['displayName'] ??
        value['username'];
    final parsedName = name?.toString().trim();
    return parsedName == null || parsedName.isEmpty ? null : parsedName;
  }

  static String? _parseWorkerProfileImage(dynamic value) {
    if (value is! Map) return null;
    final profileImage =
        value['profileImage'] ??
        value['profile_image'] ??
        value['avatar'] ??
        value['photo'];
    final parsedImage = profileImage?.toString().trim();
    return parsedImage == null || parsedImage.isEmpty ? null : parsedImage;
  }
}
