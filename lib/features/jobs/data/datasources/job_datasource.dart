import 'package:hireasy_mobile/features/jobs/data/job_api.dart';
import 'package:hireasy_mobile/features/jobs/data/models/job_api_model.dart';

abstract interface class IJobRemoteDataSource {
  Future<GetJobsApiResponse> getJobs();

  Future<GetJobsApiResponse> getMyJobs();

  Future<ApplyJobApiResponse> applyForJob(String jobId);

  Future<CreateJobApiResponse> createJob(JobApiModel job);
}
