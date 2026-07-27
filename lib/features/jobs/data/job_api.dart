import 'package:hireasy_mobile/features/jobs/data/models/job_api_model.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';

class ApplyJobApiResponse {
  final bool success;
  final String message;

  const ApplyJobApiResponse({required this.success, required this.message});

  factory ApplyJobApiResponse.fromJson(Map<String, dynamic> json) {
    return ApplyJobApiResponse(
      success: json['success'] != false,
      message: json['message']?.toString() ?? 'Applied successfully',
    );
  }
}

class GetJobsApiResponse {
  final List<JobApiModel> jobs;

  const GetJobsApiResponse({required this.jobs});

  factory GetJobsApiResponse.fromJson(dynamic json) {
    dynamic jobsJson = json;

    if (json is Map) {
      jobsJson = json['jobs'] ?? json['data'];
      if (jobsJson is Map) {
        jobsJson = jobsJson['jobs'] ?? jobsJson['data'];
      }
    }

    if (jobsJson is! List) {
      throw const FormatException('The server returned an invalid jobs list.');
    }

    return GetJobsApiResponse(
      jobs: jobsJson
          .whereType<Map>()
          .map((job) => JobApiModel.fromJson(Map<String, dynamic>.from(job)))
          .toList(),
    );
  }
}

class GetAppliedJobsApiResponse {
  final List<JobApiModel> jobs;
  final Map<String, String> applicationStatuses;
  final AppliedJobsPaginationApiModel? pagination;

  const GetAppliedJobsApiResponse({
    required this.jobs,
    required this.applicationStatuses,
    this.pagination,
  });

  factory GetAppliedJobsApiResponse.fromJson(dynamic json) {
    dynamic applicationsJson = json;
    dynamic paginationJson;

    if (json is Map) {
      applicationsJson =
          json['applications'] ??
          json['appliedJobs'] ??
          json['jobs'] ??
          json['data'];
      paginationJson = json['pagination'] ?? json['meta'];
      if (applicationsJson is Map) {
        paginationJson =
            applicationsJson['pagination'] ??
            applicationsJson['meta'] ??
            paginationJson;
        applicationsJson =
            applicationsJson['applications'] ??
            applicationsJson['appliedJobs'] ??
            applicationsJson['jobs'] ??
            applicationsJson['data'];
      }
    }

    if (applicationsJson is! List) {
      throw const FormatException(
        'The server returned an invalid applications list.',
      );
    }

    final jobs = <JobApiModel>[];
    final statuses = <String, String>{};

    for (final item in applicationsJson) {
      if (item is! Map) continue;

      final map = Map<String, dynamic>.from(item);
      final nestedJob =
          map['job'] ??
          map['jobId'] ??
          map['jobDetails'] ??
          map['jobPost'] ??
          map['jobPosting'];
      final jobJson = nestedJob is Map ? nestedJob : map;
      if (jobJson is! Map) continue;

      final job = JobApiModel.fromJson(Map<String, dynamic>.from(jobJson));
      jobs.add(job);

      if (job.id == null || job.id!.isEmpty) continue;
      statuses[job.id!] = _parseApplicationStatus(
        map,
        hasNestedJob: nestedJob is Map,
      );
    }

    return GetAppliedJobsApiResponse(
      jobs: jobs,
      applicationStatuses: statuses,
      pagination: AppliedJobsPaginationApiModel.fromJson(paginationJson),
    );
  }

  static String _parseApplicationStatus(
    Map<String, dynamic> map, {
    required bool hasNestedJob,
  }) {
    final application = map['application'];
    final applicationStatus = application is Map
        ? application['status'] ??
              application['applicationStatus'] ??
              application['application_status']
        : null;
    final status =
        map['myApplicationStatus'] ??
        map['my_application_status'] ??
        map['userApplicationStatus'] ??
        map['user_application_status'] ??
        map['applicationStatus'] ??
        map['application_status'] ??
        applicationStatus ??
        _parseStatusCounts(map['applicationStatusCounts']) ??
        (hasNestedJob ? map['status'] : null);
    return _normalizeApplicationStatus(status);
  }

  static String? _parseStatusCounts(dynamic value) {
    if (value is! Map) return null;
    final entries = Map<String, dynamic>.from(value).entries.where((entry) {
      final count = entry.value is num
          ? entry.value as num
          : num.tryParse(entry.value?.toString() ?? '') ?? 0;
      return count > 0;
    }).toList();
    if (entries.length != 1) return null;
    return entries.single.key.toString();
  }

  static String _normalizeApplicationStatus(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return 'pending';
    if (normalized == 'approved') return 'accepted';
    if (normalized == 'declined') return 'rejected';
    if (const {
      'pending',
      'accepted',
      'rejected',
      'completed',
    }.contains(normalized)) {
      return normalized;
    }
    return 'pending';
  }
}

class AppliedJobsPaginationApiModel {
  final int? page;
  final int? limit;
  final int? total;
  final int? totalPages;
  final bool? hasNextPage;
  final bool? hasPreviousPage;

