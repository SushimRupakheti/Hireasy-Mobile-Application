import 'package:hireasy_mobile/features/jobs/data/models/job_api_model.dart';

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
