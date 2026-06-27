import 'package:hireasy_mobile/features/jobs/data/job_api.dart';
import 'package:hireasy_mobile/features/jobs/data/models/job_api_model.dart';

abstract interface class IJobRemoteDataSource {
  Future<GetJobsApiResponse> getJobs();

  Future<GetJobsApiResponse> getMyJobs();

  Future<GetJobApplicantsApiResponse> getJobApplicants(String jobId);

  Future<ApplyJobApiResponse> applyForJob(String jobId);

  Future<CreateJobApiResponse> createJob(JobApiModel job);

  Future<UpdateJobApiResponse> updateJob(String jobId, JobApiModel job);

  Future<DeleteJobApiResponse> deleteJob(String jobId);
}
