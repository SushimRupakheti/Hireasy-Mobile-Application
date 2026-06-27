import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';

abstract interface class IJobRepository {
  Future<List<JobEntity>> getJobs();

  Future<List<JobEntity>> getMyJobs();

  Future<List<JobApplicationEntity>> getJobApplicants(String jobId);

  Future<String> applyForJob(String jobId);

  Future<JobEntity> createJob(JobEntity job);

  Future<JobEntity> updateJob(String jobId, JobEntity job);

  Future<String> deleteJob(String jobId);
}
