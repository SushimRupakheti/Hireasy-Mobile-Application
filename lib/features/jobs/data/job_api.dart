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
