import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_client.dart';
import 'package:hireasy_mobile/core/api/api_endpoints.dart';
import 'package:hireasy_mobile/features/jobs/data/datasources/job_datasource.dart';
import 'package:hireasy_mobile/features/jobs/data/job_api.dart';
import 'package:hireasy_mobile/features/jobs/data/models/job_api_model.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_photo_upload.dart';

final jobRemoteDataSourceProvider = Provider<IJobRemoteDataSource>((ref) {
  return JobRemoteDataSource(apiClient: ref.read(apiClientProvider));
});

class JobRemoteDataSource implements IJobRemoteDataSource {
  final ApiClient apiClient;

  const JobRemoteDataSource({required this.apiClient});

  @override
  Future<GetJobsApiResponse> getJobs() async {
    final response = await apiClient.get(ApiEndpoints.jobs);

    try {
      return GetJobsApiResponse.fromJson(response.data);
    } on FormatException catch (error) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: error.message,
      );
    }
  }

  @override
  Future<GetJobsApiResponse> getMyJobs() async {
    final response = await apiClient.get(ApiEndpoints.myJobs);

    try {
      return GetJobsApiResponse.fromJson(response.data);
    } on FormatException catch (error) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: error.message,
      );
    }
  }

  @override
  Future<GetAppliedJobsApiResponse> getMyApplications() async {
    final response = await apiClient.get(ApiEndpoints.myApplications);

    try {
      return GetAppliedJobsApiResponse.fromJson(response.data);
    } on FormatException catch (error) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: error.message,
      );
    }
  }

  @override
  Future<GetJobApplicantsApiResponse> getJobApplicants(String jobId) async {
    final response = await apiClient.get(ApiEndpoints.jobApplicants(jobId));

    try {
      return GetJobApplicantsApiResponse.fromJson(response.data);
    } on FormatException catch (error) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: error.message,
      );
    }
  }

  @override
  Future<ApplyJobApiResponse> applyForJob(String jobId) async {
    final response = await apiClient.post(ApiEndpoints.applyForJob(jobId));
    final responseData = response.data;

    if (responseData is! Map) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'The server returned an invalid response.',
      );
    }

    final result = ApplyJobApiResponse.fromJson(
      Map<String, dynamic>.from(responseData),
    );
    if (!result.success) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: result.message,
      );
    }

    return result;
  }

  @override
  Future<CreateJobApiResponse> createJob(
    JobApiModel job, {
    List<JobPhotoUpload> photoUploads = const [],
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.jobs,
      data: photoUploads.isEmpty
          ? job.toCreateJson()
          : _buildJobFormData(job.toCreateJson(), photoUploads),
    );

    final responseData = response.data;
    if (responseData is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'The server returned an invalid response.',
      );
    }

    final result = CreateJobApiResponse.fromJson(responseData);
    if (!result.success) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: result.message,
      );
    }

    return result;
  }

  @override
  Future<UpdateJobApiResponse> updateJob(
    String jobId,
    JobApiModel job, {
    List<JobPhotoUpload> photoUploads = const [],
  }) async {
    final data = job.toUpdateJson();
    if (data.isEmpty) {
      throw FormatException('At least one field is required.');
    }

    final response = await apiClient.patch(
      ApiEndpoints.jobById(jobId),
      data: photoUploads.isEmpty ? data : _buildJobFormData(data, photoUploads),
    );

    final responseData = response.data;
    if (responseData is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'The server returned an invalid response.',
      );
    }

    final result = UpdateJobApiResponse.fromJson(responseData);
    if (!result.success) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: result.message,
      );
    }

    return result;
  }

  @override
  Future<DeleteJobApiResponse> deleteJob(String jobId) async {
    final response = await apiClient.delete(ApiEndpoints.jobById(jobId));

    final responseData = response.data;
    if (responseData is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'The server returned an invalid response.',
      );
    }

    final result = DeleteJobApiResponse.fromJson(responseData);
    if (!result.success) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: result.message,
      );
    }

    return result;
  }

  FormData _buildJobFormData(
    Map<String, dynamic> fields,
    List<JobPhotoUpload> photoUploads,
  ) {
    final formData = FormData();

    for (final entry in fields.entries) {
      final value = entry.value;
      if (value is List) {
        for (final item in value) {
          formData.fields.add(MapEntry(entry.key, item.toString()));
        }
      } else {
        formData.fields.add(MapEntry(entry.key, value.toString()));
      }
    }

    for (final photo in photoUploads) {
      formData.files.add(
        MapEntry(
          'photos',
          MultipartFile.fromBytes(photo.bytes, filename: photo.fileName),
        ),
      );
    }

    return formData;
  }
}
