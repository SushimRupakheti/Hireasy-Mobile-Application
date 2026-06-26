import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_client.dart';
import 'package:hireasy_mobile/core/api/api_endpoints.dart';
import 'package:hireasy_mobile/features/jobs/data/datasources/job_datasource.dart';
import 'package:hireasy_mobile/features/jobs/data/job_api.dart';
import 'package:hireasy_mobile/features/jobs/data/models/job_api_model.dart';

final jobRemoteDataSourceProvider = Provider<IJobRemoteDataSource>((ref) {
  return JobRemoteDataSource(apiClient: ref.read(apiClientProvider));
});

class JobRemoteDataSource implements IJobRemoteDataSource {
  final ApiClient _apiClient;

  const JobRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<GetJobsApiResponse> getJobs() async {
    final response = await _apiClient.get(ApiEndpoints.jobs);

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
  Future<ApplyJobApiResponse> applyForJob(String jobId) async {
    final response = await _apiClient.post(ApiEndpoints.applyForJob(jobId));
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
  Future<CreateJobApiResponse> createJob(JobApiModel job) async {
    final response = await _apiClient.post(
      ApiEndpoints.jobs,
      data: job.toCreateJson(),
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
}