  const AppliedJobsPaginationApiModel({
    this.page,
    this.limit,
    this.total,
    this.totalPages,
    this.hasNextPage,
    this.hasPreviousPage,
  });

  factory AppliedJobsPaginationApiModel.fromJson(dynamic json) {
    if (json is! Map) return const AppliedJobsPaginationApiModel();
    final map = Map<String, dynamic>.from(json);
    return AppliedJobsPaginationApiModel(
      page: _parseInt(map['page'] ?? map['currentPage']),
      limit: _parseInt(map['limit'] ?? map['perPage']),
      total: _parseInt(map['total'] ?? map['totalItems'] ?? map['count']),
      totalPages: _parseInt(map['totalPages'] ?? map['pages']),
      hasNextPage: _parseBool(map['hasNextPage'] ?? map['hasNext']),
      hasPreviousPage: _parseBool(
        map['hasPreviousPage'] ?? map['hasPrevPage'] ?? map['hasPrevious'],
      ),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return null;
  }
}

class CreateJobApiResponse {
  final bool success;
  final String message;
  final JobApiModel job;

  const CreateJobApiResponse({
    required this.success,
    required this.message,
    required this.job,
  });

  factory CreateJobApiResponse.fromJson(Map<String, dynamic> json) {
    final jobJson = json['job'];
    if (jobJson is! Map<String, dynamic>) {
      throw const FormatException('The server returned an invalid job.');
    }

    return CreateJobApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? 'Job posted successfully',
      job: JobApiModel.fromJson(jobJson),
    );
  }
}

class UpdateJobApiResponse {
  final bool success;
  final String message;
  final JobApiModel job;

  const UpdateJobApiResponse({
    required this.success,
    required this.message,
    required this.job,
  });

  factory UpdateJobApiResponse.fromJson(Map<String, dynamic> json) {
    final jobJson = json['data'] ?? json['job'];
    if (jobJson is! Map) {
      throw const FormatException('The server returned an invalid job.');
    }

    return UpdateJobApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? 'Job updated successfully',
      job: JobApiModel.fromJson(Map<String, dynamic>.from(jobJson)),
    );
  }
}

class DeleteJobApiResponse {
  final bool success;
  final String message;

  const DeleteJobApiResponse({required this.success, required this.message});

  factory DeleteJobApiResponse.fromJson(Map<String, dynamic> json) {
    return DeleteJobApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? 'Job deleted successfully',
    );
  }
}

class GetJobApplicantsApiResponse {
  final List<JobApplicationEntity> applicants;

  const GetJobApplicantsApiResponse({required this.applicants});

  factory GetJobApplicantsApiResponse.fromJson(dynamic json) {
    var applicantsJson = json;

    if (json is Map) {
      final data = json['data'];
      applicantsJson = data is Map
          ? data['applicants'] ??
                data['applications'] ??
                data['appliedWorkers'] ??
                data
          : json['applicants'] ??
                json['applications'] ??
                json['appliedWorkers'] ??
                data;
      if (applicantsJson is Map) {
        applicantsJson =
            applicantsJson['applicants'] ??
            applicantsJson['applications'] ??
            applicantsJson['appliedWorkers'] ??
            applicantsJson;
      }
    }

    if (applicantsJson is Map) {
      return GetJobApplicantsApiResponse(
        applicants: _parseGroupedApplicants(applicantsJson),
      );
    }

    if (applicantsJson is! List) {
      throw const FormatException(
        'The server returned an invalid applicants list.',
      );
    }

    return GetJobApplicantsApiResponse(
      applicants: applicantsJson
          .map(_parseApplicant)
          .where((applicant) => applicant.workerId.isNotEmpty)
          .toList(),
    );
  }

  static List<JobApplicationEntity> _parseGroupedApplicants(Map value) {
    final applicants = <JobApplicationEntity>[];
    for (final entry in value.entries) {
      final status = entry.key.toString().toLowerCase();
      final group = entry.value;
      if (group is! List) continue;

      applicants.addAll(
        group
            .map((applicant) => _parseApplicant(applicant, status: status))
            .where((applicant) => applicant.workerId.isNotEmpty),
      );
    }
    return applicants;
  }

  static JobApplicationEntity _parseApplicant(dynamic value, {String? status}) {
    if (value is! Map) {
      return JobApplicationEntity(
        workerId: value?.toString() ?? '',
        status: status ?? 'pending',
      );
    }

    final map = Map<String, dynamic>.from(value);
    final workerValue =
        map['workerId'] ??
        map['userId'] ??
        map['worker'] ??
        map['applicant'] ??
        map['user'] ??
        map;

    return JobApplicationEntity(
      workerId: _parseNestedId(workerValue),
      status: (map['applicationStatus'] ?? map['status'] ?? status ?? 'pending')
          .toString()
          .toLowerCase(),
      workerName: _parseWorkerName(workerValue),
      workerProfileImage: _parseWorkerProfileImage(workerValue),
    );
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
        value['username'] ??
        value['email'];
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
